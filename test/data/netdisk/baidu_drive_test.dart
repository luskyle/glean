import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glean/data/sync/netdisk/baidu_auth.dart';
import 'package:glean/data/sync/netdisk/baidu_drive.dart';

/// 构造带令牌的 [BaiduDrive]（协议层测试，不触网）。
Future<BaiduDrive> _drive(MockClient client, {String token = 'mock-token'}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('baidu.access_token', token);
  await prefs.setInt(
    'baidu.token_expires_at',
    DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  );
  return BaiduDrive(
    clientId: 'test-id',
    clientSecret: 'test-secret',
    tokenStore: BaiduTokenStore(prefs),
    httpClient: client,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('upload：分片上传（tmpfile）→ 合并（create）参数正确', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.contains('superfile2') &&
          request.url.queryParameters['method'] == 'upload') {
        // 分片接口返回块 md5（merge create 用）
        return http.Response(jsonEncode({'errno': 0, 'md5': 'mock-md5'}), 200);
      }
      return http.Response(jsonEncode({'errno': 0}), 200);
    });
    final drive = await _drive(client);

    await drive.upload('{"app":"glean"}');

    // 请求序列：mkdir ×2 → upload(tmpfile) → create
    final uploads =
        requests.where((r) => r.url.path.contains('superfile2')).toList();
    expect(uploads.length, 2, reason: '单片上传 + 合并');

    final upload = uploads[0];
    expect(upload.url.queryParameters['method'], 'upload');
    expect(upload.url.queryParameters['type'], 'tmpfile');
    expect(upload.url.queryParameters['partseq'], '0');
    expect(upload.url.queryParameters['size'], '15');
    expect(upload.url.queryParameters['path'], '/apps/glean/backup.json');

    final create = uploads[1];
    expect(create.url.queryParameters['method'], 'create');
    final blockList =
        jsonDecode(create.bodyFields['block_list'] ?? '[]') as List;
    expect(blockList, isNotEmpty);
  });

  test('listMedia：解析网盘目录为 文件名→大小', () async {
    final client = MockClient((request) async {
      final json = switch (request.url.path) {
        '/rest/2.0/xpan/file' => {
            'errno': 0,
            'list': [
              {'server_filename': '-1001.jpg', 'size': 2048, 'isdir': 0},
              {'server_filename': '-1002.mp4', 'size': 4096, 'isdir': 0},
              {'server_filename': 'sub', 'isdir': 1},
            ],
          },
        _ => const {'errno': 0, 'list': []},
      };
      return http.Response(jsonEncode(json), 200);
    });
    final drive = await _drive(client);

    final list = await drive.listMedia();
    expect(list, {'-1001.jpg': 2048, '-1002.mp4': 4096});
  });

  test('download：读取快照文本', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/rest/2.0/pcs/file');
      expect(request.url.queryParameters['method'], 'download');
      expect(request.url.queryParameters['path'], '/apps/glean/backup.json');
      return http.Response('{"app":"glean"}', 200);
    });
    final drive = await _drive(client);

    expect(await drive.download(), '{"app":"glean"}');
  });

  test('deleteMedia：删除成功 / 文件不存在均视为成功', () async {
    var errno = 0;
    final client = MockClient((request) async {
      return http.Response(jsonEncode({'errno': errno}), 200);
    });
    final drive = await _drive(client);
    expect(await drive.deleteMedia('/glean/media/-1.jpg'), isTrue);

    errno = -9; // 文件不存在（幂等删除）
    expect(await drive.deleteMedia('/glean/media/-1.jpg'), isTrue);
  });

  test('令牌失效（errno 111）自动刷新后重试', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (request.url.path.contains('oauth/2.0/token')) {
        return http.Response(
          jsonEncode({
            'access_token': 'new-token',
            'refresh_token': 'new-refresh',
            'expires_in': 3600,
          }),
          200,
        );
      }
      if (calls <= 2) {
        return http.Response(jsonEncode({'errno': 111}), 401);
      }
      return http.Response(jsonEncode({'errno': 0, 'list': []}), 200);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baidu.access_token', 'old-token');
    await prefs.setString('baidu.refresh_token', 'rt');
    final drive = BaiduDrive(
      clientId: 'id',
      clientSecret: 'secret',
      tokenStore: BaiduTokenStore(prefs),
      httpClient: client,
    );

    expect(await drive.listMedia(), isEmpty);
    expect(prefs.getString('baidu.access_token'), 'new-token',
        reason: '应自动刷新并持久化新令牌');
  });
}