import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../data/database/database.dart';
import '../../providers.dart';

/// 收藏条目详情与操作（收件箱 / 收藏库共用）：
/// 查看 / 编辑内容、语言、状态、分组、标签；删除。
class ItemActions {
  static void open(BuildContext context, WidgetRef ref, ItemRow item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ItemDetailSheet(item: item),
    );
  }
}

class ItemDetailSheet extends ConsumerStatefulWidget {
  const ItemDetailSheet({super.key, required this.item});

  final ItemRow item;

  @override
  ConsumerState<ItemDetailSheet> createState() => _ItemDetailSheetState();
}

class _ItemDetailSheetState extends ConsumerState<ItemDetailSheet> {
  late final TextEditingController _note;
  final _tagCtrl = TextEditingController();

  String? _lang; // null = 自动（保持原样越界时按条目原值）
  final Set<String> _tags = {};
  bool _saving = false;

  static const _knownLangs = {'zh', 'ja', 'en', 'other'};

  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.item.note ?? '');
    final raw = widget.item.lang;
    _lang = (_knownLangs.contains(raw) && raw != null) ? raw : null;
    _loadTags();
  }

  Future<void> _loadTags() async {
    final tags =
        await ref.read(itemRepositoryProvider).tagsOfItem(widget.item.id);
    if (mounted) setState(() => _tags.addAll(tags));
  }

  @override
  void dispose() {
    _note.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _note.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('内容不能为空')));
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(itemRepositoryProvider);
    await repo.updateItem(
      widget.item.id,
      note: content,
      lang: _lang,
    );
    await repo.setItemTags(widget.item.id, _tags.toList());
    ref.invalidate(libraryItemsProvider);
    // 编辑即同步（其他端同时收敛）
    ref.read(syncServiceProvider).syncNow().ignore();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已保存')));
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除这条收藏？'),
        content: const Text('删除后可通过云盘备份恢复（若有）。'),
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
    if (ok != true) return;
    await ref.read(itemRepositoryProvider).deleteItem(widget.item.id);
    // 删除即同步（墓碑防云端复活），其他端同时收敛
    ref.read(syncServiceProvider).syncNow().ignore();
    ref.invalidate(libraryItemsProvider);
    ref.invalidate(collectionsProvider);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已删除')));
    }
  }

  void _chooseCollection(int? collectionId) {
    setState(() {});
    ref
        .read(itemRepositoryProvider)
        .setPrimaryCollection(widget.item.id, collectionId);
    ref.invalidate(libraryItemsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final scheme = Theme.of(context).colorScheme;
    final item = widget.item;

    // 分组：当前主分类（来自关系流）
    final links = ref.watch(itemCollectionLinksProvider).value ?? const [];
    final primaryId = links
        .where((l) => l.itemId == item.id && l.isPrimary)
        .map((l) => l.collectionId)
        .firstOrNull;
    final collections = ref.watch(collectionsProvider).value ?? const [];

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
                Text('收藏详情', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '收藏于 ${_dateLabel(item.createdAt)} · 来源 ${_sourceLabel(item.source)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            // 出处（Phase 1：浏览器划词收藏自动带来源页）
            if (item.originalUrl != null || item.sourceTitle != null) ...[
              const SizedBox(height: 12),
              _SourceRow(item: item),
            ],
            // 封面（视频/音频/网页收藏的 og:image 引用）
            if (item.coverUrl != null && item.coverUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.coverUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
            // 浏览器选区 HTML 快照（只读渲染，flutter_html 不执行脚本）
            if (item.htmlClip != null && item.htmlClip!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _HtmlClipView(html: item.htmlClip!),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // 语言
            DropdownButtonFormField<String?>(
              initialValue: _lang,
              decoration: const InputDecoration(labelText: '语言'),
              items: const [
                DropdownMenuItem(value: null, child: Text('自动')),
                DropdownMenuItem(value: 'zh', child: Text('中文')),
                DropdownMenuItem(value: 'ja', child: Text('日语')),
                DropdownMenuItem(value: 'en', child: Text('英语')),
                DropdownMenuItem(value: 'other', child: Text('其他')),
              ],
              onChanged: (v) => setState(() => _lang = v),
            ),
            const SizedBox(height: 12),
            // 分组（主分类）
            DropdownButtonFormField<int?>(
              initialValue: primaryId,
              decoration: const InputDecoration(labelText: '分组'),
              items: [
                const DropdownMenuItem(value: null, child: Text('未分类')),
                for (final c in collections)
                  DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: _chooseCollection,
            ),
            const SizedBox(height: 12),
            // 标签
            TextField(
              controller: _tagCtrl,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '回车添加',
              ),
              onSubmitted: (t) {
                final tag = t.trim();
                if (tag.isNotEmpty) {
                  setState(() => _tags.add(tag));
                  _tagCtrl.clear();
                }
              },
            ),
            if (_tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 6,
                  children: _tags
                      .map((t) => InputChip(
                            label: Text('#$t'),
                            onDeleted: () => setState(() => _tags.remove(t)),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _saving ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: scheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _dateLabel(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  String _sourceLabel(String? source) {
    return switch (source) {
      'clipboard' => '剪贴板',
      'browser' => '浏览器',
      'share' => '分享',
      'photo' => '照片',
      'image' => '图片',
      'video' => '视频',
      'audio' => '音频',
      'file' => '文件',
      'manual' => '手动',
      'word' => '词条',
      'quote' => '语录',
      'idea' => '灵感',
      _ => source ?? '未知',
    };
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

/// 选区 HTML 快照（只读渲染；flutter_html 不执行脚本，避免 XSS）。
class _HtmlClipView extends StatelessWidget {
  const _HtmlClipView({required this.html});

  final String html;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('选区快照', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          HtmlWidget(
            html,
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}