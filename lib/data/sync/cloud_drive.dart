import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/services.dart';
import 'package:webdav_client/webdav_client.dart';

/// 云盘通道抽象（B 档：用户自有云盘，服务器 0 存储）。
///
/// 实现：
/// - [ICloudDriveAdapter]：iOS 原生 iCloud Drive 通道（MethodChannel）
/// - [WebDavAdapter]：通用 WebDAV（坚果云等，国内兜底）
/// - 测试用 [LocalDrive]（临时目录模拟）
abstract class CloudDrive {
  String get name;

  /// 通道是否可用（未登录 iCloud / 未配置 WebDAV / 平台不支持 → false）。
  Future<bool> isAvailable();

  /// 是否有备份文件。
  Future<bool> backupExists();

  /// 全量写入备份。
  Future<void> upload(String content);

  /// 读取最新备份；无备份时返回 null。
  Future<String?> download();

  /// 读取媒体文件字节（浏览器直传的 /glean/media/ 文件）；不支持返回 null。
  Future<Uint8List?> readMedia(String path);

  /// 媒体目录清单（路径 → 字节数）；不支持返回空。
  Future<Map<String, int>> listMedia();

  /// 删除媒体文件；失败返回 false。
  Future<bool> deleteMedia(String path);
}

const _icloudChannel = MethodChannel('glean/icloud');

/// iCloud Drive 适配器：Native（Swift）实现位于 ios/Runner/AppDelegate.swift。
/// 文件写入 iCloud 容器的 Documents 目录（用户配额，开发者零成本）。
class ICloudDriveAdapter implements CloudDrive {
  const ICloudDriveAdapter();

  @override
  String get name => 'iCloud';

  @override
  Future<bool> isAvailable() async {
    try {
      return await _icloudChannel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (_) {
      return false; // 非 iOS / 未开启 iCloud
    }
  }

  @override
  Future<bool> backupExists() async {
    return await _icloudChannel.invokeMethod<bool>('backupExists') ?? false;
  }

  @override
  Future<void> upload(String content) {
    return _icloudChannel.invokeMethod('upload', content);
  }

  @override
  Future<String?> download() async {
    return _icloudChannel.invokeMethod<String>('download');
  }

  // iCloud 通道仅承载 backup.json 快照；媒体文件不支持（浏览器插件走 WebDAV）。
  @override
  Future<Uint8List?> readMedia(String path) async => null;

  @override
  Future<Map<String, int>> listMedia() async => const {};

  @override
  Future<bool> deleteMedia(String path) async => false;
}

/// WebDAV 适配器（坚果云等：免费 1GB 起）。
class WebDavAdapter implements CloudDrive {
  WebDavAdapter({
    required this.baseUrl,
    required this.username,
    required this.password,
    this.remotePath = '/glean/backup.json',
  });

  final String baseUrl;
  final String username;
  final String password;
  final String remotePath;

  Client? _client;

  Future<Client?> _ensure() async {
    if (_client != null) return _client;
    try {
      final c = Client(
        uri: baseUrl,
        c: WdDio(),
        auth: BasicAuth(user: username, pwd: password),
      );
      await c.ping();
      _client = c;
      return c;
    } catch (_) {
      return null;
    }
  }

  @override
  String get name => 'WebDAV';

  @override
  Future<bool> isAvailable() async => (await _ensure()) != null;

  @override
  Future<bool> backupExists() async {
    final c = await _ensure();
    if (c == null) return false;
    try {
      await c.read(remotePath);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> upload(String content) async {
    final c = await _ensure();
    if (c == null) throw StateError('WebDAV 不可用');
    await c.write(remotePath, Uint8List.fromList(utf8.encode(content)));
  }

  @override
  Future<String?> download() async {
    final c = await _ensure();
    if (c == null) return null;
    try {
      final bytes = await c.read(remotePath);
      return utf8.decode(bytes);
    } catch (_) {
      return null;
    }
  }

  // ---- 媒体文件（浏览器直传的 /glean/media/）----

  @override
  Future<Uint8List?> readMedia(String path) async {
    final c = await _ensure();
    if (c == null) return null;
    try {
      return Uint8List.fromList(await c.read(path));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Map<String, int>> listMedia() async {
    final c = await _ensure();
    if (c == null) return const {};
    try {
      final dir = await c.readDir('/glean/media');
      return {
        for (final f in dir)
          if (f.isDir != true && f.name != null) f.name!: (f.size ?? 0),
      };
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<bool> deleteMedia(String path) async {
    final c = await _ensure();
    if (c == null) return false;
    try {
      await c.remove(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}

/// 本地目录模拟（测试 / 桌面本地演示）。
class LocalDrive implements CloudDrive {
  LocalDrive(this.directory);

  final io.Directory directory;

  @override
  String get name => '本地';

  Future<io.File> _file() async {
    await directory.create(recursive: true);
    return io.File('${directory.path}/backup.json');
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> backupExists() async => (await _file()).existsSync();

  @override
  Future<void> upload(String content) async {
    await (await _file()).writeAsString(content);
  }

  @override
  Future<String?> download() async {
    final f = await _file();
    return f.existsSync() ? f.readAsString() : null;
  }

  // ---- 本地模拟媒体目录（<dir>/media/）----

  Future<io.File> _mediaFile(String path) async {
    await directory.create(recursive: true);
    // 去掉开头的 /glean/media/ 或 / 前缀，落在 <dir>/media/ 下
    final name = path.split('/').last;
    final mediaDir = io.Directory('${directory.path}/media');
    await mediaDir.create(recursive: true);
    return io.File('${mediaDir.path}/$name');
  }

  @override
  Future<Uint8List?> readMedia(String path) async {
    final f = await _mediaFile(path);
    return f.existsSync() ? f.readAsBytes() : null;
  }

  @override
  Future<Map<String, int>> listMedia() async {
    final dir = io.Directory('${directory.path}/media');
    if (!await dir.exists()) return const {};
    final entries = await dir.list().toList();
    return {
      for (final e in entries)
        if (e is io.File) e.uri.pathSegments.last: await e.length(),
    };
  }

  @override
  Future<bool> deleteMedia(String path) async {
    final f = await _mediaFile(path);
    if (!f.existsSync()) return false;
    await f.delete();
    return true;
  }
}
