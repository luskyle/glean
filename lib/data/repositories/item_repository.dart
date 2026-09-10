import 'package:drift/drift.dart';

import '../database/database.dart';
import '../../domain/tagging/language.dart';

/// 默认「未分类」分组名（列表排序时恒置底）。
const kUncategorizedName = '未分类';

/// 收藏域仓储（Glean 收藏助手）：收件箱 → 整理 → 素材库/分组/标签。
///
/// 数据模型：收藏条目（items）为一等公民，分类（collections）/标签
/// （item_tags）/素材（media_assets）均为其附注；无卡片/SRS 概念。
class ItemRepository {
  ItemRepository(this.db);

  final AppDatabase db;

  // ---------------------------------------------------------------------------
  // 收藏条目
  // ---------------------------------------------------------------------------

  /// 收藏库流（新在前），支持搜索/语言/状态/分组过滤。
  Stream<List<ItemRow>> watchLibrary({
    String search = '',
    String? lang,
    String? status,
    int? collectionId,
  }) {
    final q = db.select(db.items)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

    if (search.trim().isNotEmpty) {
      final like = '%${search.trim()}%';
      // 命中标签 → 条目也算搜索匹配（多对多用子查询避免行重复）
      final tagQuery = db.selectOnly(db.itemTags)
        ..addColumns([db.itemTags.itemId])
        ..where(db.itemTags.tag.like(like));
      q.where((t) =>
          t.note.like(like) |
          t.sourceTitle.like(like) |
          t.originalUrl.like(like) |
          t.id.isInQuery(tagQuery));
    }
    if (lang != null && lang.isNotEmpty) {
      q.where((t) => t.lang.equals(lang));
    }
    if (status != null && status.isNotEmpty) {
      q.where((t) => t.status.equals(status));
    }
    if (collectionId != null) {
      final memberQuery = db.selectOnly(db.itemCollections)
        ..addColumns([db.itemCollections.itemId])
        ..where(db.itemCollections.collectionId.equals(collectionId));
      q.where((t) => t.id.isInQuery(memberQuery));
    }
    return q.watch();
  }

  /// 收藏列表查询（一次性，非流）。
  Future<List<ItemRow>> items({
    String search = '',
    String? lang,
    String? status,
    int? collectionId,
    int limit = 500,
  }) async {
    final q = db.select(db.items)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);

