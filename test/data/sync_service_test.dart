import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyi/data/database/database.dart';
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
}
