import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyi/data/database/database.dart';
import 'package:shiyi/data/sync/cloud_drive.dart';
import 'package:shiyi/data/sync/sync_service.dart';

/// 活体集成测试：连接环境变量指定的 WebDAV 端点，验证
/// 「浏览器插件写入 → 拾忆同步引擎拉取合并」全链路。
/// 用法：WEBDAV_URL=http://127.0.0.1:8080 flutter test test/live_webdav_test.dart
void main() {
  final url = Platform.environment['WEBDAV_URL'] ?? '';

  test(
    'WebDAV 拉取合并：插件条目进入本地库',
    () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);

      final svc = SyncService(
        db: db,
        cloud: WebDavAdapter(
          baseUrl: url,
          username: '',
          password: '',
        ),
      );

      expect(await svc.cloudHasBackup(), isTrue, reason: '云端应有 backup.json');
      expect(await svc.syncNow(), isNull, reason: '同步应成功');

      // 插件写入的 browser 条目应已合并进本地
      final browserItems = await (db.select(db.items)
            ..where((t) => t.source.equals('browser')))
          .get();
      expect(browserItems, isNotEmpty, reason: '插件收藏应进入收件箱');
      expect(browserItems.first.lang, 'en');
      expect(browserItems.first.status, 'inbox');
      expect(browserItems.first.originalUrl, contains('example.com'));

      final cards = await (db.select(db.cards)
            ..where((t) => t.prompt.equals('spaced repetition')))
          .get();
      expect(cards, hasLength(1));
      expect(cards.first.intervalDays, 0); // 新卡未复习

      // 分类关联（工作）
      final links = await (db.select(db.itemCollections)
            ..where((t) => t.itemId.equals(browserItems.first.id)))
          .get();
      expect(links, isNotEmpty);
    },
    skip: url.isEmpty ? '未设置 WEBDAV_URL，跳过活体测试' : false,
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
