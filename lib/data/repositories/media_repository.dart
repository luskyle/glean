import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:path/path.dart' as p;

import '../database/database.dart';

/// 图片扩展名（素材库扫描用）。
const kImageExts = {'.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.heic'};

/// 视频扩展名（素材库扫描用）。
const kVideoExts = {'.mp4', '.mov', '.mkv', '.webm', '.avi', '.m4v'};

/// 本地素材库仓储（记忆教练：链接不导入）：
/// 只写素材索引（路径/类型），绝不复制媒体文件；素材仅本地使用。
class MediaRepository {
  MediaRepository(this.db);

  final AppDatabase db;

  /// 全部素材（新在前）。
  Future<List<MediaAssetRow>> all() async {
    final q = db.select(db.mediaAssets)
      ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  /// 生成本地文件素材索引：扫描目录（递归）下图片/视频，幂等（按路径去重）。
  Future<List<MediaAssetRow>> linkFolder(String dirPath) async {
    final files = await _scanMediaFiles(dirPath);
    final now = DateTime.now();
    final existing = await all();
    final knownPaths = existing.map((a) => a.path).toSet();

    final batch = <MediaAssetsCompanion>[];
    for (final f in files) {
      if (knownPaths.contains(f.path)) continue;
      batch.add(MediaAssetsCompanion.insert(
        source: const drift.Value('folder'),
        type: drift.Value(_typeOf(f.path)),
        path: f.path,
        name: p.basename(f.path),
        sizeBytes: drift.Value(f.lengthSync()),
        createdAt: now,
      ));
    }
    if (batch.isNotEmpty) {
      await db.batch((b) => b.insertAll(db.mediaAssets, batch));
    }
    return all();
  }

  /// 新增单个素材（文件选择器指定文件时）。
  Future<MediaAssetRow> addFile(String path) async {
    final existing = await (db.select(db.mediaAssets)
          ..where((t) => t.path.equals(path)))
        .getSingleOrNull();
    if (existing != null) return existing;

    final id = await db.into(db.mediaAssets).insert(
          MediaAssetsCompanion.insert(
            source: const drift.Value('folder'),
            type: drift.Value(_typeOf(path)),
            path: path,
            name: p.basename(path),
            sizeBytes: drift.Value(File(path).lengthSync()),
            createdAt: DateTime.now(),
          ),
        );
    return (db.select(db.mediaAssets)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  /// 删除素材索引（只删记录，不删文件——链接不导入）。
  Future<void> unlink(int id) async {
    await (db.delete(db.mediaAssets)..where((t) => t.id.equals(id))).go();
  }

  /// 递归扫描目录下的媒体文件。
  Future<List<File>> _scanMediaFiles(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return const [];
    final results = <File>[];
    await for (final entry in dir.list(recursive: true, followLinks: false)) {
      if (entry is File && _isMedia(entry.path)) {
        results.add(entry);
      }
    }
    return results;
  }

  bool _isMedia(String path) {
    final ext = p.extension(path).toLowerCase();
    return kImageExts.contains(ext) || kVideoExts.contains(ext);
  }

  static String _typeOf(String path) {
    final ext = p.extension(path).toLowerCase();
    return kVideoExts.contains(ext) ? 'video' : 'image';
  }
}
