import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../cloud_drive.dart';
import 'common.dart';

/// Dropbox 适配器（C 档网盘适配器；API v2）。
///
/// OAuth（token_access_type=offline 拿 refresh_token）；
/// 文件在「应用目录」/apps/glean/ 下（App folder 权限，不触碰用户其它文件）。
/// ≤150MB 走 files/upload 直传（备份与 ≤500MB 媒体一般都在内，
/// 超限时降级为 PCS 式分片——Dropbox 为 upload_session，仅在 >150MB 启用）。
class DropboxDrive implements CloudDrive {
  DropboxDrive({
    required this.clientId,
    required this.clientSecret,
    required this.tokenStore,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String clientId;
  final String clientSecret;
  final PrefsTokenStore tokenStore;
  final http.Client _http;

  static const authorizeUrl = 'https://www.dropbox.com/oauth2/authorize';
  static const tokenUrl = 'https://api.dropboxapi.com/oauth2/token';
  static const apiHost = 'https://api.dropboxapi.com';
  static const contentHost = 'https://content.dropboxapi.com';
  static const _appRoot = '/apps/glean';
  static const _mediaDir = '/apps/glean/media';
  static const _directMax = 150 * 1024 * 1024; // files/upload 上限
  static const _chunkSize = 8 * 1024 * 1024; // upload_session 分片

  String? get _token => tokenStore.accessToken;

  @override
  String get name => 'Dropbox';

  static String buildAuthorizeUrl(String clientId) {
    return '$authorizeUrl?client_id=${Uri.encodeQueryComponent(clientId)}'
        '&response_type=code&token_access_type=offline&redirect_uri=oob';
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
      final e = _json(res)?['error'] as Map<String, dynamic>?;
      return e?['.tag'] == 'expired_access_token';
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _api(
    String method,
    Map<String, dynamic> body, {
    bool retried = false,
  }) async {
    final res = await _http.post(
      Uri.parse('$apiHost/2/$method'),
      headers: {
        'Authorization': 'Bearer ${_token ?? ''}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (_tokenInvalid(res) && !retried) {
      await _refresh();
      return _api(method, body, retried: true);
    }
    return res;
  }

  Future<http.Response> _content(
    String method,
    Map<String, dynamic> arg,
    List<int>? body, {
    bool retried = false,
  }) async {
    final res = await _http.post(
      Uri.parse('$contentHost/2/$method'),
      headers: {
        'Authorization': 'Bearer ${_token ?? ''}',
        'Dropbox-API-Arg': jsonEncode(arg),
        if (body != null) 'Content-Type': 'application/octet-stream',
      },
      body: body,
    );
    if (_tokenInvalid(res) && !retried) {
      await _refresh();
      return _content(method, arg, body, retried: true);
    }
    return res;
  }

  Map<String, dynamic>? _json(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// 确保应用目录与 media 目录存在（幂等：409 conflict 视为成功）。
  Future<void> _ensureMediaDir() async {
    for (final dir in [_appRoot, _mediaDir]) {
      await _api('files/create_folder_v2', {'path': dir, 'autorename': false});
    }
  }

  Future<Map<String, int>> _listDir(String dir) async {
    final res = await _api('files/list_folder', {
      'path': dir,
      'limit': 1000,
      'recursive': false,
    });
    if (res.statusCode != 200) return const {};
    final entries = _json(res)?['entries'] as List? ?? const [];
    return {
      for (final e in entries.cast<Map<String, dynamic>>())
        if (e['.tag'] == 'file' && e['name'] is String)
          e['name'] as String: (e['size'] as num?)?.toInt() ?? 0,
    };
  }

  Future<Uint8List?> _download(String path) async {
    final res = await _content('files/download', {'path': path}, null);
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
    return res.bodyBytes;
  }

  Future<void> _upload(String path, List<int> bytes) async {
    if (bytes.length <= _directMax) {
      final res = await _content(
        'files/upload',
        {'path': path, 'mode': 'overwrite', 'autorename': false},
        bytes,
      );
      if (res.statusCode != 200) {
        throw StateError('Dropbox 上传失败：${utf8.decode(res.bodyBytes)}');
      }
      return;
    }
    // >150MB：upload_session（start → append → finish）
    final start = await _content(
      'files/upload_session/start',
      {'close': false},
      bytes.sublist(0, _chunkSize),
    );
    final sessionId = _json(start)?['session_id'] as String?;
    if (sessionId == null) {
      throw StateError('Dropbox 上传会话失败：${utf8.decode(start.bodyBytes)}');
    }
    var offset = _chunkSize;
    while (offset < bytes.length) {
      final end =
          (offset + _chunkSize) > bytes.length ? bytes.length : offset + _chunkSize;
      await _content(
        'files/upload_session/append_v2',
        {'cursor': {'session_id': sessionId, 'offset': offset}, 'close': end >= bytes.length},
        bytes.sublist(offset, end),
      );
      offset = end;
    }
    final finish = await _content(
      'files/upload_session/finish',
      {
        'cursor': {'session_id': sessionId, 'offset': bytes.length},
        'commit': {'path': path, 'mode': 'overwrite', 'autorename': false},
      },
      const [],
    );
    if (finish.statusCode != 200) {
      throw StateError('Dropbox 分片上传失败：${utf8.decode(finish.bodyBytes)}');
    }
  }

  // ---- 快照 / 媒体接口 ----

  @override
  Future<bool> backupExists() async {
    final list = await _listDir(_appRoot);
    return list.containsKey('backup.json');
  }

  @override
  Future<void> upload(String content) async {
    await _ensureMediaDir();
    await _upload('$_appRoot/backup.json', utf8.encode(content));
  }

  @override
  Future<String?> download() async {
    final bytes = await _download('$_appRoot/backup.json');
    return bytes == null ? null : utf8.decode(bytes);
  }

  @override
  Future<Uint8List?> readMedia(String path) => _download(_mapPath(path));

  @override
  Future<Map<String, int>> listMedia() => _listDir(_mediaDir);

  @override
  Future<bool> deleteMedia(String path) async {
    final res = await _api('files/delete_v2', {'path': _mapPath(path)});
    if (res.statusCode == 200) return true;
    final tag = _json(res)?['error']?['.tag'];
    return tag == 'path_lookup' || tag == 'not_found'; // 幂等
  }

  String _mapPath(String webPath) => webPath.replaceFirst('/glean/', '$_appRoot/');
}