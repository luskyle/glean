import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyi/data/database/database.dart';
import 'package:shiyi/data/repositories/item_repository.dart';
import 'package:shiyi/data/repositories/media_repository.dart';
import 'package:shiyi/data/repositories/memory_set_repository.dart';
import 'package:shiyi/data/repositories/review_repository.dart';

void main() {
  late AppDatabase db;
  late MemorySetRepository sets;
  late MediaRepository media;
  late ItemRepository items;
  late ReviewRepository reviews;

  setUp(() {
    db = AppDatabase.forTesting();
    items = ItemRepository(db);
    media = MediaRepository(db);
    sets = MemorySetRepository(db, items: items);
    reviews = ReviewRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('记忆集 CRUD：建集 / 改名 / 删集', () async {
    final id = await sets.create('考研真题', purpose: '英语一近十年');
    var all = await sets.all();
    expect(all, hasLength(1));
    expect(all.first.name, '考研真题');

    await sets.rename(id, '考研英语');
    expect((await sets.all()).first.name, '考研英语');

    await sets.delete(id);
    expect(await sets.all(), isEmpty);
  });

  test('拉入素材自动成卡：条目进集合，卡片进复习队列', () async {
    final dir = await Directory.systemTemp.createTemp('ms_media');
    addTearDown(() => dir.delete(recursive: true));
    final img = File('${dir.path}/vocab.png')
      ..writeAsBytesSync(List.filled(6, 1));
    final asset = await media.addFile(img.path);

    final setId = await sets.create('单词本');
    final itemIds = await sets.addMediaAssets(setId, [asset]);

    expect(itemIds, hasLength(1));
    final detail = await sets.detail(setId);
    expect(detail.items, hasLength(1));
    // 素材链接到条目
    expect(detail.items.first.item.mediaAssetId, asset.id);
    // 卡片已建（明天首复）
    expect(detail.items.first.hasCard, isTrue);

    // 把到期时间拨回过去，使其进入复习队列
    final now = DateTime(2026, 9, 1, 10);
    final future = DateTime(2026, 9, 10, 10);
    await db.update(db.cards).write(
          CardsCompanion(dueAt: drift.Value(now)),
        );

    // 记忆集过滤的到期队列应含该卡
    final due = await reviews.dueCards(memorySetId: setId, now: future);
    expect(due, hasLength(1));
    expect(due.first.item.mediaAssetId, asset.id);

    // 全局队列同样包含
    final allDue = await reviews.dueCards(now: future);
    expect(allDue.map((c) => c.card.id), contains(due.first.card.id));
  });

  test('删除记忆集不动收藏，但移出集合生效', () async {
    final dir = await Directory.systemTemp.createTemp('ms_del');
    addTearDown(() => dir.delete(recursive: true));
    final img = File('${dir.path}/a.png')..writeAsBytesSync(List.filled(4, 1));
    final asset = await media.addFile(img.path);

    final setId = await sets.create('临时集');
    final itemIds = await sets.addMediaAssets(setId, [asset]);
    final itemId = itemIds.first;

    // 移出集合
    await sets.removeItem(setId, itemId);
    expect((await sets.detail(setId)).items, isEmpty);

    // 再拉入 + 删集：收藏与卡片保留
    await sets.addMediaAssets(setId, [asset]);
    await sets.delete(setId);
    final kept = await (db.select(db.items)..where((t) => t.id.equals(itemId)))
        .getSingle();
    expect(kept.cardId, isNotNull, reason: '删集不应删除收藏');
  });
}
