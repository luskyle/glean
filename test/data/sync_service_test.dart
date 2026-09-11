import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:glean/data/database/database.dart';
import 'package:glean/data/repositories/item_repository.dart';
import 'package:glean/data/sync/cloud_drive.dart';
import 'package:glean/data/sync/sync_service.dart';
import 'package:glean/data/sync/sync_snapshot.dart';

void main() {
  late AppDatabase db;
  late Directory backupDir;
  late SyncService svc;

  setUp(() {
    db = AppDatabase.forTesting();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seed() async {
    final now = DateTime(2026, 9, 1, 10);
    await db.into(db.items).insert(
          ItemsCompanion.insert(
            source: const drift.Value('manual'),
            note: const drift.Value('remember'),
            lang: const drift.Value('en'),
            status: const drift.Value('active'),
            createdAt: now,
          ),
        );
  }

  Future<({int items, int cols})> counts() async {
    final i = (await db.select(db.items).get()).length;
    final co = (await db.select(db.collections).get()).length;
    return (items: i, cols: co);
  }

  test('本地通道：备份 → 清库 → 恢复 → 数据一致且幂等', () async {
    backupDir = await Directory.systemTemp.createTemp('sync_test');
    addTearDown(() => backupDir.delete(recursive: true));
    svc = SyncService(db: db, cloud: LocalDrive(backupDir));

    await seed();
    final before = await counts();
    expect(before.items, greaterThan(0));

    // 备份
    expect(await svc.backup(), isNull);
    expect(await svc.cloudHasBackup(), isTrue);

    // 清空业务数据（保留系统分组种子无妨，直接全删）
    await db.delete(db.items).go();
    final cleared = await counts();
    expect(cleared.items, 0);

    // 恢复
    try {
      final err = await svc.restore();
      expect(err, isNull, reason: err ?? '');
    } catch (e, st) {
      fail('restore 抛异常: $e\n$st');
    }
    final after = await counts();
    expect(after.items, before.items);
    expect(after.cols, before.cols);

    // 幂等：再恢复一次不重复
    await svc.restore();
    final again = await counts();
    expect(again.items, before.items);
  });

  test('墓碑：删除分类后云端合并不会复活', () async {
    backupDir = await Directory.systemTemp.createTemp('tombstone');
    addTearDown(() => backupDir.delete(recursive: true));
    final svc = SyncService(db: db, cloud: LocalDrive(backupDir));
    final repo = ItemRepository(db);

    // 本地新建并删除「日语」分类（删除即打墓碑）
    final japId = await repo.createCollection('日语');
    await repo.deleteCollection(japId);

    // 云端快照仍包含已删除的「日语」（旧数据），另有一个未被删除的新分类
    final snap = SyncSnapshot.decode(
      '{"app":"glean","rows":{"collections":['
      '{"id":$japId,"name":"日语","parentId":null,"ownerId":null,'
      '"isSystem":false,"createdAt":"2026-09-01T00:00:00.000Z"},'
      '{"id":9001,"name":"法语","parentId":null,"ownerId":null,'
      '"isSystem":false,"createdAt":"2026-09-01T00:00:00.000Z"}],'
      '"cards":[],"items":[],"review_logs":[],"item_collections":[],"item_tags":[]}}',
    );
    await svc.merge(db, snap);

    final deleted = await (db.select(db.collections)
          ..where((t) => t.id.equals(japId)))
        .get();
    expect(deleted, isEmpty, reason: '墓碑分类不应被合并复活');

    // 对照：无墓碑的新分类正常合并进来
    final fresh = await (db.select(db.collections)
          ..where((t) => t.id.equals(9001)))
        .get();
    expect(fresh, hasLength(1), reason: '无墓碑的数据应正常合并');
  });

  test('快照 sourceTitle：往返保留 + 旧快照（无字段）兼容', () async {
    backupDir = await Directory.systemTemp.createTemp('snap_title');
    addTearDown(() => backupDir.delete(recursive: true));
    final svc = SyncService(db: db, cloud: LocalDrive(backupDir));

    // 浏览器式条目：带 originalUrl + sourceTitle
    final now = DateTime(2026, 9, 1, 10);
    final itemId = await db.into(db.items).insert(
          ItemsCompanion.insert(
            source: const drift.Value('browser'),
            originalUrl: const drift.Value('https://example.com/article'),
            sourceTitle: const drift.Value('间隔重复指南'),
            note: const drift.Value('spaced repetition'),
            lang: const drift.Value('en'),
            status: const drift.Value('inbox'),
            createdAt: now,
          ),
        );
    await svc.backup();

    // 恢复：sourceTitle 原样回到本地
    await db.delete(db.items).go();
    expect(await svc.restore(), isNull);
    final merged = await (db.select(db.items)
          ..where((t) => t.id.equals(itemId)))
        .getSingle();
    expect(merged.originalUrl, 'https://example.com/article');
    expect(merged.sourceTitle, '间隔重复指南');

    // 旧快照（无 sourceTitle 字段）合并不报错、字段为 null；
    // 旧 items 行里的 cardId 等已删字段被忽略
    final legacy = SyncSnapshot.decode(
      '{"app":"glean","rows":{"collections":[],'
      '"cards":[],"items":[{"id":9901,"cardId":null,"source":"manual",'
      '"mediaPath":null,"originalUrl":null,"note":"旧数据","lang":"zh",'
      '"status":"learning","createdAt":1788846000000}],'
      '"review_logs":[],"item_collections":[],"item_tags":[]}}',
    );
    await svc.merge(db, legacy);
    final legacyRow = await (db.select(db.items)
          ..where((t) => t.id.equals(9901)))
        .getSingle();
    expect(legacyRow.note, '旧数据');
    expect(legacyRow.sourceTitle, isNull);
  });

  test('快照编码/解码往返一致', () async {
    backupDir = await Directory.systemTemp.createTemp('snap_test');
    addTearDown(() => backupDir.delete(recursive: true));

    await seed();
    final snap = await SyncSnapshot.capture(db);
    final text = snap.encode();

    final decoded = SyncSnapshot.decode(text);
    expect(decoded.payload['app'], 'glean');
    expect(decoded.rows['items'], isA<List>());
    expect((decoded.rows['items'] as List).length, 1);
    // Glean 无卡片/复习日志表：快照中这两段恒为空列表（兼容旧契约）
    expect(decoded.rows['cards'], isA<List>());
    expect(decoded.rows['review_logs'], isA<List>());
  });

  test('多端合并：两端各自新增互不丢失', () async {
    backupDir = await Directory.systemTemp.createTemp('sync_multi');
    addTearDown(() => backupDir.delete(recursive: true));
    final drive = LocalDrive(backupDir);

    // 端 A：有 1 条收藏，首次同步（推送）
    final dbA = db;
    final svcA = SyncService(db: dbA, cloud: drive);
    await seed();
    expect(await svcA.syncNow(), isNull); // 无远端 → 仅推送

    // 端 B：空库，同步（拉取 A 的数据 + 自己新增）
    final dbB = AppDatabase.forTesting();
    addTearDown(() => dbB.close());
    final svcB = SyncService(db: dbB, cloud: drive);
    await svcB.syncNow(); // 合并 A

    // B 新增一条收藏
    final now = DateTime(2026, 9, 2, 10);
    await ItemRepository(dbB).createItem(
      note: 'あたらしい',
      source: 'manual',
      lang: 'ja',
      now: now,
    );
    expect(await svcB.syncNow(), isNull); // 拉取(已一致)+推送 B 全量

    // 端 A：再次同步 → B 的新收藏合并进 A，A 原有数据保留
    await svcA.syncNow();
    final aCount = (await dbA.select(dbA.items).get()).length;
    final bCount = (await dbB.select(dbB.items).get()).length;
    expect(aCount, bCount);
    expect(aCount, greaterThanOrEqualTo(2)); // A 1 条 + B 1 条 = 2
  });
}