import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../cloud_drive.dart';
import 'common.dart';

/// OneDrive 适配器（C 档网盘适配器；Microsoft Graph API）。
///
/// 使用「应用专用目录」（special/approot，只申请 Files.ReadWrite.AppFolder，
/// 不需要用户全部文件权限），Glean 数据只在 OneDrive → 应用 文件夹下。
/// 小文件（≤4MB）简单 PUT（:/path:/content）；大文件走 upload session 分片。
class OneDriveDrive implements CloudDrive {
  OneDriveDrive({
    required this.clientId,
    required this.clientSecret,
    required this.tokenStore,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String clientId;
  final String clientSecret;
  final PrefsTokenStore tokenStore;
  final http.Client _http;

  static const authorizeUrl =
      'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
  static const tokenUrl =
      'https://login.microsoftonline.com/common/oauth2/v2.0/token';
  static const graphBase = 'https://graph.microsoft.com/v1.0';
  static const _scope = 'Files.ReadWrite.AppFolder offline_access User.Read';
  static const _chunkSize = 4 * 1024 * 1024;

  String? get _token => tokenStore.accessToken;

  @override
  String get name => 'OneDrive';

  static String buildAuthorizeUrl(String clientId) {
    return '$authorizeUrl?client_id=${Uri.encodeQueryComponent(clientId)}'
        '&response_type=code&redirect_uri=oob'
        '&scope=${Uri.encodeQueryComponent(_scope)}&response_mode=query';
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
          'scope': _scope,
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

  // ---- 内部：Graph 调用 ----

  /// approot 相对路径（如 media/x.jpg）→ Graph `:/…:` 路径（各段 URL 编码）。
  String _itemPath(String rel) {
    final segs =
        rel.split('/').map((s) => Uri.encodeComponent(s)).join('/');
    return '/me/drive/special/approot:/$segs:';
  }

  Map<String, String> _headers({bool json = false}) => {
        'Authorization': 'Bearer ${_token ?? ''}',
        if (json) 'Content-Type': 'application/json',
      };

  bool _tokenInvalid(http.Response res) => res.statusCode == 401;

  Future<http.Response> _request(
    Future<http.Response> Function() send, {
    bool retried = false,
  }) async {
    final res = await send();
    if (_tokenInvalid(res) && !retried) {
      await _refresh();
      return _request(send, retried: true);
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

  /// 确保 approot 下有 media 目录（幂等：已存在 409 视为成功）。
  Future<bool> _ensureMediaDir() async {
    final res = await _request(() => _http.post(
          Uri.parse('$graphBase${_itemPath('media')}/children'),
          headers: _headers(json: true),
          body: jsonEncode({
            'name': 'media',
            'folder': <String, dynamic>{},
            '@microsoft.graph.conflictBehavior': 'fail',
          }),
        ));
    return res.statusCode == 201 || res.statusCode == 409;
  }

  Future<Map<String, int>> _listDir(String relDir) async {
    final res = await _request(() => _http.get(
          Uri.parse('$graphBase${_itemPath(relDir)}/children'),
          headers: _headers(),
        ));
    if (res.statusCode != 200) return const {};
    final items = _json(res)?['value'] as List? ?? const [];
    return {
      for (final e in items.cast<Map<String, dynamic>>())
        if (e['file'] != null && e['name'] is String)
          e['name'] as String: (e['size'] as num?)?.toInt() ?? 0,
    };
  }

  Future<Uint8List?> _download(String relPath) async {
    final res = await _request(() => _http.get(
          Uri.parse('$graphBase${_itemPath(relPath)}/content'),
          headers: _headers(),
        ));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
    return res.bodyBytes;
  }

  Future<void> _upload(String relPath, List<int> bytes) async {
    if (bytes.length <= _chunkSize) {
      final res = await _request(() => _http.put(
            Uri.parse('$graphBase${_itemPath(relPath)}/content'),
            headers: _headers(),
            body: bytes,
          ));
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw StateError('OneDrive 上传失败：${utf8.decode(res.bodyBytes)}');
      }
    } else {
      await _uploadSession(relPath, bytes);
    }
  }

  Future<void> _uploadSession(String relPath, List<int> bytes) async {
    final create = await _request(() => _http.post(
          Uri.parse('$graphBase${_itemPath(relPath)}/createUploadSession'),
          headers: _headers(json: true),
          body: jsonEncode({
            'item': {
              '@microsoft.graph.conflictBehavior': 'replace',
            },
          }),
        ));
    final uploadUrl = _json(create)?['uploadUrl'] as String?;
    if (uploadUrl == null) {
      throw StateError(
          'OneDrive 创建上传会话失败：${utf8.decode(create.bodyBytes)}');
    }
    final total = bytes.length;
    for (var offset = 0; offset < total; offset += _chunkSize) {
      final end = (offset + _chunkSize) > total ? total : offset + _chunkSize;
      final res = await _http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Range': 'bytes $offset-${end - 1}/$total',
        },
        body: bytes.sublist(offset, end),
      );
      if (res.statusCode != 202 &&
          res.statusCode != 201 &&
          res.statusCode != 200) {
        throw StateError('OneDrive 分片上传失败：${utf8.decode(res.bodyBytes)}');
      }
    }
  }

  // ---- 快照 / 媒体接口（内部路径统一为 approot 相对路径）----

  String _rel(String webPath) => webPath.replaceFirst('/glean/', '');

  @override
  Future<bool> backupExists() async {
    final list = await _listDir('media');
    return list.containsKey('backup.json');
  }

  @override
  Future<void> upload(String content) async {
    await _ensureMediaDir();
    await _upload('media/backup.json', utf8.encode(content));
  }

  @override
  Future<String?> download() async {
    final bytes = await _download('media/backup.json');
    return bytes == null ? null : utf8.decode(bytes);
  }

  @override
  Future<Uint8List?> readMedia(String path) => _download(_rel(path));

  @override
  Future<Map<String, int>> listMedia() => _listDir('media');

  @override
  Future<bool> deleteMedia(String path) async {
    final res = await _request(() => _http.delete(
          Uri.parse('$graphBase${_itemPath(_rel(path))}'),
          headers: _headers(),
        ));
    return res.statusCode == 204 || res.statusCode == 404;
  }
}