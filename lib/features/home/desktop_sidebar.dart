import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../providers.dart';
import '../inbox/add_item_sheet.dart';
import '../settings/settings_screen.dart';

/// Cubox 式左侧栏：收藏箱导航（复习/收件箱/记忆库/分组）+ 新建收藏 + 设置。
///
/// 宽屏（桌面）专用；窄屏走底部三 Tab，不渲染本组件。
class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({
    super.key,
    required this.activeTab,
    required this.onSelectTab,
  });

  final int activeTab;
  final ValueChanged<int> onSelectTab;

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddItemSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final collections = ref.watch(collectionsProvider);
    final overview = ref.watch(reviewOverviewProvider);
    final inboxCount = ref.watch(inboxItemsProvider).maybeWhen(
          data: (list) => list.length,
          orElse: () => 0,
        );

    final due = overview.maybeWhen(
      data: (o) => o.due,
      orElse: () => 0,
    );

    return Material(
      color: scheme.surfaceContainerLowest,
      child: SafeArea(
        child: SizedBox(
          width: 240,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_stories,
                        size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '拾忆',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: FilledButton.icon(
                onPressed: () => _openAddSheet(context),
                icon: const Icon(Icons.add),
                label: const Text('新建收藏'),
              ),
            ),
            const SizedBox(height: 8),
            // ---- 收藏箱 ----
            _NavItem(
              icon: Icons.school_outlined,
              selectedIcon: Icons.school,
              label: '今日复习',
              badge: due,
              selected: activeTab == 1,
              onTap: () => onSelectTab(1),
            ),
            _NavItem(
              icon: Icons.inbox_outlined,
              selectedIcon: Icons.inbox,
              label: '收件箱',
              badge: inboxCount,
              selected: activeTab == 0,
              onTap: () => onSelectTab(0),
            ),
            _NavItem(
              icon: Icons.collections_bookmark_outlined,
              selectedIcon: Icons.collections_bookmark,
              label: '记忆库',
              selected: activeTab == 2 && _isAllView(ref),
              onTap: () => _openLibraryAll(ref),
            ),
            const SizedBox(height: 8),
            // ---- 分组 ----
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                '分组',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: collections.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (cols) => Column(
                    children: [
                      for (final c in cols)
                        _NavItem(
                          icon: Icons.folder_outlined,
                          selectedIcon: Icons.folder,
                          label: c.name,
                          selected:
                              activeTab == 2 &&
                              ref.watch(libraryFilterProvider).collectionId ==
                                  c.id,
                          onTap: () => _openCollection(ref, c),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Divider(height: 1),
            ListTile(
              dense: true,
              leading: Icon(Icons.settings_outlined,
                  size: 20, color: scheme.onSurfaceVariant),
              title: Text(
                '设置',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onTap: () =>
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  )),
            ),
          ],
        ),
        ),
      ),
    );
  }

  bool _isAllView(WidgetRef ref) {
    final f = ref.read(libraryFilterProvider);
    return f.collectionId == null;
  }

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
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(selected ? selectedIcon : icon,
                    size: 20,
                    color: selected ? scheme.onSecondaryContainer : scheme.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                ),
                if (badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}