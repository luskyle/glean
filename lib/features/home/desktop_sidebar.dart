import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/database/database.dart';
import '../../providers.dart';
import '../inbox/add_item_sheet.dart';
import '../settings/settings_screen.dart';

/// iOS 风格侧边栏（HIG Sidebar）：大标题 + 分组导航 + 底部设置。
///
/// 宽屏（桌面）专用；窄屏走底部 Tab，不渲染本组件。
class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({
    super.key,
    required this.activeTab,
    required this.onSelectTab,
  });

  final int activeTab;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final collections = ref.watch(collectionsProvider);
    final overview = ref.watch(reviewOverviewProvider);
    final inboxCount = ref.watch(inboxItemsProvider).maybeWhen(
          data: (list) => list.length,
          orElse: () => 0,
        );
    final due = overview.maybeWhen(data: (o) => o.due, orElse: () => 0);

    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: SizedBox(
          width: 292,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // iOS Large Title + 新建按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 6),
                child: Row(
                  children: [
                    Text(
                      '拾忆',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(34, 34),
                      onPressed: () => _openAddSheet(context),
                      child: Icon(
                        CupertinoIcons.add_circled,
                        size: 26,
                        color: AppTheme.systemBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // ---- 收藏箱（第一分组）----
              _SidebarGroup(
                children: [
                  _SidebarRow(
                    icon: CupertinoIcons.book_fill,
                    label: '今日复习',
                    badge: due,
                    selected: activeTab == 1,
                    onTap: () => onSelectTab(1),
                  ),
                  _SidebarRow(
                    icon: CupertinoIcons.tray_fill,
                    label: '收件箱',
                    badge: inboxCount,
                    selected: activeTab == 0,
                    onTap: () => onSelectTab(0),
                  ),
                  _SidebarRow(
                    icon: CupertinoIcons.square_grid_2x2_fill,
                    label: '记忆库',
                    selected: activeTab == 2 && _isAllView(ref),
                    onTap: () => _openLibraryAll(ref),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ---- 分组（第二分组）----
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 16, 6),
                child:
                    Text('分组', style: Theme.of(context).textTheme.labelSmall),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: collections.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (cols) => _SidebarGroup(
                      children: [
                        for (final c in cols)
                          _SidebarRow(
                            icon: CupertinoIcons.folder_fill,
                            label: c.name,
                            selected: activeTab == 2 &&
                                ref.watch(libraryFilterProvider).collectionId ==
                                    c.id,
                            onTap: () => _openCollection(ref, c),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ---- 底部（设置）----
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: _SidebarRow(
                  icon: CupertinoIcons.settings,
                  label: '设置',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isAllView(WidgetRef ref) =>
      ref.read(libraryFilterProvider).collectionId == null;

  void _openLibraryAll(WidgetRef ref) {
    ref.read(libraryFilterProvider.notifier).state =
        ref.read(libraryFilterProvider).withCollection(null);
    onSelectTab(2);
  }

  void _openCollection(WidgetRef ref, CollectionRow c) {
    ref.read(libraryFilterProvider.notifier).state =
        ref.read(libraryFilterProvider).withCollection(c.id);
    onSelectTab(2);
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddItemSheet(),
    );
  }
}

/// 分组容器（iOS inset grouped：圆角分组卡片）。
class _SidebarGroup extends StatelessWidget {
  const _SidebarGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 0.5,
                indent: 50,
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 导航行：系统图标 + 标签 + 徽标；选中态：蓝色文字 + 圆角高亮。
class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? AppTheme.systemBlue : scheme.onSurface;
    return Material(
      color: selected
          ? AppTheme.systemBlue.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  ),
                ),
              ),
              if (badge > 0)
                Text(
                  '$badge',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
