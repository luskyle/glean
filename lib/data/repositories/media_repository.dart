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
///
/// 目录级管理：链接目录（带用途）→ 递归扫描入索引；可整目录取消链接。
/// 素材级管理：多选批注用途 / 取消单个素材链接。
class MediaRepository {
  MediaRepository(this.db);

  final AppDatabase db;

  // ---- 目录 ----

  /// 全部素材目录（新在前）。
  Future<List<MediaFolderRow>> folders() async {
    final q = db.select(db.mediaFolders)
      ..orderBy([(t) => drift.OrderingTerm.desc(t.linkedAt)]);
    return q.get();
  }

  /// 链接目录：登记目录（带用途）→ 递归扫描素材，幂等（按路径去重）。
  Future<List<MediaAssetRow>> linkFolder(String dirPath,
      {String? purpose}) async {
    final now = DateTime.now();
    // 目录登记（已存在则更新用途）
    final folderRow = await (db.select(db.mediaFolders)
          ..where((t) => t.path.equals(dirPath)))
        .getSingleOrNull();
    final int folderId;
    if (folderRow == null) {
      folderId = await db.into(db.mediaFolders).insert(
            MediaFoldersCompanion.insert(
              path: dirPath,
              name: p.basename(dirPath),
              purpose: drift.Value(purpose),
              linkedAt: now,
            ),
          );
    } else {
      folderId = folderRow.id;
      await (db.update(db.mediaFolders)..where((t) => t.id.equals(folderId)))
          .write(MediaFoldersCompanion(
        purpose:
            purpose == null ? const drift.Value.absent() : drift.Value(purpose),
      ));
    }

    // 扫描目录素材并入索引（挂 folderId）
    final files = await _scanMediaFiles(dirPath);
    // 收养历史孤儿：同目录下 folder_id 为空的旧行补挂到本目录
    // （早期版本曾漏写 folderId，且 unlinkFolder 残留 NULL 行）
    if (files.isNotEmpty) {
      final paths = files.map((f) => f.path).toList();
      await (db.update(db.mediaAssets)
            ..where((t) => t.folderId.isNull() & t.path.isIn(paths)))
          .write(MediaAssetsCompanion(folderId: drift.Value(folderId)));
    }
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
        folderId: drift.Value(folderId),
        createdAt: now,
      ));
    }
    if (batch.isNotEmpty) {
      await db.batch((b) => b.insertAll(db.mediaAssets, batch));
    }
    return all();
  }

  /// 取消链接目录：删除目录记录 + 该目录下全部素材索引（不删原文件）。
  Future<void> unlinkFolder(int folderId) async {
    await (db.delete(db.mediaAssets)..where((t) => t.folderId.equals(folderId)))
        .go();
    await (db.delete(db.mediaFolders)..where((t) => t.id.equals(folderId)))
        .go();
  }

  /// 更新目录用途说明。
  Future<void> updateFolderPurpose(int folderId, String? purpose) async {
    await (db.update(db.mediaFolders)..where((t) => t.id.equals(folderId)))
        .write(MediaFoldersCompanion(
      purpose:
          purpose == null ? const drift.Value.absent() : drift.Value(purpose),
    ));
  }

  /// 指定目录下的素材（新在前）。
  Future<List<MediaAssetRow>> assetsOfFolder(int folderId) async {
    final q = db.select(db.mediaAssets)
      ..where((t) => t.folderId.equals(folderId))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  // ---- 素材 ----

  /// 全部素材（新在前）。
  Future<List<MediaAssetRow>> all() async {
    final q = db.select(db.mediaAssets)
      ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]);
    return q.get();
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

  /// 批量补充素材用途说明。
  Future<void> setAssetPurpose(List<int> assetIds, String? purpose) async {
    for (final id in assetIds) {
      await (db.update(db.mediaAssets)..where((t) => t.id.equals(id))).write(
        MediaAssetsCompanion(
          purpose: purpose == null
              ? const drift.Value.absent()
              : drift.Value(purpose),
        ),
      );
    }
  }

  /// 取消链接单个素材（只删索引，不删文件）。
  Future<void> unlinkAsset(int id) async {
    await (db.delete(db.mediaAssets)..where((t) => t.id.equals(id))).go();
  }

  /// 批量取消链接素材。
  Future<void> unlinkAssets(List<int> ids) async {
    for (final id in ids) {
      await unlinkAsset(id);
    }
  }

  /// 递归扫描目录下的媒体文件（支持符号链接跟随）。
  Future<List<File>> _scanMediaFiles(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) return const [];
    final results = <File>[];
    _scanSync(dir, results, {});
    return results;
  }

  void _scanSync(Directory dir, List<File> results, Set<String> visited) {
    // 防止符号链接循环
    final real = dir.resolveSymbolicLinksSync();
    if (!visited.add(real)) return;

    List<FileSystemEntity> entries;
    try {
      entries = dir.listSync();
    } on FileSystemException {
      return; // 无权限：跳过整个子目录
    }

    for (final entry in entries) {
      try {
        if (entry is File) {
          if (_isMedia(entry.path)) results.add(entry);
        } else if (entry is Directory) {
          _scanSync(entry, results, visited);
        } else if (entry is Link) {
          // 跟随符号链接：检测目标类型
          final target = entry.resolveSymbolicLinksSync();
          final type = FileSystemEntity.typeSync(target);
          if (type == FileSystemEntityType.file && _isMedia(target)) {
            results.add(File(target));
          } else if (type == FileSystemEntityType.directory) {
            _scanSync(Directory(target), results, visited);
          }
        }
      } on FileSystemException {
        // 单个文件/链接异常（如断链、无权限），跳过继续
      }
    }
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
