import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置 KV（Hive 缓存的轻量替代：设置类数据无需关系查询）。
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kPro = 'settings.is_pro';
  static const _kClipboardWatch = 'settings.clipboard_watch';
  static const _kOnboarded = 'settings.onboarded';

  /// 是否 Pro（MVP 阶段默认 false；内购在阶段 2 接入）。
  bool get isPro => _prefs.getBool(_kPro) ?? false;
  Future<void> setPro(bool v) => _prefs.setBool(_kPro, v);

  /// 剪贴板监听开关（可关闭）。
  bool get clipboardWatchEnabled => _prefs.getBool(_kClipboardWatch) ?? true;
  Future<void> setClipboardWatch(bool v) => _prefs.setBool(_kClipboardWatch, v);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded() => _prefs.setBool(_kOnboarded, true);

  /// 已处理过的剪贴板指纹（避免重复提示）。
  String? get lastClipboardFingerprint =>
      _prefs.getString('settings.last_clipboard_fp');
  Future<void> setLastClipboardFingerprint(String fp) =>
      _prefs.setString('settings.last_clipboard_fp', fp);
}

/// 免费额度（非 Pro）。
class Quota {
  const Quota._();

  static const int maxLibraryCards = 100;
  static const int maxDailyReviews = 30;
}