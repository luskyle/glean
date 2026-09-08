import 'package:drift/drift.dart' as drift;
import 'package:path/path.dart' as p;

import '../database/database.dart';
import 'item_repository.dart';
import '../../domain/tagging/language.dart';

/// 记忆集数据（含条目展开视图）。
class MemorySetWithItems {
  const MemorySetWithItems({required this.set, required this.items});

  final MemorySetRow set;
  final List<ItemWithCard> items;
}

/// 记忆集仓储（记忆教练：用户自建复习集合）：
/// 记忆集 = 一组收藏条目（卡片），可整体学习/复习/回顾。
/// 从素材库拉入素材时：自动建卡（prompt=文件名，answer=素材用途/占位）。
class MemorySetRepository {
  MemorySetRepository(this.db, {required this.items});

  final AppDatabase db;
  final ItemRepository items;

  // ---- 集合 CRUD ----

  /// 全部记忆集（新在前）。
  Future<List<MemorySetRow>> all() async {
    final q = db.select(db.memorySets)
      ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  Future<int> create(String name, {String? purpose}) {
    return db.into(db.memorySets).insert(
          MemorySetsCompanion.insert(
            name: name,
            purpose: drift.Value(purpose),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> rename(int id, String name) async {
    await (db.update(db.memorySets)..where((t) => t.id.equals(id)))
        .write(MemorySetsCompanion(name: drift.Value(name)));
  }

  Future<void> setPurpose(int id, String? purpose) async {
    await (db.update(db.memorySets)..where((t) => t.id.equals(id))).write(
      MemorySetsCompanion(
        purpose:
            purpose == null ? const drift.Value.absent() : drift.Value(purpose),
      ),
    );
  }

  Future<void> delete(int id) async {
    // 条目级联；只移除集合关联，不删除收藏
    await (db.delete(db.memorySetItems)..where((t) => t.memorySetId.equals(id)))
        .go();
    await (db.delete(db.memorySets)..where((t) => t.id.equals(id))).go();
  }

  // ---- 条目 ----

  /// 集合内的收藏条目（join 卡片）。
  Future<List<ItemWithCard>> itemsOf(int setId) async {
    final q = db.select(db.items).join([
      drift.innerJoin(
          db.memorySetItems, db.memorySetItems.itemId.equalsExp(db.items.id)),
      drift.leftOuterJoin(db.cards, db.cards.id.equalsExp(db.items.cardId)),
    ])
      ..where(db.memorySetItems.memorySetId.equals(setId))
      ..orderBy([drift.OrderingTerm.desc(db.items.createdAt)]);
    final rows = await q.get();
    return rows
        .map((r) => ItemWithCard(
              item: r.readTable(db.items),
              card: r.readTableOrNull(db.cards),
            ))
        .toList();
  }

  Future<MemorySetWithItems> detail(int setId) async {
    final set = await (db.select(db.memorySets)
          ..where((t) => t.id.equals(setId)))
        .getSingle();
    return MemorySetWithItems(set: set, items: await itemsOf(setId));
  }

  /// 拉入已有收藏条目。
  Future<void> addItem(int setId, int itemId) async {
    await db.into(db.memorySetItems).insert(
          MemorySetItemsCompanion.insert(
            memorySetId: setId,
            itemId: itemId,
          ),
          mode: drift.InsertMode.insertOrIgnore,
        );
  }

  /// 批量拉入素材 → 自动成卡（prompt=文件名，answer=用途/占位）。
  /// 返回新建的 itemId 列表。
  Future<List<int>> addMediaAssets(int setId, List<MediaAssetRow> assets,
      {DateTime? now}) async {
    final result = <int>[];
    for (final a in assets) {
      final prompt = p.basenameWithoutExtension(a.path);
      final answer = (a.purpose?.isNotEmpty ?? false)
          ? a.purpose!
          : (a.type == 'video' ? '视频素材（点击播放回顾）' : '图片素材');
      final lang = langCodeOf(detectLang(prompt));
      final itemId = await items.createManualCard(
        prompt: prompt,
        answer: '（记忆集：$prompt）\n$answer',
        kind: 'word',
        lang: lang,
        note: a.path,
        source: 'memory_set',
        mediaAssetId: a.id,
        now: now,
      );
      await addItem(setId, itemId);
      result.add(itemId);
    }
    return result;
  }

  /// 从集合移除条目（不删除收藏）。
  Future<void> removeItem(int setId, int itemId) async {
    await (db.delete(db.memorySetItems)
          ..where((t) => t.memorySetId.equals(setId) & t.itemId.equals(itemId)))
        .go();
  }
}
