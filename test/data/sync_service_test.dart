import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyi/data/database/database.dart';
import 'package:shiyi/data/repositories/item_repository.dart';
import 'package:shiyi/data/repositories/review_repository.dart';
import 'package:shiyi/data/sync/cloud_drive.dart';
import 'package:shiyi/data/sync/sync_service.dart';
import 'package:shiyi/data/sync/sync_snapshot.dart';
import 'package:shiyi/domain/srs/sm2.dart';

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
    final cardId = await db.into(db.cards).insert(
          CardsCompanion.insert(
            kind: const drift.Value('word'),
            prompt: 'remember',
            answer: '记得',
            lang: const drift.Value('en'),
            dueAt: now,
            createdAt: now,
          ),
        );
    await db.into(db.items).insert(
          ItemsCompanion.insert(
            cardId: drift.Value(cardId),
            source: const drift.Value('manual'),
            lang: const drift.Value('en'),
            status: const drift.Value('learning'),
            createdAt: now,
          ),
        );
    final repo = ReviewRepository(db);
    await repo.reviewCard(
      cardId: cardId,
      rating: ReviewRating.remembered,
      now: now,
    );
  }

  Future<({int cards, int items, int logs, int cols})> counts() async {
    final c = (await db.select(db.cards).get()).length;
    final i = (await db.select(db.items).get()).length;
    final l = (await db.select(db.reviewLogs).get()).length;
    final co = (await db.select(db.collections).get()).length;
    return (cards: c, items: i, logs: l, cols: co);
  }

  test('本地通道：备份 → 清库 → 恢复 → 数据一致且幂等', () async {
    backupDir = await Directory.systemTemp.createTemp('sync_test');
    addTearDown(() => backupDir.delete(recursive: true));
    svc = SyncService(db: db, cloud: LocalDrive(backupDir));

    await seed();
    final before = await counts();
    expect(before.cards, greaterThan(0));

    // 备份
    expect(await svc.backup(), isNull);
    expect(await svc.cloudHasBackup(), isTrue);

    // 清空业务数据（保留系统分组种子无妨，直接全删）
    await db.delete(db.cards).go(); // 级联 review_logs
    await db.delete(db.items).go();
    final cleared = await counts();
    expect(cleared.cards, 0);

    // 恢复
    try {
      final err = await svc.restore();
      expect(err, isNull, reason: err ?? '');
    } catch (e, st) {
      fail('restore 抛异常: $e\n$st');
    }
    final after = await counts();
    expect(after.cards, before.cards);
    expect(after.items, before.items);
    expect(after.logs, before.logs);
    expect(after.cols, before.cols);

    // 幂等：再恢复一次不重复
    await svc.restore();
    final again = await counts();
    expect(again.cards, before.cards);
    expect(again.logs, before.logs);
  });

  test('快照编码/解码往返一致', () async {
    backupDir = await Directory.systemTemp.createTemp('snap_test');
    addTearDown(() => backupDir.delete(recursive: true));

    await seed();
    final snap = await SyncSnapshot.capture(db);
    final text = snap.encode();

    final decoded = SyncSnapshot.decode(text);
    expect(decoded.payload['app'], 'shiyi');
    expect(decoded.rows['review_logs'], isA<List>());
    expect((decoded.rows['cards'] as List).length, 1);
  });

  test('多端合并：两端各自新增互不丢失', () async {
    backupDir = await Directory.systemTemp.createTemp('sync_multi');
    addTearDown(() => backupDir.delete(recursive: true));
    final drive = LocalDrive(backupDir);

    // 端 A：有 1 张卡，首次同步（推送）
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
    await ItemRepository(dbB).createManualCard(
      prompt: 'あたらしい',
      answer: '新的',
      kind: 'word',
      lang: 'ja',
      now: now,
    );
    expect(await svcB.syncNow(), isNull); // 拉取(已一致)+推送 B 全量

    // 端 A：再次同步 → B 的新收藏合并进 A，A 原有数据保留
    await svcA.syncNow();
    final aCount = (await dbA.select(dbA.cards).get()).length;
    final bCount = (await dbB.select(dbB.cards).get()).length;
    expect(aCount, bCount);
    expect(aCount, greaterThanOrEqualTo(2)); // A 1 张 + B 1 张 = 2
  });
}
