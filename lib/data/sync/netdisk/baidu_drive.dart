import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../cloud_drive.dart';
import 'baidu_auth.dart';

/// 百度网盘适配器（C 档网盘适配器首个实现，无 WebDAV 网盘的直连方案）。
///
/// 数据放网盘「应用目录」`/apps/glean/`（百度强制命名空间）：
/// - 快照 `backup.json` 与媒体文件都在该目录下
/// - 上传走 PCS superfile2 分片（单块 ≤4MB，backup.json 通常单片）
/// - 列表/删除走 xpan file API；下载走 PCS file download（自动跟随 302）
///
/// 令牌自动刷新（过期或 errno 111 时）；HTTP 调用注入可测。
class BaiduDrive implements CloudDrive {
  BaiduDrive({
    required this.clientId,
    required this.clientSecret,
    required this.tokenStore,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String clientId;
  final String clientSecret;
  final BaiduTokenStore tokenStore;
  final http.Client _http;

  static const _blockSize = 4 * 1024 * 1024; // 百度分片上限
  static const _appRoot = '/apps/glean';
  static const _mediaDir = '/apps/glean/media';

  String? get _token => tokenStore.accessToken;

  @override
  String get name => '百度网盘';

  @override
  Future<bool> isAvailable() async {
    if (!tokenStore.hasToken) return false;
    if (tokenStore.isExpired) await _refresh();
    return tokenStore.hasToken;
  }

  Future<void> _refresh() async {
    final rt = tokenStore.refreshToken;
    if (rt == null || rt.isEmpty) return;
    try {
      final t = await BaiduAuth.refresh(
        refreshToken: rt,
        clientId: clientId,
        clientSecret: clientSecret,
        client: _http,
      );
      await tokenStore.save(t, keepRefreshToken: rt);
    } catch (_) {
      // 刷新失败：下一步调用会因无有效 token 失败，由上层提示重新授权
    }
  }

  // -------------------------------------------------------------------------
  // 快照接口（与 WebDAV 对齐）
  // -------------------------------------------------------------------------

  @override
  Future<bool> backupExists() async {
    final list = await _listDir(_appRoot);
    return list.containsKey('backup.json');
  }

  @override
  Future<void> upload(String content) async {
    await _uploadFile('$_appRoot/backup.json', utf8.encode(content));
  }

  @override
  Future<String?> download() async {
    final bytes = await _downloadFile('$_appRoot/backup.json');
    return bytes == null ? null : utf8.decode(bytes);
  }

  // -------------------------------------------------------------------------
  // 媒体接口（与 WebDAV 对齐；路径 /glean/… 映射到 /apps/glean/…）
  // -------------------------------------------------------------------------

  @override
  Future<Uint8List?> readMedia(String path) async {
    return _downloadFile(_mapPath(path));
  }

  @override
  Future<Map<String, int>> listMedia() async {
    return _listDir(_mediaDir);
  }

  @override
  Future<bool> deleteMedia(String path) async {
    final res = await _postJson(
      _xpan('filemanager', {'opera': 'delete', 'async': '0'}),
      body: {'filelist': jsonEncode([_mapPath(path)])},
    );
    final errno = _errnoOf(res);
    // 0 成功；-9 文件不存在（幂等视为成功）
    return errno != null && (errno == 0 || errno == -9);
  }

  // -------------------------------------------------------------------------
  // 内部：API 调用
  // -------------------------------------------------------------------------

  String _mapPath(String p) => p.replaceFirst('/glean/', '/apps/glean/');

  Uri _pcs(String method, [Map<String, String>? extra]) {
    return Uri.https('d.pcs.baidu.com', '/rest/2.0/pcs/$method', {
      'access_token': _token ?? '',
      ...?extra,
    });
  }

  Uri _xpan(String method, [Map<String, String>? extra]) {
    return Uri.https('pan.baidu.com', '/rest/2.0/xpan/$method', {
      'access_token': _token ?? '',
      ...?extra,
    });
  }

  int? _errnoOf(http.Response res) {
    try {
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      return (json['errno'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  bool _tokenInvalid(http.Response res) {
    if (res.statusCode == 401) return true;
    final errno = _errnoOf(res);
    return errno == 111; // access_token 已过期
  }

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String> query = const {},
    bool retried = false,
  }) async {
    final finalUri = uri.replace(
        queryParameters: {...uri.queryParameters, 'access_token': _token ?? '', ...query});
    final res = await _http.get(finalUri);
    if (_tokenInvalid(res) && !retried) {
      await _refresh();
      return _get(uri, query: query, retried: true);
    }
    return res;
  }

  Future<http.Response> _postJson(
    Uri uri, {
    Map<String, String> body = const {},
    bool retried = false,
  }) async {
    final finalUri = uri.replace(
        queryParameters: {...uri.queryParameters, 'access_token': _token ?? ''});
    final res = await _http.post(finalUri, body: body);
    if (_tokenInvalid(res) && !retried) {
      await _refresh();
      return _postJson(uri, body: body, retried: true);
    }
    return res;
  }

  /// 列出目录：{文件名: 大小}。
  Future<Map<String, int>> _listDir(String dir) async {
    final res = await _get(
      _xpan('file'),
      query: {'method': 'list', 'dir': dir, 'limit': '1000', 'order': 'name'},
    );
    if (res.statusCode != 200) return const {};
    try {
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if ((json['errno'] as num?)?.toInt() != 0) return const {};
      final list = (json['list'] as List? ?? const []);
      return {
        for (final e in list.cast<Map<String, dynamic>>())
          if (e['isdir'] != 1 && e['server_filename'] is String)
            e['server_filename'] as String: (e['size'] as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return const {};
    }
  }

  /// 确保应用目录与媒体目录存在（幂等：已存在错误忽略）。
  Future<void> _ensureDirs() async {
    for (final dir in [_appRoot, _mediaDir]) {
      await _postJson(
        _xpan('create'),
        body: {'path': dir, 'isdir': '1'},
      );
    }
  }

  /// 分片上传文件（superfile2：tmpfile 上传各分片 → create 合并）。
  Future<void> _uploadFile(String remotePath, List<int> bytes) async {
    await _ensureDirs();
    final md5s = <String>[];
    for (var offset = 0; offset < bytes.length; offset += _blockSize) {
      final end = (offset + _blockSize) > bytes.length ? bytes.length : offset + _blockSize;
      final part = bytes.sublist(offset, end);
      final res = await _http.post(
        _pcs('superfile2', {
          'method': 'upload',
          'type': 'tmpfile',
          'path': remotePath,
          'partseq': '${md5s.length}',
          'size': '${part.length}',
          'uploadsign': '0',
        }),
        body: part,
        headers: const {'Content-Type': 'application/octet-stream'},
      );
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final md5 = json['md5'];
      if (md5 == null) {
        throw StateError('百度网盘分片上传失败：${utf8.decode(res.bodyBytes)}');
      }
      md5s.add(md5 as String);
    }
    final res = await _postJson(
      _pcs('superfile2', {
        'method': 'create',
        'path': remotePath,
        'size': '${bytes.length}',
      }),
      body: {'block_list': jsonEncode(md5s)},
    );
    if (_errnoOf(res) != 0) {
      throw StateError('百度网盘上传合并失败：${utf8.decode(res.bodyBytes)}');
    }
  }

  /// 下载文件字节（PCS download 302 跟随）；不存在/失败返回 null。
  Future<Uint8List?> _downloadFile(String remotePath) async {
    final res = await _http.get(
      _pcs('file', {'method': 'download', 'path': remotePath}),
      headers: const {'User-Agent': 'Glean'},
    );
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
    return res.bodyBytes;
  }
}