import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics/analytics_service.dart';
import '../../data/sync/local_notify_server.dart';
import '../../providers.dart';
import '../inbox/add_item_sheet.dart';
import '../inbox/inbox_screen.dart';
import '../settings/settings_screen.dart';
import 'desktop_sidebar.dart';

/// 外壳：Glean 收藏视图。
///
/// - 宽屏（>= 900，桌面）：左侧分类侧栏 + 顶栏搜索 + 内容区
/// - 窄屏（移动）：AppBar（分类 / 设置）+ 收藏入口 FAB
/// - 启动静默同步：本地通知服务 + 前台周期同步（WebDAV / iCloud）
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  static const _wideBreakpoint = 900.0;

  /// 顶栏全局搜索框控制器（宽屏）。
  final _searchCtrl = TextEditingController();

  Timer? _syncTimer;
  final LocalNotifyServer _notifyServer = LocalNotifyServer();
  StreamSubscription<void>? _notifySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(analyticsProvider).track(AnalyticsEvents.appOpen);
    // 本地通知服务：浏览器插件等本机写入方收藏后实时触发同步
    _notifyServer.start();
    _notifySub = _notifyServer.onNotify.listen((_) => _quietSync());
    // 多端云盘同步：启动时拉取远端并合并（静默，失败不影响使用）
    _quietSync();
    // 前台周期自动同步（浏览器插件等其他端写入后可自动出现）
    _syncTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _quietSync();
      }
    });
  }

  /// 静默安全同步（拉取合并 → 推送），失败仅打日志。
  void _quietSync() {
    ref.read(syncServiceProvider).syncNow().then((err) {
      if (err != null) debugPrint('自动同步跳过：$err');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _notifySub?.cancel();
    _notifyServer.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final analytics = ref.read(analyticsProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        analytics.track(AnalyticsEvents.appResume);
        _quietSync(); // 回到前台立即拉取其他端的新收藏
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        analytics.track(AnalyticsEvents.appBackground);
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wideBreakpoint) {
          return _buildWide(context);
        }
        return _buildNarrow(context);
      },
    );
  }

  // ---- 宽屏（桌面）----

  Widget _buildWide(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          const DesktopSidebar(),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, scheme),
                const Divider(height: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1280),
                      child: const InboxScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ColorScheme scheme) {
    return Container(
      color: scheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: '搜索收藏…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(libraryFilterProvider.notifier).state = ref
                              .read(libraryFilterProvider)
                              .copyWith(search: '');
                        },
                      ),
                isDense: true,
                filled: true,
                fillColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) {
                ref.read(libraryFilterProvider.notifier).state =
                    ref.read(libraryFilterProvider).copyWith(search: v);
              },
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ---- 窄屏（移动）----

  Widget _buildNarrow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Glean'),
        actions: [
          // 分类入口：选择分组查看内容
          IconButton(
            tooltip: '分类',
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => _openCollectionPicker(),
          ),
          // 设置常驻顶栏（窄屏无侧栏）
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(),
          ),
        ],
      ),
      body: const InboxScreen(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('收藏'),
      ),
    );
  }

  /// 窄屏分类入口：弹分组选择，点选后进入该分组内容。
  Future<void> _openCollectionPicker() async {
    final cols = await ref.read(itemRepositoryProvider).collections();
    if (!mounted) return;
    final res = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child:
                  Text('选择分组', style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final c in cols)
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(c.name),
                onTap: () => Navigator.pop(context, '${c.id}'),
              ),
          ],
        ),
      ),
    );
    if (res != null) {
      final id = int.tryParse(res);
      ref.read(libraryFilterProvider.notifier).state =
          ref.read(libraryFilterProvider).withCollection(id);
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddItemSheet(),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
}