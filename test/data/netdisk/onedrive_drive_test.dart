import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glean/data/sync/netdisk/common.dart';
import 'package:glean/data/sync/netdisk/onedrive_drive.dart';

const _graph = 'https://graph.microsoft.com/v1.0';

Future<OneDriveDrive> _drive(MockClient client) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('onedrive.access_token', 'mock-token');
  await prefs.setInt(
    'onedrive.token_expires_at',
    DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  );
  return OneDriveDrive(
    clientId: 'id',
    clientSecret: 'secret',
    tokenStore: PrefsTokenStore(prefs, 'onedrive'),
    httpClient: client,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('upload：建目录(mkdir) → 小文件 PUT 到 approot 正确路径', () async {
    final calls = <String>[];
    final client = MockClient((request) async {
      calls.add('${request.method} ${request.url.toString()}');
      return switch (request.url.path) {
        '$_graph/me/drive/special/approot:/media:/children' =>
          http.Response('{}', 201),
        _ => http.Response('{}', 201),
      };
    });
    final drive = await _drive(client);

    await drive.upload('{"app":"glean"}');

    expect(
      calls,
      contains('POST $_graph/me/drive/special/approot:/media:/children'),
    );
    expect(
      calls,
      contains(
          'PUT $_graph/me/drive/special/approot:/media/backup.json:/content'),
    );
  });

  test('listMedia：解析 children 为 文件名→大小', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'value': [
            {'name': '-1.jpg', 'size': 10, 'file': {'mimeType': 'image/jpeg'}},
            {'name': '-2.mp4', 'size': 20, 'file': {}},
            {'name': 'sub', 'folder': {}},
          ],
        }),
        200,
      );
    });
    final drive = await _drive(client);
    expect(await drive.listMedia(), {'-1.jpg': 10, '-2.mp4': 20});
  });

  test('download：GET approot content 返回文本', () async {
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        '$_graph/me/drive/special/approot:/media/backup.json:/content',
      );
      return http.Response('{"app":"glean"}', 200);
    });
    final drive = await _drive(client);
    expect(await drive.download(), '{"app":"glean"}');
  });

  test('deleteMedia：DELETE approot 路径，204 / 404 视为成功', () async {
    var status = 204;
    final client = MockClient((request) async {
      expect(request.method, 'DELETE');
      expect(
        request.url.toString(),
        '$_graph/me/drive/special/approot:/media/-1.jpg:',
      );
      return http.Response('', status);
    });
    final drive = await _drive(client);
    expect(await drive.deleteMedia('/glean/media/-1.jpg'), isTrue);

    status = 404; // 文件不存在（幂等删除）
    expect(await drive.deleteMedia('/glean/media/-1.jpg'), isTrue);
  });

  test('令牌失效 401 自动刷新后重试', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (request.url.host == 'login.microsoftonline.com') {
        return http.Response(
          jsonEncode({
            'access_token': 'new-token',
            'refresh_token': 'new-refresh',
            'expires_in': 3600,
          }),
          200,
        );
      }
      if (calls <= 2) return http.Response('', 401);
      return http.Response(jsonEncode({'value': []}), 200);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onedrive.access_token', 'old');
    await prefs.setString('onedrive.refresh_token', 'rt');
    final drive = OneDriveDrive(
      clientId: 'id',
      clientSecret: 'secret',
      tokenStore: PrefsTokenStore(prefs, 'onedrive'),
      httpClient: client,
    );

    expect(await drive.listMedia(), isEmpty);
    expect(prefs.getString('onedrive.access_token'), 'new-token');
  });
}