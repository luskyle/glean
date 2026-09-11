import 'package:shared_preferences/shared_preferences.dart';

/// 应用设置 KV（Hive 缓存的轻量替代：设置类数据无需关系查询）。
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kPro = 'settings.is_pro';
  static const _kOnboarded = 'settings.onboarded';
  static const _kThemeMode = 'settings.theme_mode';

  /// 是否 Pro（MVP 阶段默认 false；内购在阶段 2 接入）。
  bool get isPro => _prefs.getBool(_kPro) ?? false;
  Future<void> setPro(bool v) => _prefs.setBool(_kPro, v);

  /// 主题模式：system | light | dark。
  String get themeMode => _prefs.getString(_kThemeMode) ?? 'system';
  Future<void> setThemeMode(String v) => _prefs.setString(_kThemeMode, v);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded() => _prefs.setBool(_kOnboarded, true);

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

  // ---- 百度网盘（C 档网盘适配器）----

  /// 客户端 ID / Secret（百度开放平台申请，PCS 网盘权限）。
  String? get baiduClientId => _prefs.getString('settings.baidu_client_id');
  Future<void> setBaiduClientId(String v) =>
      _prefs.setString('settings.baidu_client_id', v);

  String? get baiduClientSecret => _prefs.getString('settings.baidu_client_secret');
  Future<void> setBaiduClientSecret(String v) =>
      _prefs.setString('settings.baidu_client_secret', v);

  // ---- 阿里云盘（C 档网盘适配器）----

  String? get aliClientId => _prefs.getString('settings.ali_client_id');
  Future<void> setAliClientId(String v) =>
      _prefs.setString('settings.ali_client_id', v);

  String? get aliClientSecret => _prefs.getString('settings.ali_client_secret');
  Future<void> setAliClientSecret(String v) =>
      _prefs.setString('settings.ali_client_secret', v);

  // ---- OneDrive（C 档网盘适配器）----

  String? get oneClientId => _prefs.getString('settings.one_client_id');
  Future<void> setOneClientId(String v) =>
      _prefs.setString('settings.one_client_id', v);

  String? get oneClientSecret => _prefs.getString('settings.one_client_secret');
  Future<void> setOneClientSecret(String v) =>
      _prefs.setString('settings.one_client_secret', v);

  // ---- Dropbox（C 档网盘适配器）----

  String? get dropboxClientId => _prefs.getString('settings.dropbox_client_id');
  Future<void> setDropboxClientId(String v) =>
      _prefs.setString('settings.dropbox_client_id', v);

  String? get dropboxClientSecret =>
      _prefs.getString('settings.dropbox_client_secret');
  Future<void> setDropboxClientSecret(String v) =>
      _prefs.setString('settings.dropbox_client_secret', v);

  // ---- Google Drive（C 档网盘适配器）----

  String? get gdriveClientId => _prefs.getString('settings.gdrive_client_id');
  Future<void> setGdriveClientId(String v) =>
      _prefs.setString('settings.gdrive_client_id', v);

  String? get gdriveClientSecret =>
      _prefs.getString('settings.gdrive_client_secret');
  Future<void> setGdriveClientSecret(String v) =>
      _prefs.setString('settings.gdrive_client_secret', v);

  /// 最近一次备份时间（本地展示用）。
  DateTime? get lastBackupAt {
    final raw = _prefs.getString('settings.last_backup_at');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> markBackupNow() => _prefs.setString(
      'settings.last_backup_at', DateTime.now().toIso8601String());
}
