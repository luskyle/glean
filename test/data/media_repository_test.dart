import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyi/data/database/database.dart';
import 'package:shiyi/data/repositories/media_repository.dart';
import 'package:shiyi/data/sync/sync_snapshot.dart';

void main() {
  late AppDatabase db;
  late MediaRepository repo;

  setUp(() {
    db = AppDatabase.forTesting();
    repo = MediaRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('链接目录：递归扫描图片/视频，只索引不复制，幂等去重', () async {
    final dir = await Directory.systemTemp.createTemp('media_lib');
    addTearDown(() => dir.delete(recursive: true));

    // 模拟素材：图片 + 视频 + 无关文件 + 子目录内素材
    final img = File('${dir.path}/a.jpg');
    final vid = File('${dir.path}/clip.mp4');
    final txt = File('${dir.path}/note.txt');
    final sub = Directory('${dir.path}/sub')..createSync();
    final img2 = File('${sub.path}/b.png');
    await Future.wait([
      img.writeAsBytes(List.filled(10, 1)),
      vid.writeAsBytes(List.filled(20, 2)),
      txt.writeAsString('ignore'),
      img2.writeAsBytes(List.filled(30, 3)),
    ]);

    final assets = await repo.linkFolder(dir.path);
    // 3 个媒体（jpg/mp4/png），txt 被过滤
    expect(assets, hasLength(3));
    final types = assets.map((a) => a.type).toSet();
    expect(types, containsAll(['image', 'video']));
    // 断言 source/name/size 正常
    final byName = {for (final a in assets) a.name: a};
    expect(byName['a.jpg']!.type, 'image');
    expect(byName['clip.mp4']!.type, 'video');
    expect(byName['b.png']!.source, 'folder');

    // 幂等：再次链接不重复
    final again = await repo.linkFolder(dir.path);
    expect(again, hasLength(3));

    // 未复制：源文件仍在原目录（链接不导入）
    expect(img.existsSync(), isTrue);
    expect(vid.existsSync(), isTrue);
  });

  test('addFile / unlink：单个素材增删，不删除原文件', () async {
    final dir = await Directory.systemTemp.createTemp('media_single');
    addTearDown(() => dir.delete(recursive: true));
    final f = File('${dir.path}/shot.jpeg');
    await f.writeAsBytes(List.filled(5, 9));

    final asset = await repo.addFile(f.path);
    expect(asset.name, 'shot.jpeg');
    expect(asset.type, 'image');

    // 重复添加返回同一行
    final dup = await repo.addFile(f.path);
    expect(dup.id, asset.id);

    await repo.unlink(asset.id);
    final remaining = await repo.all();
    expect(remaining, isEmpty);
    // 原文件仍在
    expect(f.existsSync(), isTrue);
  });

  test('同步快照排除 mediaAssetId（素材仅本地使用）', () async {
    // 收藏条目（不建卡，仅验证快照序列化）
    final now = DateTime(2026, 9, 1, 10);
    final dir = await Directory.systemTemp.createTemp('snap_media');
    addTearDown(() => dir.delete(recursive: true));
    final f = File('${dir.path}/x.png')..writeAsBytesSync(List.filled(4, 1));
    final asset = await repo.addFile(f.path);

    await db.into(db.items).insert(
          ItemsCompanion.insert(
            source: const drift.Value('manual'),
            originalUrl: const drift.Value('https://example.com/demo'),
            lang: const drift.Value('zh'),
            status: const drift.Value('learning'),
            mediaAssetId: drift.Value(asset.id),
            createdAt: now,
          ),
        );

    final snap = await SyncSnapshot.capture(db);
    final item = (snap.rows['items'] as List).first as Map<String, dynamic>;
    expect(item['mediaAssetId'], isNull, reason: '素材字段不应进入云同步快照');
    expect(item['originalUrl'], 'https://example.com/demo');
  });
}
