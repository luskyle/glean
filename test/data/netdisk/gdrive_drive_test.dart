import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glean/data/sync/netdisk/common.dart';
import 'package:glean/data/sync/netdisk/gdrive_drive.dart';

Future<GoogleDriveDrive> _drive(MockClient client) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('gdrive.access_token', 'mock-token');
  await prefs.setInt(
    'gdrive.token_expires_at',
    DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  );
  return GoogleDriveDrive(
    clientId: 'id',
    clientSecret: 'secret',
    tokenStore: PrefsTokenStore(prefs, 'gdrive'),
    httpClient: client,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('upload：multipart 上传到 AppData，同名先删', () async {
    final calls = <String>[];
    final client = MockClient((request) async {
      calls.add(request.method);
      if (request.url.toString().contains('uploadType=multipart')) {
        // multipart body 应同时含 metadata 与文件字节
        final body = utf8.decode(request.bodyBytes);
        expect(body, contains('"name":"backup.json"'));
        expect(body, contains('"parents":["appDataFolder"]'));
        return http.Response('{"id":"f1"}', 200);
      }
      if (request.method == 'DELETE') {
        return http.Response('', 204);
      }
      // files.list 查询（同名删除 + 其它）
      return http.Response(jsonEncode({'files': []}), 200);
    });
    final drive = await _drive(client);
    await drive.upload('{"app":"glean"}');

    expect(calls.where((c) => c == 'POST').length, greaterThanOrEqualTo(1));
    expect(calls, isNot(contains('DELETE')), reason: '无同名文件（列表为空）不应删除');
  });

  test('listMedia：列 media 目录（AppData）', () async {
    final client = MockClient((request) async {
      final q = request.url.queryParameters['q'] ?? '';
      if (q.contains('application/vnd.google-apps.folder')) {
        // 目录定位查询：返回 media 目录
        return http.Response(
          jsonEncode({
            'files': [
              {
                'id': 'media-fid',
                'name': 'media',
                'mimeType': 'application/vnd.google-apps.folder',
              },
            ],
          }),
          200,
        );
      }
      // 其余（media 目录 children）返回文件
      return http.Response(
        jsonEncode({
          'files': [
            {'id': 'a', 'name': '-1.jpg', 'size': 10},
            {'id': 'b', 'name': '-2.mp4', 'size': 20},
          ],
        }),
        200,
      );
    });
    final drive = await _drive(client);
    expect(await drive.listMedia(), {'-1.jpg': 10, '-2.mp4': 20});
  });

  test('download：alt=media 下载字节', () async {
    final client = MockClient((request) async {
      if (request.url.queryParameters['alt'] == 'media') {
        expect(request.url.path, contains('files/'));
        return http.Response('{"app":"glean"}', 200);
      }
      // 查询 backup.json 的 file id
      return http.Response(
        jsonEncode({
          'files': [
            {'id': 'bk', 'name': 'backup.json'},
          ],
        }),
        200,
      );
    });
    final drive = await _drive(client);
    expect(await drive.download(), '{"app":"glean"}');
  });

  test('deleteMedia：file id 删除成功 / 不存在幂等', () async {
    var status = 204;
    final client = MockClient((request) async {
      if (request.method == 'DELETE') {
        return http.Response('', status);
      }
      return http.Response(
        jsonEncode({
          'files': [
            {'id': 'media-fid', 'name': 'media', 'mimeType': 'application/vnd.google-apps.folder'},
            {'id': 'x', 'name': '-1.jpg', 'size': 1},
          ],
        }),
        200,
      );
    });
    final drive = await _drive(client);
    expect(await drive.deleteMedia('/glean/media/-1.jpg'), isTrue);

    status = 404; // 幂等
    expect(await drive.deleteMedia('/glean/media/-1.jpg'), isTrue);
  });

  test('令牌失效 401 自动刷新后重试', () async {
    var failing = 1; // 单次过期：刷新后重试即成功
    final client = MockClient((request) async {
      if (request.url.toString() == 'https://oauth2.googleapis.com/token') {
        return http.Response(
          jsonEncode({
            'access_token': 'new-token',
            'refresh_token': 'new-refresh',
            'expires_in': 3600,
          }),
          200,
        );
      }
      if (failing-- > 0) return http.Response('', 401);
      final q = request.url.queryParameters['q'] ?? '';
      if (q.contains('application/vnd.google-apps.folder')) {
        return http.Response(
          jsonEncode({
            'files': [
              {
                'id': 'media-fid',
                'name': 'media',
                'mimeType': 'application/vnd.google-apps.folder',
              },
            ],
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'files': [
            {'id': 'a', 'name': '-1.jpg', 'size': 1},
          ],
        }),
        200,
      );
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gdrive.access_token', 'old');
    await prefs.setString('gdrive.refresh_token', 'rt');
    final drive = GoogleDriveDrive(
      clientId: 'id',
      clientSecret: 'secret',
      tokenStore: PrefsTokenStore(prefs, 'gdrive'),
      httpClient: client,
    );

    expect(await drive.listMedia(), {'-1.jpg': 1});
    expect(prefs.getString('gdrive.access_token'), 'new-token');
  });
}