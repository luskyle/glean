import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../providers.dart';
import '../../shared/empty_state.dart';
import '../../shared/language_badge.dart';
import 'add_item_sheet.dart';
import 'item_actions.dart';

/// 收藏内容主视图（分类内容）：
/// - 无状态分段：全部条目按当前筛选（搜索 / 语言 / 分组）展示
/// - 列表行 = 收藏条目，点击进详情（查看/编辑/删除/整理）
/// - 空态引导收藏
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(libraryItemsProvider).value ?? const <ItemRow>[];

    return items.isEmpty ? _empty(context, ref) : _list(context, ref, items);
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

  Widget _empty(BuildContext context, WidgetRef ref) {
    return Center(
      child: EmptyState(
        icon: Icons.inbox_outlined,
        title: '还没有收藏',
        subtitle: '点「收藏」按钮，或从浏览器插件划词收藏。',
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