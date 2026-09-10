import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../providers.dart';
import '../../shared/empty_state.dart';
import '../../shared/status_chip.dart';
import 'add_item_sheet.dart';
import 'item_actions.dart';

/// 收件箱（收藏主视图）：
/// - 顶部状态分段：待归类 / 已收藏 / 已归档 / 全部
/// - 列表行 = 收藏条目（无卡片概念），点击进详情（查看/编辑/删除/整理）
/// - 空态引导收藏
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  static const _segments = [
    (value: 'inbox', label: '待归类'),
    (value: 'active', label: '已收藏'),
    (value: 'archived', label: '已归档'),
    (value: '', label: '全部'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(libraryFilterProvider);
    final items = ref.watch(libraryItemsProvider).value ?? const <ItemRow>[];

    final current = filter.status;
    final hasCustomStatus = current != null &&
        current != 'inbox' &&
        current != 'active' &&
        current != 'archived';
    final selected = hasCustomStatus ? 'inbox' : (current ?? 'inbox');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: SegmentedButton<String>(
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            segments: [
              for (final s in _segments)
                ButtonSegment(value: s.value, label: Text(s.label)),
            ],
            selected: {selected},
            onSelectionChanged: (s) {
              final v = s.first;
              ref.read(libraryFilterProvider.notifier).state =
                  filter.copyWith(status: v.isEmpty ? null : v);
            },
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: items.isEmpty ? _empty(context, ref, selected) : _list(context, ref, items),
        ),
      ],
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<ItemRow> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 12),
      itemBuilder: (context, i) {
        final item = items[i];
        return ListTile(
          leading: LanguageBadge(lang: item.lang),
          title: Text(
            item.note ?? '（无内容）',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15),
          ),
          subtitle: _subtitle(item),
          trailing: StatusChip(status: item.status),
          onTap: () => ItemActions.open(context, ref, item),
        );
      },
    );
  }

  Widget? _subtitle(ItemRow item) {
    final parts = [
      if (item.sourceTitle != null && item.sourceTitle!.isNotEmpty)
        item.sourceTitle!,
      if (item.originalUrl != null && item.originalUrl!.isNotEmpty)
        item.originalUrl!,
      _sourceLabel(item.source),
    ].where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' · '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _empty(BuildContext context, WidgetRef ref, String segment) {
    final (icon, title, subtitle) = switch (segment) {
      'active' => (
          Icons.star_outline,
          '还没有已收藏的内容',
          '把待归类的内容整理为「已收藏」后会出现在这里。',
        ),
      'archived' => (
          Icons.archive_outlined,
          '没有归档内容',
          '归档的收藏会在这里，方便随时翻找。',
        ),
      '' => (
          Icons.inbox_outlined,
          '还没有任何收藏',
          '点「收藏」按钮，或复制一段内容试试。',
        ),
      _ => (
          Icons.inbox_outlined,
          '收件箱是空的',
          '复制一段内容，或点「收藏」手动保存。',
        ),
    };
    return Center(
      child: EmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
        action: FilledButton.icon(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddItemSheet(),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('收藏'),
        ),
      ),
    );
  }

  String _sourceLabel(String? source) {
    return switch (source) {
      'clipboard' => '剪贴板',
      'browser' => '浏览器',
      'share' => '分享',
      'photo' => '照片',
      'manual' => '手动',
      'word' => '词条',
      'quote' => '语录',
      'idea' => '灵感',
      _ => '收藏',
    };
  }
}