import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 通用网盘令牌（access + refresh + 有效期）。
class NetdiskToken {
  const NetdiskToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;

  /// 有效期（秒）。
  final int expiresIn;
}

class NetdiskAuthException implements Exception {
  NetdiskAuthException(this.message);

  final String message;

  @override
  String toString() => 'NetdiskAuthException: $message';
}

/// 通用令牌持久化：以 [prefix] 隔离各家网盘（shared_preferences）。
class PrefsTokenStore {
  PrefsTokenStore(this._prefs, this.prefix);

  final SharedPreferences _prefs;
  final String prefix;

  String get _kAt => '$prefix.access_token';
  String get _kRt => '$prefix.refresh_token';
  String get _kExp => '$prefix.token_expires_at';

  String? get accessToken => _prefs.getString(_kAt);
  String? get refreshToken => _prefs.getString(_kRt);
  int? get expiresAt => _prefs.getInt(_kExp);

  bool get hasToken => accessToken != null && accessToken!.isNotEmpty;

  bool get isExpired {
    final exp = expiresAt;
    return exp != null && (DateTime.now().millisecondsSinceEpoch ~/ 1000) >= exp;
  }

  Future<void> save(NetdiskToken t, {String? keepRefreshToken}) async {
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

/// 标准 OAuth2 表单换取令牌（authorization_code / refresh_token 通用）。
Future<NetdiskToken> exchangeNetdiskToken({
  required Uri endpoint,
  required Map<String, String> body,
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  final res = await c.post(endpoint, body: body);
  final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  final at = json['access_token'];
  if (at == null) {
    throw NetdiskAuthException(
      '授权失败：${json['error_description'] ?? json['error'] ?? res.body}',
    );
  }
  return NetdiskToken(
    accessToken: at as String,
    refreshToken: (json['refresh_token'] as String?) ?? '',
    expiresIn: (json['expires_in'] as num?)?.toInt() ?? 0,
  );
}