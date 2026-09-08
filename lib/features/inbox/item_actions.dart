import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/analytics/analytics_service.dart';
import '../../core/theme.dart';
import '../../data/database/database.dart';
import '../../data/repositories/item_repository.dart';
import '../../providers.dart';
import '../../shared/status_chip.dart';
import '../library/media_library_screen.dart';

/// 条目详情与操作（收件箱 / 记忆库共用）：
/// - 已成卡：查看/编辑卡面、删除
/// - 待归类：一键成卡（离线词库命中自动补释义，低置信标"待确认"）
class ItemActions {
  static void open(BuildContext context, WidgetRef ref, ItemWithCard item) {
    if (item.hasCard) {
      _showCardSheet(context, ref, item);
    } else {
      _showConfirmSheet(context, ref, item);
    }
  }

  // ---- 已成卡：详情 / 编辑 / 删除 ----

  static void _showCardSheet(
      BuildContext context, WidgetRef ref, ItemWithCard item) {
    final card = item.card!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CardDetailSheet(item: item, card: card),
    );
  }

  // ---- 待归类：一键成卡 ----

  static void _showConfirmSheet(
      BuildContext context, WidgetRef ref, ItemWithCard item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ConfirmCardSheet(item: item),
    );
  }
}

class _CardDetailSheet extends ConsumerStatefulWidget {
  const _CardDetailSheet({required this.item, required this.card});

  final ItemWithCard item;
  final CardRow card;

  @override
  ConsumerState<_CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends ConsumerState<_CardDetailSheet> {
  late final TextEditingController _prompt;
  late final TextEditingController _answer;

  @override
  void initState() {
    super.initState();
    _prompt = TextEditingController(text: widget.card.prompt);
    _answer = TextEditingController(text: widget.card.answer);
  }

  @override
  void dispose() {
    _prompt.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(itemRepositoryProvider).updateCardFields(
          widget.item.item.id,
          prompt: _prompt.text.trim(),
          answer: _answer.text.trim(),
        );
    if (mounted) {
      Navigator.of(context).pop();
      ref.invalidate(libraryItemsProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已保存')));
    }
  }

  Future<void> _delete() async {
    await ref.read(itemRepositoryProvider).deleteItem(widget.item.item.id);
    // 删除即同步（墓碑防云端复活），其他端同时收敛
    ref.read(syncServiceProvider).syncNow().ignore();
    if (mounted) {
      Navigator.of(context).pop();
      ref.invalidate(libraryItemsProvider);
      ref.invalidate(reviewOverviewProvider);
      ref.invalidate(quotaProvider);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已删除')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('卡片', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                StatusChip(status: widget.item.item.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '间隔 ${widget.card.intervalDays} 天 · EF ${widget.card.easeFactor.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // 出处（Phase 1：浏览器划词收藏自动带来源页）
            if (widget.item.item.originalUrl != null ||
                widget.item.item.sourceTitle != null) ...[
              const SizedBox(height: 12),
              _SourceRow(item: widget.item.item),
            ],
            // 本地素材（记忆教练：链接素材库，回忆锚点）
            if (widget.item.item.mediaAssetId != null) ...[
              const SizedBox(height: 12),
              SourceMediaView(assetId: widget.item.item.mediaAssetId!),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _prompt,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '正面',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answer,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '背面 / 答案',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
                const Spacer(),
                FilledButton(onPressed: _save, child: const Text('保存')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmCardSheet extends ConsumerStatefulWidget {
  const _ConfirmCardSheet({required this.item});

  final ItemWithCard item;

  @override
  ConsumerState<_ConfirmCardSheet> createState() => _ConfirmCardSheetState();
}

class _ConfirmCardSheetState extends ConsumerState<_ConfirmCardSheet> {
  late final TextEditingController _prompt;
  final _answer = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prompt = TextEditingController(
      text: widget.item.item.note ?? '',
    );
  }

  @override
  void dispose() {
    _prompt.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('内容不能为空')));
      return;
    }
    await ref.read(itemRepositoryProvider).confirmInboxToCard(
          itemId: widget.item.item.id,
          promptOverride: prompt,
          answer: _answer.text.trim().isEmpty ? '（待补充答案）' : _answer.text.trim(),
          kind: widget.item.item.lang == 'ja' || widget.item.item.lang == 'en'
              ? 'word'
              : 'idea',
        );
    ref.read(analyticsProvider).track(
      AnalyticsEvents.itemCardCreated,
      props: {'source': widget.item.item.source},
    );
    if (mounted) {
      Navigator.of(context).pop();
      ref.invalidate(reviewOverviewProvider);
      ref.invalidate(quotaProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已成卡，明天首次复习')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('待归类 → 成卡', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '确认后进入复习队列（明天首复），答案可随时编辑',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _prompt,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: '正面',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answer,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: '背面 / 答案',
                hintText: '可留空，稍后补充',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _confirm,
                icon: const Icon(Icons.task_alt),
                label: const Text('成卡并入复习'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 来源行：标题 + 「打开原文」。
class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.item});

  final ItemRow item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = item.originalUrl;
    final title = item.sourceTitle;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.link, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title ?? url ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (url != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () async {
                final uri = Uri.tryParse(url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                '打开原文',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.systemBlue,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
