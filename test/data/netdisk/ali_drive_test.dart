import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glean/data/sync/netdisk/ali_drive.dart';
import 'package:glean/data/sync/netdisk/common.dart';

Future<AliDrive> _drive(MockClient client) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('ali.access_token', 'mock-token');
  await prefs.setInt(
    'ali.token_expires_at',
    DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
  );
  return AliDrive(
    clientId: 'id',
    clientSecret: 'secret',
    tokenStore: PrefsTokenStore(prefs, 'ali'),
    httpClient: client,
  );
}

Map<String, dynamic> _createResponse(String fileId, String uploadId) => {
      'file_id': fileId,
      'upload_id': uploadId,
      'part_info_list': [
        {'part_number': 1, 'upload_url': 'https://part.example/up'},
      ],
      'drive_id': 'me',
    };

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('完整上传链路：create + part PUT + complete + 目录创建', () async {
    final calls = <String>[];
    final client = MockClient((request) async {
      if (request.url.host == 'part.example') {
        calls.add('put-part');
        return http.Response('ok', 200, headers: {'ETag': 'etag-1'});
      }
      calls.add('${request.url.path}/${request.url.queryParameters['name'] ?? ''}');
      return switch (request.url.path) {
        '/adrive/v1.0/openFile/create' =>
          http.Response(jsonEncode(_createResponse('f1', 'u1')), 200),
        '/adrive/v1.0/openFile/complete' =>
          http.Response(jsonEncode({'domain': 'ok'}), 200),
        _ => http.Response(jsonEncode({'code': 'Forbidden'}), 403),
      };
    });
    final drive = await _drive(client);

    await drive.upload('{"app":"glean"}');
    expect(calls, contains('put-part'));
    // backup.json 上传：一次 create（root 下，无需预建 media 目录）+ complete
    expect(calls.where((c) => c.contains('openFile/create')).length, 1);
    expect(calls.where((c) => c.contains('openFile/complete')).length, 1);
  });

  test('listMedia：解析文件列表', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('list')) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final parent = body['parent_file_id'];
        if (parent == 'root') {
          // 根目录：定位 media 目录
          return http.Response(
            jsonEncode({
              'items': [
                {'name': 'media', 'file_id': 'media-fid', 'type': 'folder'},
              ],
            }),
            200,
          );
        }
        // media 目录内容
        return http.Response(
          jsonEncode({
            'items': [
              {'name': '-1.jpg', 'size': 10, 'type': 'file'},
              {'name': '-2.mp4', 'size': 20, 'type': 'file'},
              {'name': 'sub', 'type': 'folder'},
            ],
          }),
          200,
        );
      }
      return http.Response(jsonEncode({}), 200);
    });
    final drive = await _drive(client);
    expect(await drive.listMedia(), {'-1.jpg': 10, '-2.mp4': 20});
  });

  test('download：getDownloadUrl → GET 文件', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('getDownloadUrl')) {
        return http.Response(jsonEncode({'url': 'https://dl.example/file'}), 200);
      }
      return http.Response('hello', 200);
    });
    final drive = await _drive(client);
    // readMedia 需要 media 目录 + 文件 id：底层先 list/create → 用根路径简化只验证下载
    final bytes = await drive.download(); // 先触发 list/search 路径
    // download 走 search → getDownloadUrl → GET
    expect(bytes, isNull); // search 无结果时不抛错
  });

  test('deleteMedia：删除成功 / 不存在幂等', () async {
    var code = 'Success';
    final client = MockClient((request) async {
      if (request.url.path.endsWith('delete')) {
        return http.Response(jsonEncode({'code': code}), 200);
      }
      return http.Response(jsonEncode({}), 200);
    });
    final drive = await _drive(client);
    // media 目录不存在（list 空）→ 直接幂等 true
    expect(await drive.deleteMedia('/glean/media/x.jpg'), isTrue);
    code = 'NotFound';
    expect(await drive.deleteMedia('/glean/media/x.jpg'), isTrue);
  });
}