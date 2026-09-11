import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 百度网盘 OAuth2 令牌数据。
class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;

  /// 有效期（秒）。
  final int expiresIn;
}

class BaiduAuthException implements Exception {
  BaiduAuthException(this.message);

  final String message;

  @override
  String toString() => 'BaiduAuthException: $message';
}

/// 百度网盘 OAuth2 流程（桌面友好模式）：
/// 生成授权 URL（oob）→ 用户浏览器授权 → 粘贴 code → 换 token；
/// 过期后自动 refresh。
class BaiduAuth {
  static const authorizeUrl = 'https://openapi.baidu.com/oauth/2.0/authorize';
  static const tokenUrl = 'https://openapi.baidu.com/oauth/2.0/token';
  static const redirectUri = 'oob';
  static const scope = 'basic,netdisk';

  /// 生成浏览器授权页 URL（应用需在百度开放平台申请 PCS/网盘权限）。
  static String buildAuthorizeUrl(String clientId) {
    return '$authorizeUrl?response_type=code'
        '&client_id=${Uri.encodeQueryComponent(clientId)}'
        '&redirect_uri=$redirectUri&scope=$scope&display=page';
  }

  /// 用授权 code 换取 token。
  static Future<TokenResponse> exchangeCode({
    required String code,
    required String clientId,
    required String clientSecret,
    http.Client? client,
  }) async {
    final res = await _post(client, {
      'grant_type': 'authorization_code',
      'code': code,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri,
    });
    return _decode(res);
  }

  /// 用 refresh_token 刷新 access_token。
  static Future<TokenResponse> refresh({
    required String refreshToken,
    required String clientId,
    required String clientSecret,
    http.Client? client,
  }) async {
    final res = await _post(client, {
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
      'client_id': clientId,
      'client_secret': clientSecret,
    });
    return _decode(res);
  }

  static Future<http.Response> _post(
    http.Client? client,
    Map<String, String> body,
  ) {
    final c = client ?? http.Client();
    return c.post(Uri.parse(tokenUrl), body: body);
  }

  static TokenResponse _decode(http.Response res) {
    final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final at = json['access_token'];
    if (at == null) {
      throw BaiduAuthException(
        '授权失败：${json['error_description'] ?? json['error'] ?? res.body}',
      );
    }
    return TokenResponse(
      accessToken: at as String,
      refreshToken: (json['refresh_token'] as String?) ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
    );
  }
}

/// 百度令牌持久化（shared_preferences；与设置同仓库，随 App 数据导出不带走令牌）。
class BaiduTokenStore {
  BaiduTokenStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kAt = 'baidu.access_token';
  static const _kRt = 'baidu.refresh_token';
  static const _kExp = 'baidu.token_expires_at'; // epoch 秒

  String? get accessToken => _prefs.getString(_kAt);
  String? get refreshToken => _prefs.getString(_kRt);
  int? get expiresAt => _prefs.getInt(_kExp);

  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;

  bool get isExpired {
    final exp = expiresAt;
    return exp != null && (DateTime.now().millisecondsSinceEpoch ~/ 1000) >= exp;
  }

  Future<void> save(TokenResponse t, {String? keepRefreshToken}) async {
    await _prefs.setString(_kAt, t.accessToken);
    final rt = keepRefreshToken ?? t.refreshToken;
    if (rt.isNotEmpty) await _prefs.setString(_kRt, rt);
    await _prefs.setInt(
      _kExp,
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + t.expiresIn,
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_kAt);
    await _prefs.remove(_kRt);
    await _prefs.remove(_kExp);
  }
}