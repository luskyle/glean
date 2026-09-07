import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers.dart';
import '../inbox/add_item_sheet.dart';
import '../inbox/inbox_screen.dart';
import '../library/library_screen.dart';
import '../review/curve_screen.dart';
import '../review/review_screen.dart';
import '../settings/settings_screen.dart';

/// 当前 Tab（默认落点 = 复习页，见设计原则 2）。
final homeTabIndexProvider = StateProvider<int>((ref) => 1);

/// 三 Tab 外壳：收件箱 / 复习（默认）/ 记忆库。
///
/// - IndexedStack 保状态（切 Tab 不重建）
/// - 全局共享元素：右上角"+"（收件箱）、搜索（跳记忆库）、底部三 Tab
/// - 剪贴板监听（前台轮询，可设置关闭）→ 轻提示"有内容要收藏？"
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const _titles = ['收件箱', '今日复习', '记忆库'];

  ClipboardWatcher? _watcher;

  @override
  void initState() {
    super.initState();
    // 剪贴板监听：创建 watcher 并启动（设置里可关闭）
    _watcher = ClipboardWatcher(
      readClipboard: _readClipboard,
      onCapture: _onClipboardCapture,
    );
    if (ref.read(settingsProvider).clipboardWatchEnabled) {
      _watcher!.start();
    }
  }

  @override
  void dispose() {
    _watcher?.dispose();
    _watcher = null;
    super.dispose();
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('复制了一段内容，要收藏吗？'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: '收藏',
          onPressed: () async {
            final repo = ref.read(itemRepositoryProvider);
            await repo.createInboxItem(text: text, source: 'clipboard');
            ref.invalidate(inboxItemsProvider);
            messenger.showSnackBar(
              const SnackBar(content: Text('已收进收件箱，稍后整理成卡')),
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
    final isInbox = tabIndex == 0;

    // 设置里切换剪贴板监听 → 即时启停轮询
    ref.listen(clipboardWatchEnabledProvider, (prev, next) {
      if (next) {
        _watcher?.start();
      } else {
        _watcher?.stop();
      }
    });

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
        children: const [
          InboxScreen(),
          ReviewScreen(),
          LibraryScreen(),
        ],
      ),
      floatingActionButton: isInbox
          ? FloatingActionButton.extended(
              onPressed: () => _openAddSheet(),
              icon: const Icon(Icons.add),
              label: const Text('收藏'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) =>
            ref.read(homeTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox),
            label: '收件箱',
          ),
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