import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/analytics/analytics_service.dart';
import 'data/database/database.dart';
import 'data/repositories/item_repository.dart';
import 'data/settings/settings_store.dart';
import 'data/sync/cloud_drive.dart';
import 'data/sync/sync_service.dart';
import 'domain/tagging/language.dart';

/// 数据库（测试中可 override 为内存库）。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

/// 埋点服务（本地 JSONL 记录 + 上报占位）。
final analyticsProvider = Provider<AnalyticsService>((ref) {
  final svc = AnalyticsService();
  ref.onDispose(svc.dispose);
  return svc;
});

/// 设置存储（测试中可 override）。
final settingsProvider = Provider<SettingsStore>((ref) {
  throw UnimplementedError('settingsProvider must be overridden in tests or '
      'initialized in main() via settingsStoreProvider');
});

/// 云盘同步服务（通道按设置路由：iCloud Drive 优先；WebDAV 兜底）。
final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final settings = ref.watch(settingsProvider);
  if (settings.syncChannel == 'webdav' &&
      settings.webdavUrl != null &&
      settings.webdavUrl!.trim().isNotEmpty) {
    return SyncService(
      db: db,
      cloud: WebDavAdapter(
        baseUrl: settings.webdavUrl!.trim(),
        username: settings.webdavUser ?? '',
        password: settings.webdavPassword ?? '',
      ),
    );
  }
  return SyncService(db: db, cloud: const ICloudDriveAdapter());
});

/// 由 main() 注入的 SharedPreferences 实例。
final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPrefsProvider must be overridden in main()');
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(databaseProvider));
});

// ---------------------------------------------------------------------------
// 收藏库
// ---------------------------------------------------------------------------

/// 收藏库筛选参数。
class LibraryFilter {
  const LibraryFilter({this.search = '', this.lang, this.collectionId});

  final String search;
  final String? lang;

  /// 按分组过滤，null = 全部。
  final int? collectionId;

  LibraryFilter copyWith({String? search, String? lang, int? collectionId}) {
    return LibraryFilter(
      search: search ?? this.search,
      lang: lang ?? this.lang,
      collectionId: collectionId ?? this.collectionId,
    );
  }

  /// 切换语言筛选（再点一次取消）。
  LibraryFilter toggleLang(String l) {
    return LibraryFilter(
      search: search,
      lang: lang == l ? null : l,
      collectionId: collectionId,
    );
  }

  /// 切到指定分组（null = 全部）。
  LibraryFilter withCollection(int? id) {
    return LibraryFilter(
      search: search,
      lang: lang,
      collectionId: id,
    );
  }

  /// 清空（切回"全部"视图）。
  LibraryFilter reset() => const LibraryFilter();

  @override
  bool operator ==(Object other) =>
      other is LibraryFilter &&
      other.search == search &&
      other.lang == lang &&
      other.collectionId == collectionId;

  @override
  int get hashCode => Object.hash(search, lang, collectionId);
}

final libraryFilterProvider = StateProvider<LibraryFilter>((ref) {
  return const LibraryFilter();
});

/// 收藏库流（行流，携带搜索/语言/分组过滤）。
final libraryItemsProvider = StreamProvider<List<ItemRow>>((ref) {
  final filter = ref.watch(libraryFilterProvider);
  return ref.watch(itemRepositoryProvider).watchLibrary(
        search: filter.search,
        lang: filter.lang,
        collectionId: filter.collectionId,
      );
});

/// 分组列表（含系统分类）。
final collectionsProvider = FutureProvider<List<CollectionRow>>((ref) {
  return ref.watch(itemRepositoryProvider).collections();
});

/// 条目-分组 多对多关系流（收藏详情归属展示用）。
final itemCollectionLinksProvider =
    StreamProvider<List<ItemCollectionRow>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.itemCollections).watch();
});

// ---------------------------------------------------------------------------
// 主题
// ---------------------------------------------------------------------------

/// 主题模式（UI 状态：system / light / dark；随设置持久化）。
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final raw = ref.watch(settingsProvider).themeMode;
  return switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
});

// ---------------------------------------------------------------------------
// 语言标签帮助函数
// ---------------------------------------------------------------------------

String languageLabel(ContentLang lang) {
  return switch (lang) {
    ContentLang.ja => '日语',
    ContentLang.zh => '中文',
    ContentLang.en => '英语',
    ContentLang.other => '其他',
  };
}