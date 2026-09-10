import 'package:flutter/cupertino.dart' show CupertinoButton;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/database/database.dart';
import '../../providers.dart';
import '../inbox/add_item_sheet.dart';

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
                      'Glean',
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
                        Icons.add_circle,
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
                    icon: Icons.inbox_outlined,
                    label: '收件箱',
                    selected: activeTab == 0,
                    onTap: () => onSelectTab(0),
                  ),
                  _SidebarRow(
                    icon: Icons.photo_library_outlined,
                    label: '素材库',
                    selected: activeTab == 1,
                    onTap: () => onSelectTab(1),
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
              // ---- 新建分类 ----
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: _SidebarRow(
                  icon: Icons.add,
                  label: '新建分类',
                  onTap: () => _createCollection(context, ref),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: collections.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (cols) => _SidebarGroup(
                      children: [
                        for (final c in cols)
                          Dismissible(
                            key: ValueKey('sidebar-col-${c.id}'),
                            direction: DismissDirection.endToStart,
                            // 左划 → 确认删除（内容自动回未分类），手动刷新列表
                            confirmDismiss: (_) async {
                              await _deleteCollection(context, ref, c);
                              return false;
                            },
                            background: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: scheme.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: Icon(
                                Icons.delete_outline,
                                color: scheme.error,
                              ),
                            ),
                            child: _SidebarRow(
                              icon: Icons.folder,
                              label: c.name,
                              selected: activeTab == 0 &&
                                  ref
                                          .watch(libraryFilterProvider)
                                          .collectionId ==
                                      c.id,
                              onTap: () => _openCollection(ref, c),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('新建分类'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: '如：英语、读书、灵感'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      final repo = ref.read(itemRepositoryProvider);
      await repo.createCollection(name);
      ref.invalidate(collectionsProvider);
      // 分类即时同步到云端（浏览器端弹窗下拉实时可见）
      ref.read(syncServiceProvider).syncNow().ignore();
    }
  }

  Future<void> _deleteCollection(
    BuildContext context,
    WidgetRef ref,
    CollectionRow c,
  ) async {
    // 系统分类（工作/学习/未分类）不可删除
    if (c.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${c.name}」是默认分类，不能删除')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('删除分类「${c.name}」？'),
        content: const Text('分类里的内容会移到「未分类」，内容不会被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(itemRepositoryProvider).deleteCollection(c.id);
      ref.invalidate(collectionsProvider);
      // 分类即时同步到云端
      ref.read(syncServiceProvider).syncNow().ignore();
    }
  }

  void _openCollection(WidgetRef ref, CollectionRow c) {
    ref.read(libraryFilterProvider.notifier).state =
        ref.read(libraryFilterProvider).withCollection(c.id);
    onSelectTab(0);
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

/// 导航行：系统图标 + 标签；选中态：蓝色文字 + 圆角高亮。
class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
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
            ],
          ),
        ),
      ),
    );
  }
}