    if (search.trim().isNotEmpty) {
      final like = '%${search.trim()}%';
      final tagQuery = db.selectOnly(db.itemTags)
        ..addColumns([db.itemTags.itemId])
        ..where(db.itemTags.tag.like(like));
      q.where((t) =>
          t.note.like(like) |
          t.sourceTitle.like(like) |
          t.originalUrl.like(like) |
          t.id.isInQuery(tagQuery));
    }
    if (lang != null && lang.isNotEmpty) {
      q.where((t) => t.lang.equals(lang));
    }
    if (status != null && status.isNotEmpty) {
      q.where((t) => t.status.equals(status));
    }
    if (collectionId != null) {
      final memberQuery = db.selectOnly(db.itemCollections)
        ..addColumns([db.itemCollections.itemId])
        ..where(db.itemCollections.collectionId.equals(collectionId));
      q.where((t) => t.id.isInQuery(memberQuery));
    }
    return q.get();
  }

  /// 收藏条目（按 id）。
  Future<ItemRow> item(int id) async {
    return (db.select(db.items)..where((t) => t.id.equals(id))).getSingle();
  }

  /// 创建收藏：
  /// - [note] 为收藏内容（主内容）
  /// - 语言未指定时按内容自动检测
  /// - 默认进入收件箱（status='inbox'，待整理）
  /// - 可选：分类（自动设为主分类）、标签、素材、出处
  Future<ItemRow> createItem({
    required String note,
    String source = 'manual',
    String? lang,
    int? mediaAssetId,
    String? originalUrl,
    String? sourceTitle,
    String? mediaPath,
    String status = 'inbox',
    List<String> tags = const [],
    int? collectionId,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final resolvedLang = lang ??
        (note.trim().isEmpty ? null : langCodeOf(detectLang(note)));

    final itemId = await db.into(db.items).insert(
          ItemsCompanion.insert(
            source: Value(source),
            note: Value(note),
            lang: Value(resolvedLang),
            status: Value(status),
            mediaAssetId: Value(mediaAssetId),
            originalUrl: Value(originalUrl),
            sourceTitle: Value(sourceTitle),
            mediaPath: Value(mediaPath),
            createdAt: ts,
          ),
        );

    await _linkTags(itemId, tags);
    if (collectionId != null) {
      await setPrimaryCollection(itemId, collectionId);
    }
    return (db.select(db.items)..where((t) => t.id.equals(itemId)))
        .getSingle();
  }

  /// 更新收藏条目字段（只写传入的字段）。
  Future<void> updateItem(
    int id, {
    String? note,
    String? lang,
    String? status,
    String? source,
    int? mediaAssetId,
    String? originalUrl,
    String? sourceTitle,
  }) async {
    await (db.update(db.items)..where((t) => t.id.equals(id))).write(
      ItemsCompanion(
        note: note == null ? const Value.absent() : Value(note),
        lang: lang == null ? const Value.absent() : Value(lang),
        status: status == null ? const Value.absent() : Value(status),
        source: source == null ? const Value.absent() : Value(source),
        mediaAssetId:
            mediaAssetId == null ? const Value.absent() : Value(mediaAssetId),
        originalUrl:
            originalUrl == null ? const Value.absent() : Value(originalUrl),
        sourceTitle:
            sourceTitle == null ? const Value.absent() : Value(sourceTitle),
      ),
    );
  }

  /// 删除条目（打墓碑防同步复活；分类/标签级联删除）。
  Future<void> deleteItem(int itemId) async {
    await recordDeletion('items', itemId);
    await (db.delete(db.items)..where((t) => t.id.equals(itemId))).go();
  }

  // ---------------------------------------------------------------------------
  // 标签（ItemTags）
  // ---------------------------------------------------------------------------

  Future<void> _linkTags(int itemId, List<String> tags) async {
    for (final tag in tags.where((t) => t.trim().isNotEmpty)) {
      await db.into(db.itemTags).insert(
            ItemTagsCompanion.insert(itemId: itemId, tag: tag.trim()),
            mode: InsertMode.insertOrIgnore,
          );
    }
  }

  /// 覆盖条目标签（整组替换）。
  Future<void> setItemTags(int itemId, List<String> tags) async {
    await (db.delete(db.itemTags)..where((t) => t.itemId.equals(itemId))).go();
    await _linkTags(itemId, tags);
  }

  /// 条目标签列表。
  Future<List<String>> tagsOfItem(int itemId) async {
    final rows =
        await (db.select(db.itemTags)..where((t) => t.itemId.equals(itemId)))
            .get();
    return rows.map((r) => r.tag).toList();
  }

  // ---------------------------------------------------------------------------
  // 分类 / 分组（Collections）
  // ---------------------------------------------------------------------------

  /// 分类列表（「未分类」恒置底，其余按 id 即创建顺序）。
  Future<List<CollectionRow>> collections() async {
    final all = await db.select(db.collections).get();
    final uncategorized =
        all.where((c) => c.name == kUncategorizedName).toList();
    final rest = all.where((c) => c.name != kUncategorizedName).toList();
    return [...rest, ...uncategorized];
  }

  Future<int> createCollection(String name, {bool isSystem = false}) {
    return db.into(db.collections).insert(
          CollectionsCompanion.insert(
            name: name,
            isSystem: Value(isSystem),
            createdAt: DateTime.now(),
          ),
        );
  }

  Future<void> updateCollection(int id, String name) =>
      (db.update(db.collections)..where((t) => t.id.equals(id)))
          .write(CollectionsCompanion(name: Value(name)));

  Future<void> deleteCollection(int id) async {
    await recordDeletion('collections', id);
    await (db.delete(db.itemCollections)
          ..where((t) => t.collectionId.equals(id)))
        .go();
    await (db.delete(db.collections)..where((t) => t.id.equals(id))).go();
  }

  /// 确保系统分类存在（工作/学习/未分类；幂等；不可删）。
  Future<void> ensureSystemCollections() => db.ensureDefaultCollections();

  /// 条目所属的分类（详情展示用）。
  Future<List<CollectionRow>> collectionsOfItem(int itemId) async {
    final rows = await (db.select(db.itemCollections).join([
      innerJoin(db.collections,
          db.collections.id.equalsExp(db.itemCollections.collectionId)),
    ])
          ..where(db.itemCollections.itemId.equals(itemId)))
        .get();
    return rows.map((r) => r.readTable(db.collections)).toList();
  }

  /// 条目的主分类 id（null = 未分类）。
  Future<int?> primaryCollectionOfItem(int itemId) async {
    final row = await (db.select(db.itemCollections)
          ..where((t) => t.itemId.equals(itemId) & t.isPrimary.equals(true)))
        .getSingleOrNull();
    return row?.collectionId;
  }

  /// 关联条目与分类（幂等）；[isPrimary] 时设为主分类。
  Future<void> linkItemToCollection(
    int itemId,
    int collectionId, {
    bool isPrimary = false,
  }) async {
    await db.into(db.itemCollections).insert(
          ItemCollectionsCompanion.insert(
            itemId: itemId,
            collectionId: collectionId,
            isPrimary: Value(isPrimary),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    if (isPrimary) {
      await _markPrimary(itemId, collectionId);
    }
  }

  /// 取消条目与分类的关联。
  Future<void> unlinkItemFromCollection(int itemId, int collectionId) async {
    await (db.delete(db.itemCollections)
          ..where((t) =>
              t.itemId.equals(itemId) & t.collectionId.equals(collectionId)))
        .go();
  }

  /// 设置主分类：清除其他主标记，[collectionId] 置为主分类。
  /// 传入 null 则仅清除主标记（条目回到未分类视图）。
  Future<void> setPrimaryCollection(int itemId, int? collectionId) async {
    await (db.update(db.itemCollections)..where((t) => t.itemId.equals(itemId)))
        .write(const ItemCollectionsCompanion(isPrimary: Value(false)));
    if (collectionId == null) return;
    await db.into(db.itemCollections).insert(
          ItemCollectionsCompanion.insert(
            itemId: itemId,
            collectionId: collectionId,
            isPrimary: const Value(false),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    await _markPrimary(itemId, collectionId);
  }

  Future<void> _markPrimary(int itemId, int collectionId) async {
    await (db.update(db.itemCollections)
          ..where((t) =>
              t.itemId.equals(itemId) & t.collectionId.equals(collectionId)))
        .write(const ItemCollectionsCompanion(isPrimary: Value(true)));
  }

  // ---------------------------------------------------------------------------
  // 同步墓碑
  // ---------------------------------------------------------------------------

  /// 记录删除墓碑（防止同步 pull 时复活）。
  Future<void> recordDeletion(String tableName, int entityId) {
    return db.into(db.syncDeletions).insert(
          SyncDeletionsCompanion.insert(
            entityTable: tableName,
            entityId: entityId,
            deletedAt: DateTime.now(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// 全部墓碑键（merge 过滤用）：`table|id` 集合。
  Future<Set<String>> deletionKeys() async {
    final rows = await db.select(db.syncDeletions).get();
    return rows.map((r) => '${r.entityTable}|${r.entityId}').toSet();
  }
}