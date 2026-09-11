import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glean/data/sync/netdisk/common.dart';
import 'package:glean/data/sync/netdisk/dropbox_drive.dart';

const _api = 'https://api.dropboxapi.com/2';
const _content = 'https://content.dropboxapi.com/2';

Future<DropboxDrive> _drive(MockClient client) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('dropbox.access_token', 'mock-token');
  await prefs.setInt(
    'dropbox.token_expires_at',
    DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  );
  return DropboxDrive(
    clientId: 'id',
    clientSecret: 'secret',
    tokenStore: PrefsTokenStore(prefs, 'dropbox'),
    httpClient: client,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('upload：建目录 → files/upload 携带 Dropbox-API-Arg', () async {
    final reqs = <http.Request>[];
    final client = MockClient((request) async {
      reqs.add(request);
      return http.Response('{}', 200);
    });
    final drive = await _drive(client);
    await drive.upload('{"app":"glean"}');

    final upload = reqs.firstWhere(
        (r) => r.url.toString() == '$_content/files/upload');
    final arg = jsonDecode(upload.headers['dropbox-api-arg']!) as Map;
    expect(arg['path'], '/apps/glean/backup.json');
    expect(arg['mode'], 'overwrite');

    final mkdirs = reqs
        .where((r) => r.url.toString() == '$_api/files/create_folder_v2')
        .toList();
    expect(mkdirs.length, 2, reason: '应用目录 + media 目录');
  });

  test('listMedia：解析 entries（文件带 size，目录跳过）', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'entries': [
            {'name': '-1.jpg', '.tag': 'file', 'size': 10},
            {'name': '-2.mp4', '.tag': 'file', 'size': 20},
            {'name': 'sub', '.tag': 'folder'},
          ],
        }),
        200,
      );
    });
    final drive = await _drive(client);
    expect(await drive.listMedia(), {'-1.jpg': 10, '-2.mp4': 20});
  });

  test('download：files/download 返回字节', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), '$_content/files/download');
      final arg = jsonDecode(request.headers['dropbox-api-arg']!) as Map;
      expect(arg['path'], '/apps/glean/backup.json');
      return http.Response('{"app":"glean"}', 200);
    });
    final drive = await _drive(client);
    expect(await drive.download(), '{"app":"glean"}');
  });

  test('deleteMedia：delete_v2 成功 / not_found 幂等', () async {
    var tag = '';
    final client = MockClient((request) async {
      if (tag.isEmpty) return http.Response('{}', 200);
      return http.Response(
        jsonEncode({'error': {'.tag': tag}}),
        409,
      );
    });
    final drive = await _drive(client);
    expect(await drive.deleteMedia('/glean/media/-1.jpg'), isTrue);

    tag = 'path_lookup'; // 文件不存在
    expect(await drive.deleteMedia('/glean/media/-1.jpg'), isTrue);
  });

  test('令牌失效（expired_access_token）自动刷新后重试', () async {
    var failing = 2;
    final client = MockClient((request) async {
      if (request.url.toString() == 'https://api.dropboxapi.com/oauth2/token') {
        return http.Response(
          jsonEncode({
            'access_token': 'new-token',
            'refresh_token': 'new-refresh',
            'expires_in': 14400,
          }),
          200,
        );
      }
      if (failing-- > 0) {
        return http.Response(
          jsonEncode({'error': {'.tag': 'expired_access_token'}}),
          401,
        );
      }
      return http.Response(jsonEncode({'entries': []}), 200);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dropbox.access_token', 'old');
    await prefs.setString('dropbox.refresh_token', 'rt');
    final drive = DropboxDrive(
      clientId: 'id',
      clientSecret: 'secret',
      tokenStore: PrefsTokenStore(prefs, 'dropbox'),
      httpClient: client,
    );

    expect(await drive.listMedia(), isEmpty);
    expect(prefs.getString('dropbox.access_token'), 'new-token');
  });
}