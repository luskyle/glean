import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics/analytics_service.dart';
import '../../data/sync/local_notify_server.dart';
import '../../domain/tagging/language.dart';
import '../../providers.dart';
import '../inbox/add_item_sheet.dart';
import '../inbox/inbox_screen.dart';
import '../library/media_library_screen.dart';
import '../settings/settings_screen.dart';
import 'desktop_sidebar.dart';

/// 当前 Tab（默认落点 = 收件箱）。
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// 外壳：Glean 三区布局（收件箱 / 素材库 / 设置）。
///
/// - 宽屏（>= 900，桌面）：左侧收藏箱侧栏 + 顶栏搜索 + 内容区（IndexedStack 保状态）
/// - 窄屏（移动）：底部两 Tab + 右上角"+"，与原设计一致
/// - 剪贴板监听（前台轮询，可设置关闭）→ 轻提示"有内容要收藏？"
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  static const _titles = ['收件箱', '素材库'];
  static const _wideBreakpoint = 900.0;

  /// 顶栏全局搜索框控制器（宽屏）。
  final _searchCtrl = TextEditingController();

  ClipboardWatcher? _watcher;
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
    // 剪贴板监听：创建 watcher 并启动（设置里可关闭）
    _watcher = ClipboardWatcher(
      readClipboard: _readClipboard,
      onCapture: _onClipboardCapture,
    );
    if (ref.read(settingsProvider).clipboardWatchEnabled) {
      _watcher!.start();
    }
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
    _watcher?.dispose();
    _watcher = null;
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

  void _trackTab(int index) {
    ref.read(analyticsProvider).track(
      AnalyticsEvents.appTabViewed,
      props: {'tab': index},
    );
  }

  Future<String?> _readClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } catch (_) {
      return null; // 平台不支持/未授权：静默降级
    }
  }

  Future<void> _onClipboardCapture(String text) async {
    if (!mounted) return;
    ref.read(analyticsProvider).track(AnalyticsEvents.clipboardPromptShown);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    // 轻量提示：缩短时长 + 宽屏居中窄条，避免全宽横幅干扰
    final screenW = MediaQuery.of(context).size.width;
    const maxBubble = 420.0;
    final horizontalMargin =
        screenW > maxBubble ? (screenW - maxBubble) / 2 : 16.0;
    messenger.showSnackBar(
      SnackBar(
        content: const Text('复制了一段内容，要收藏吗？'),
        duration: const Duration(seconds: 5),
        margin: EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 28),
        action: SnackBarAction(
          label: '收藏',
          onPressed: () async {
            final repo = ref.read(itemRepositoryProvider);
            await repo.createItem(
              note: text.trim(),
              source: 'clipboard',
              lang: langCodeOf(detectLang(text)),
            );
            ref.read(analyticsProvider).track(
              AnalyticsEvents.itemCollected,
              props: {'source': 'clipboard'},
            );
            ref.invalidate(libraryItemsProvider);
            messenger.showSnackBar(
              const SnackBar(content: Text('已收藏到收件箱')),
            );
          },
        ),
        onVisible: () {},
      ),
    );
    // 忽略：轮询前先标记，避免再次提示
    _watcher?.markHandled(text);
  }

  @override
  Widget build(BuildContext context) {
    final tabIndex = ref.watch(homeTabIndexProvider);

    // 设置里切换剪贴板监听 → 即时启停轮询
    ref.listen(clipboardWatchEnabledProvider, (prev, next) {
      if (next) {
        _watcher?.start();
      } else {
        _watcher?.stop();
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wideBreakpoint) {
          return _buildWide(context, tabIndex);
        }
        return _buildNarrow(context, tabIndex);
      },
    );
  }

  // ---- 宽屏（Cubox 式）----

  Widget _buildWide(BuildContext context, int tabIndex) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: tabIndex < 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && tabIndex > 0) {
          ref.read(homeTabIndexProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
        body: Row(
          children: [
            DesktopSidebar(
              activeTab: tabIndex,
              onSelectTab: (i) {
                _trackTab(i);
                ref.read(homeTabIndexProvider.notifier).state = i;
              },
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(context, scheme, tabIndex),
                  const Divider(height: 1),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: IndexedStack(
                          index: tabIndex,
                          children: const [
                            InboxScreen(),
                            MediaLibraryScreen(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, ColorScheme scheme, int tabIndex) {
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
                // 输入即切回收件箱并搜索
                if (tabIndex != 0) {
                  ref.read(homeTabIndexProvider.notifier).state = 0;
                }
                ref.read(libraryFilterProvider.notifier).state =
                    ref.read(libraryFilterProvider).copyWith(search: v);
              },
            ),
          ),
          const Spacer(),
          // 收藏入口统一在侧栏右上角 ⊕；此处不放（避免重复）
          // 设置常驻顶栏：任何页面都可直接进入
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(),
          ),
        ],
      ),
    );
  }

  // ---- 窄屏（移动 Tab）----

  Widget _buildNarrow(BuildContext context, int tabIndex) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[tabIndex]),
        actions: [
          // 分类入口：任何页面都可直接选分组查看内容
          IconButton(
            tooltip: '分类',
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => _openCollectionPicker(),
          ),
          // 设置常驻顶栏：任何页面都可直接进入
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _openSettings(),
          ),
        ],
      ),
      body: IndexedStack(
        index: tabIndex,
        children: const [
          InboxScreen(),
          MediaLibraryScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('收藏'),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) {
          _trackTab(i);
          ref.read(homeTabIndexProvider.notifier).state = i;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: '收件箱',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: '素材库',
          ),
        ],
      ),
    );
  }

  /// 窄屏分类入口：弹分组选择，点选后进入该分组内容（tab 0）。
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
      ref.read(homeTabIndexProvider.notifier).state = 0;
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