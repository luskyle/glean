import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/item_repository.dart';
import '../../providers.dart';
import '../../shared/empty_state.dart';
import '../../shared/status_chip.dart';
import 'item_actions.dart';

/// 收件箱：待归类 + 待学习条目，收藏时间倒序。
///
/// [active]：非活动 Tab 时 build 短路，停止构建与流监听（减少后台开销）。
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key, this.active = true});

  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!active) return const SizedBox.shrink();
    final items = ref.watch(inboxItemsProvider);

    return items.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('加载失败：$e')),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.inbox_outlined,
            title: '收件箱还空着',
            subtitle: '从任何 App 复制内容，或点右下角"收藏"收录第一件。\n收到的东西会自动安排复习，直到你真正记住。',
          );
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(inboxItemsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, i) => InboxItemTile(item: list[i]),
          ),
        );
      },
    );
  }
}

class InboxItemTile extends ConsumerWidget {
  const InboxItemTile({super.key, required this.item});

  final ItemWithCard item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final card = item.card;
    final title = card?.prompt ?? item.item.note ?? '（无内容）';
    final subtitle = _sourceLabel(item.item.source);

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: LanguageBadge(lang: item.item.lang),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: StatusChip(status: item.item.status),
        onTap: () => ItemActions.open(context, ref, item),
      ),
    );
  }

  String _sourceLabel(String source) {
    return switch (source) {
      'clipboard' => '来自剪贴板',
      'share' => '来自分享',
      'photo' => '来自拍照',
      'anki_import' => '来自 Anki',
      _ => '手动收藏',
    };
  }
}