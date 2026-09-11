import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../cloud_drive.dart';
import 'common.dart';

/// Google Drive 适配器（C 档网盘适配器；Drive API v3）。
///
/// 使用「AppData 专属空间」（scope: drive.appdata）——应用看不见用户
/// 的其它文件，数据只出现在「Google 云端硬盘 → 应用数据」里。
/// 上传用 multipart（metadata + media），下载 alt=media，列表按父目录查询。
class GoogleDriveDrive implements CloudDrive {
  GoogleDriveDrive({
    required this.clientId,
    required this.clientSecret,
    required this.tokenStore,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String clientId;
  final String clientSecret;
  final PrefsTokenStore tokenStore;
  final http.Client _http;

  static const authorizeUrl = 'https://accounts.google.com/o/oauth2/v2/auth';
  static const tokenUrl = 'https://oauth2.googleapis.com/token';
  static const apiBase = 'https://www.googleapis.com/drive/v3';
  static const uploadBase = 'https://www.googleapis.com/upload/drive/v3';
  static const _scope = 'https://www.googleapis.com/auth/drive.appdata';
  static const _folderMime = 'application/vnd.google-apps.folder';

  String? get _token => tokenStore.accessToken;

  @override
  String get name => 'Google 云端硬盘';

  static String buildAuthorizeUrl(String clientId) {
    return '$authorizeUrl?client_id=${Uri.encodeQueryComponent(clientId)}'
        '&redirect_uri=oob&response_type=code'
        '&scope=${Uri.encodeQueryComponent(_scope)}'
        '&access_type=offline&prompt=consent';
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

  bool _tokenInvalid(http.Response res) => res.statusCode == 401;

  Map<String, String> _bearer() => {'Authorization': 'Bearer ${_token ?? ''}'};

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

  /// 查询文件：{名字 → id}（限定父目录与类型）。
  Future<Map<String, String>> _query({
    required String parent,
    bool folderOnly = false,
  }) async {
    final q = "'$parent' in parents"
        " and name != '' and trashed = false"
        '${folderOnly ? " and mimeType = '$_folderMime'" : ''}';
    final res = await _request(() => _http.get(
          Uri.parse('$apiBase/files')
              .replace(queryParameters: {
            'spaces': 'appDataFolder',
            'q': q,
            'fields': 'files(id,name,size,mimeType)',
            'pageSize': '1000',
          }),
          headers: _bearer(),
        ));
    if (res.statusCode != 200) return const {};
    final files = _json(res)?['files'] as List? ?? const [];
    return {
      for (final f in files.cast<Map<String, dynamic>>())
        if (f['name'] is String) f['name'] as String: f['id'] as String,
    };
  }

  /// 确保 AppData 下有 media 目录，返回其 file id（幂等）。
  Future<String> _ensureMediaDir() async {
    final dirs = await _query(parent: 'appDataFolder', folderOnly: true);
    final existing = dirs['media'];
    if (existing != null) return existing;
    final res = await _request(() => _http.post(
          Uri.parse('$apiBase/files?fields=id'),
          headers: {..._bearer(), 'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': 'media',
            'mimeType': _folderMime,
            'parents': ['appDataFolder'],
          }),
        ));
    final id = _json(res)?['id'] as String?;
    if (id == null) {
      throw StateError('创建 Google Drive media 目录失败：${utf8.decode(res.bodyBytes)}');
    }
    return id;
  }

  /// multipart 上传（metadata + media）；同名文件先删（覆盖语义）。
  Future<void> _upload(String relPath, List<int> bytes) async {
    final parent =
        relPath.contains('/') ? await _ensureMediaDir() : 'appDataFolder';
    final name = relPath.split('/').last;

    // 覆盖：删同名旧文件
    final existing = await _query(parent: parent);
    final oldId = existing[name];
    if (oldId != null) {
      await _request(() => _http.delete(
            Uri.parse('$apiBase/files/$oldId'),
            headers: _bearer(),
          ));
    }

    const boundary = 'glean-upload-boundary';
    final meta = jsonEncode({
      'name': name,
      'parents': [parent],
    });
    final out = BytesBuilder();
    out.add(utf8.encode(
        '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n'
        '$meta\r\n'
        '--$boundary\r\nContent-Type: application/octet-stream\r\n\r\n'));
    out.add(bytes);
    out.add(utf8.encode('\r\n--$boundary--\r\n'));

    final res = await _request(() => _http.post(
          Uri.parse('$uploadBase/files?uploadType=multipart&fields=id'),
          headers: {
            ..._bearer(),
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: out.toBytes(),
        ));
    if (res.statusCode != 200) {
      throw StateError('Google Drive 上传失败：${utf8.decode(res.bodyBytes)}');
    }
  }

  // ---- 快照 / 媒体接口 ----

  String _rel(String webPath) => webPath.replaceFirst('/glean/', '');

  @override
  Future<bool> backupExists() async {
    final files = await _query(parent: 'appDataFolder');
    return files.containsKey('backup.json');
  }

  @override
  Future<void> upload(String content) async {
    await _upload('backup.json', utf8.encode(content));
  }

  @override
  Future<String?> download() async {
    final bytes = await _download('backup.json');
    return bytes == null ? null : utf8.decode(bytes);
  }

  Future<Uint8List?> _download(String relPath) async {
    final parent = relPath.contains('/') ? (await _ensureMediaDir()) : 'appDataFolder';
    final files = await _query(parent: parent);
    final id = files[relPath.split('/').last];
    if (id == null) return null;
    final res = await _request(() => _http.get(
          Uri.parse('$apiBase/files/$id?alt=media'),
          headers: _bearer(),
        ));
    if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
    return res.bodyBytes;
  }

  @override
  Future<Uint8List?> readMedia(String path) => _download(_rel(path));

  @override
  Future<Map<String, int>> listMedia() async {
    final parent = await _ensureMediaDir();
    final res = await _request(() => _http.get(
          Uri.parse('$apiBase/files')
              .replace(queryParameters: {
            'spaces': 'appDataFolder',
            'q': "'$parent' in parents and trashed = false",
            'fields': 'files(id,name,size)',
          }),
          headers: _bearer(),
        ));
    if (res.statusCode != 200) return const {};
    return {
      for (final f in (_json(res)?['files'] as List? ?? const [])
          .cast<Map<String, dynamic>>())
        if (f['name'] is String && f['size'] is num)
          f['name'] as String: (f['size'] as num).toInt(),
    };
  }

  @override
  Future<bool> deleteMedia(String path) async {
    final rel = _rel(path);
    final parent = rel.contains('/') ? (await _ensureMediaDir()) : 'appDataFolder';
    final files = await _query(parent: parent);
    final id = files[rel.split('/').last];
    if (id == null) return true; // 不存在 → 幂等
    final res = await _request(() => _http.delete(
          Uri.parse('$apiBase/files/$id'),
          headers: _bearer(),
        ));
    return res.statusCode == 204 || res.statusCode == 404;
  }
}