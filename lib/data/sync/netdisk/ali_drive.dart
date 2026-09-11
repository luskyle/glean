import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../cloud_drive.dart';
import 'common.dart';

/// 阿里云盘适配器（C 档网盘适配器）。
///
/// 走 Open API（openapi.alipan.com），应用需在阿里云盘开放平台申请并开通
/// 「文件」权限（scope: user:base,file:all:read,file:all:write）。
///
/// 上传为「create → getUploadUrl(part) → PUT → complete」；
/// 大小 ≤4GB 用单分片即可（备份快照与 ≤500MB 媒体都在内），实现按单分片处理。
/// 目录：根 `root` 下 backup.json；媒体在 `root`/media 子目录。
/// 注：协议按公开文档实现 + 协议单测；真机联调如遇字段差异以官方文档微调。
class AliDrive implements CloudDrive {
  AliDrive({
    required this.clientId,
    required this.clientSecret,
    required this.tokenStore,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String clientId;
  final String clientSecret;
  final PrefsTokenStore tokenStore;
  final http.Client _http;

  static const authorizeUrl = 'https://openapi.alipan.com/oauth/authorize';
  static const tokenUrl = 'https://openapi.alipan.com/oauth/token';
  static const apiBase = 'https://openapi.alipan.com/adrive/v1.0/openFile';
  static const _scope = 'user:base,file:all:read,file:all:write';
  static const _driveId = 'me'; // 自有云盘

  String? get _token => tokenStore.accessToken;

  @override
  String get name => '阿里云盘';

  static String buildAuthorizeUrl(String clientId) {
    return '$authorizeUrl?response_type=code'
        '&client_id=${Uri.encodeQueryComponent(clientId)}'
        '&redirect_uri=oob&scope=${Uri.encodeQueryComponent(_scope)}'
        '&state=glean';
  }

  Future<void> _refresh() async {
    final rt = tokenStore.refreshToken;
    if (rt == null || rt.isEmpty) return;
    try {
      final t = await exchangeNetdiskToken(
        endpoint: Uri.parse(tokenUrl),
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': rt,
          'client_id': clientId,
          'client_secret': clientSecret,
        },
        client: _http,
      );
      await tokenStore.save(t, keepRefreshToken: rt);
    } catch (_) {}
  }

  @override
  Future<bool> isAvailable() async {
    if (!tokenStore.hasToken) return false;
    if (tokenStore.isExpired) await _refresh();
    return tokenStore.hasToken;
  }

  // ---- 内部：API ----

  bool _tokenInvalid(http.Response res) {
    if (res.statusCode == 401) return true;
    try {
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final code = json['code'];
      return code == 'AccessTokenInvalid' || code == 'InvalidParameter' &&
          (json['message']?.toString().contains('token') ?? false);
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    bool retried = false,
  }) async {
    final res = await _http.post(
      Uri.parse('$apiBase/$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (_tokenInvalid(res) && !retried) {
      await _refresh();
      return _post(path, body, retried: true);
    }
    return res;
  }

  Map<String, String> _headers() => {
        'Authorization': 'Bearer ${_token ?? ''}',
        'Content-Type': 'application/json',
      };

  Map<String, dynamic>? _json(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  bool _ok(http.Response res) {
    if (res.statusCode == 200) return true;
    final code = _json(res)?['code'];
    // 目标已存在 / 不存在等业务状态按幂等处理时由调用方判断
    return code == 'AlreadyExists' || code == 'NotFound';
  }

  Future<String> _ensureMediaDir() async {
    // 已有 media 目录（内存缓存）→ 直接返回
    final prev = _mediaDirId;
    if (prev != null) return prev;
    // 尝试创建；已存在时按名称取 id
    final res = await _post('create', {
      'drive_id': _driveId,
      'parent_file_id': 'root',
      'name': 'media',
      'type': 'folder',
      'check_name_mode': 'ignore',
    });
    if (!_ok(res)) {
      final dirs = await _listDirs('root');
      if (dirs.containsKey('media')) return dirs['media']!;
    }
    _mediaDirId = _json(res)?['file_id'] as String?;
    return _mediaDirId ?? 'root';
  }

  String? _mediaDirId;

  Future<String?> _mediaDirIdOrGet() async {
    final dirs = await _listDirs('root');
    return dirs['media'];
  }

  /// 列出目录：{名字: 'file' | 'folder'}。
  Future<Map<String, String>> _listByDir(String parentFileId) async {
    final res = await _post('list', {
      'drive_id': _driveId,
      'parent_file_id': parentFileId,
      'limit': 200,
      'order_by': 'name',
    });
    if (res.statusCode != 200) return const {};
    final items = _json(res)?['items'] as List? ?? const [];
    return {
      for (final e in items.cast<Map<String, dynamic>>())
        e['name'] as String: (e['type'] == 'folder' ? 'folder' : 'file'),
    };
  }

  Future<Map<String, String>> _listDirs(String parentFileId) async {
    final res = await _post('list', {
      'drive_id': _driveId,
      'parent_file_id': parentFileId,
      'limit': 200,
    });
    if (res.statusCode != 200) return const {};
    final items = _json(res)?['items'] as List? ?? const [];
    return {
      for (final e in items.cast<Map<String, dynamic>>())
        if (e['type'] == 'folder' && e['file_id'] is String)
          e['name'] as String: e['file_id'] as String,
    };
  }

  Future<String?> _fileIdByName(String parentFileId, String name) async {
    final res = await _post('search', {
      'drive_id': _driveId,
      'query': 'parent_file_id="$parentFileId" and name="$name"',
      'limit': 1,
    });
    final items = res.statusCode == 200
        ? (_json(res)?['items'] as List? ?? const [])
        : const [];
    if (items.isEmpty) return null;
    return (items.first as Map<String, dynamic>)['file_id'] as String?;
  }

  // ---- 快照 / 媒体接口 ----

  @override
  Future<bool> backupExists() async {
    final names = await _listByDir('root');
    return names.containsKey('backup.json');
  }

  @override
  Future<void> upload(String content) async {
    await _uploadFile(
      parent: 'root',
      name: 'backup.json',
      bytes: utf8.encode(content),
    );
  }

  @override
  Future<String?> download() async {
    final fid = await _fileIdByName('root', 'backup.json');
    if (fid == null) return null;
    final bytes = await _downloadFile(fid);
    return bytes == null ? null : utf8.decode(bytes);
  }

  @override
  Future<Uint8List?> readMedia(String path) async {
    final dirId = await _mediaDirIdOrGet();
    if (dirId == null) return null;
    final fid = await _fileIdByName(dirId, path.split('/').last);
    if (fid == null) return null;
    return _downloadFile(fid);
  }

  @override
  Future<Map<String, int>> listMedia() async {
    final dirId = await _mediaDirIdOrGet();
    if (dirId == null) return const {};
    final res = await _post('list', {
      'drive_id': _driveId,
      'parent_file_id': dirId,
      'limit': 200,
    });
    if (res.statusCode != 200) return const {};
    final items = _json(res)?['items'] as List? ?? const [];
    return {
      for (final e in items.cast<Map<String, dynamic>>())
        if (e['type'] == 'file')
          e['name'] as String: (e['size'] as num?)?.toInt() ?? 0,
    };
  }

  @override
  Future<bool> deleteMedia(String path) async {
    final dirId = _mediaDirId ?? await _mediaDirIdOrGet();
    if (dirId == null) return true; // 目录不存在 → 无事可删
    final fid = await _fileIdByName(dirId, path.split('/').last);
    if (fid == null) return true; // 幂等
    final res = await _post('delete', {
      'drive_id': _driveId,
      'file_id': [fid],
    });
    final code = _json(res)?['code'];
    return res.statusCode == 200 || code == 'NotFound';
  }

  // ---- 上传 / 下载 ----

  Future<void> _uploadFile({
    required String parent,
    required String name,
    required List<int> bytes,
  }) async {
    final mediaParent = await _prepareParent(parent);
    final create = await _post('create', {
      'drive_id': _driveId,
      'parent_file_id': mediaParent,
      'name': name,
      'type': 'file',
      'check_name_mode': 'ignore',
      'part_info_list': [
        {'part_number': 1, 'part_size': bytes.length},
      ],
    });
    final createJson = _json(create);
    final fileId = createJson?['file_id'] as String?;
    final uploadId = createJson?['upload_id'] as String?;
    final partUrl =
        ((createJson?['part_info_list'] as List? ?? const [])
                .firstOrNull as Map<String, dynamic>?)?['upload_url']
            as String?;
    if (fileId == null || uploadId == null || partUrl == null) {
      throw StateError('阿里云盘创建上传失败：${utf8.decode(create.bodyBytes)}');
    }

    // PUT 分片（签名 URL，无需额外鉴权头）
    final put = await _http.put(Uri.parse(partUrl), body: bytes);
    final rawEtag = put.headers['etag'] ?? put.headers['ETag'];

    final complete = await _post('complete', {
      'drive_id': _driveId,
      'file_id': fileId,
      'upload_id': uploadId,
      'part_info_list': [
        {'part_number': 1, 'etag': rawEtag},
      ],
    });
    if (!(complete.statusCode == 200 || _json(complete)?['code'] == 'AlreadyExists')) {
      throw StateError('阿里云盘完成上传失败：${utf8.decode(complete.bodyBytes)}');
    }
  }

  Future<String> _prepareParent(String parent) async {
    if (parent == 'root') return 'root';
    return _ensureMediaDir();
  }

  Future<Uint8List?> _downloadFile(String fileId) async {
    final res = await _post(
      'getDownloadUrl',
      {'drive_id': _driveId, 'file_id': fileId},
    );
    final url = _json(res)?['url'] as String?;
    if (url == null) return null;
    final dl = await _http.get(Uri.parse(url));
    if (dl.statusCode != 200 || dl.bodyBytes.isEmpty) return null;
    return dl.bodyBytes;
  }
}