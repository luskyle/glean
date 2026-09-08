import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics/analytics_service.dart';
import '../../data/sync/local_notify_server.dart';
import '../../domain/tagging/language.dart';
import '../../providers.dart';
import '../inbox/add_item_sheet.dart';
import '../library/library_screen.dart';
import '../review/curve_screen.dart';
import '../review/review_screen.dart';
import '../settings/settings_screen.dart';
import '../study/study_screen.dart';
import 'desktop_sidebar.dart';

/// 当前 Tab（默认落点 = 复习页，见设计原则 2）。
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// 外壳：Cubox 式响应式布局。
///
/// - 宽屏（>= 900，桌面）：左侧收藏箱侧栏 + 顶栏搜索 + 内容区（IndexedStack 保状态）
/// - 窄屏（移动）：底部三 Tab + 右上角"+"，与原设计一致
/// - 剪贴板监听（前台轮询，可设置关闭）→ 轻提示"有内容要收藏？"
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  static const _titles = ['今日复习', '记忆库', '学习'];
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
    // 词库引导：载入 JLPT 词库资产（内存索引 + words 表），失败静默
    ref.read(dictionaryBootstrapProvider.future).catchError((_) {});
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
            // 直接成卡（不再经过收件箱）：明天首复，来源记为剪贴板
            await repo.createManualCard(
              prompt: text.trim(),
              answer: '（待补充答案）',
              kind: text.trim().length > 20 ? 'idea' : 'word',
              lang: langCodeOf(detectLang(text)),
              source: 'clipboard',
            );
            ref.read(analyticsProvider).track(
              AnalyticsEvents.itemCollected,
              props: {'source': 'clipboard'},
            );
            ref.invalidate(libraryItemsProvider);
            ref.invalidate(reviewOverviewProvider);
            ref.invalidate(quotaProvider);
            messenger.showSnackBar(
              const SnackBar(content: Text('已收藏，明天开始复习')),
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
    return Scaffold(
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
                        children: [
                          ReviewScreen(active: tabIndex == 0),
                          LibraryScreen(active: tabIndex == 1),
                          StudyScreen(active: tabIndex == 2),
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
                hintText: '搜索记忆库…',
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
                // 输入即切到记忆库并搜索
                if (tabIndex != 2) {
                  ref.read(homeTabIndexProvider.notifier).state = 2;
                }
                ref.read(libraryFilterProvider.notifier).state =
                    ref.read(libraryFilterProvider).copyWith(search: v);
              },
            ),
          ),
          const Spacer(),
          if (tabIndex == 1)
            IconButton(
              tooltip: '遗忘曲线',
              icon: const Icon(Icons.show_chart),
              onPressed: () => _openCurve(),
            ),
          // 收藏入口统一在侧栏右上角 ⊕；此处不放（避免重复）
          // 设置唯一入口：记忆库页顶栏
          if (tabIndex == 2)
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
          if (tabIndex == 1)
            IconButton(
              tooltip: '遗忘曲线',
              icon: const Icon(Icons.show_chart),
              onPressed: () => _openCurve(),
            ),
          if (tabIndex == 2)
            IconButton(
              tooltip: '设置',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _openSettings(),
            ),
          if (tabIndex == 0)
            IconButton(
              tooltip: '搜索（记忆库）',
              icon: const Icon(Icons.search),
              onPressed: () =>
                  ref.read(homeTabIndexProvider.notifier).state = 2,
            ),
        ],
      ),
      body: IndexedStack(
        index: tabIndex,
        children: [
          ReviewScreen(active: tabIndex == 0),
          LibraryScreen(active: tabIndex == 1),
          StudyScreen(active: tabIndex == 2),
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
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: '复习',
          ),
          NavigationDestination(
            icon: Icon(Icons.collections_bookmark_outlined),
            selectedIcon: Icon(Icons.collections_bookmark),
            label: '记忆库',
          ),
          NavigationDestination(
            icon: Icon(Icons.translate),
            selectedIcon: Icon(Icons.translate),
            label: '学习',
          ),
        ],
      ),
    );
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddItemSheet(),
    );
  }

  void _openCurve() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CurveScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }
}
