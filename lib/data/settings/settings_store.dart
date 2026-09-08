import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置 KV（Hive 缓存的轻量替代：设置类数据无需关系查询）。
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kPro = 'settings.is_pro';
  static const _kClipboardWatch = 'settings.clipboard_watch';
  static const _kOnboarded = 'settings.onboarded';
  static const _kThemeMode = 'settings.theme_mode';
  static const _kViewMode = 'settings.library_view_mode';

  /// 是否 Pro（MVP 阶段默认 false；内购在阶段 2 接入）。
  bool get isPro => _prefs.getBool(_kPro) ?? false;
  Future<void> setPro(bool v) => _prefs.setBool(_kPro, v);

  /// 剪贴板监听开关（可关闭）。
  bool get clipboardWatchEnabled => _prefs.getBool(_kClipboardWatch) ?? true;
  Future<void> setClipboardWatch(bool v) => _prefs.setBool(_kClipboardWatch, v);

  /// 主题模式：system | light | dark。
  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> setThemeMode(String v) => _prefs.setString(_kThemeMode, v);

  /// 记忆库视图：list | grid（网格卡片）。
  String get libraryViewMode => _prefs.getString(_kViewMode) ?? 'list';
  Future<void> setLibraryViewMode(String v) => _prefs.setString(_kViewMode, v);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded() => _prefs.setBool(_kOnboarded, true);

  /// 已处理过的剪贴板指纹（避免重复提示）。
  String? get lastClipboardFingerprint =>
      _prefs.getString('settings.last_clipboard_fp');
  Future<void> setLastClipboardFingerprint(String fp) =>
      _prefs.setString('settings.last_clipboard_fp', fp);

  // ---- 云盘同步（B 档）----

  /// 同步通道：none | icloud | webdav。
  String get syncChannel => _prefs.getString('settings.sync_channel') ?? 'none';
  Future<void> setSyncChannel(String v) =>
      _prefs.setString('settings.sync_channel', v);

  String? get webdavUrl => _prefs.getString('settings.webdav_url');
  Future<void> setWebdavUrl(String v) =>
      _prefs.setString('settings.webdav_url', v);

  String? get webdavUser => _prefs.getString('settings.webdav_user');
  Future<void> setWebdavUser(String v) =>
      _prefs.setString('settings.webdav_user', v);

  String? get webdavPassword => _prefs.getString('settings.webdav_password');
  Future<void> setWebdavPassword(String v) =>
      _prefs.setString('settings.webdav_password', v);

  /// 最近一次备份时间（本地展示用）。
  DateTime? get lastBackupAt {
    final raw = _prefs.getString('settings.last_backup_at');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> markBackupNow() => _prefs.setString(
      'settings.last_backup_at', DateTime.now().toIso8601String());
}

/// 免费额度（非 Pro）。
class Quota {
  const Quota._();

  static const int maxLibraryCards = 100;
  static const int maxDailyReviews = 30;
}
