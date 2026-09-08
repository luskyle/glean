import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics/analytics_service.dart';
import '../../data/settings/settings_store.dart';
import '../../domain/tagging/language.dart';
import '../../providers.dart';
import '../settings/paywall_sheet.dart';

/// 手录收藏（右上角"+"）：词条 / 语录 / 灵感。
/// 保存即成卡：进入记忆库 + SRS 首次排期（明天首复），零等待。
class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({super.key});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final _promptCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  String _kind = 'word';
  final Set<String> _tags = {};
  int? _collectionId;

  @override
  void dispose() {
    _promptCtrl.dispose();
    _answerCtrl.dispose();
    _noteCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _dictionaryFill() async {
    final dict = ref.read(dictionaryServiceProvider);
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) return;

    final hits = dict.lookup(prompt);
    if (hits.isNotEmpty) {
      setState(() {
        _answerCtrl.text = dict.buildWordAnswer(hits.first);
      });
      return;
    }
    final reading = dict.readingAnnotation(prompt);
    if (reading != null && _answerCtrl.text.isEmpty) {
      setState(() => _answerCtrl.text = '[$reading]');
    }
  }

  Future<void> _save() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('正面内容不能为空')));
      return;
    }
    final answer =
        _answerCtrl.text.trim().isEmpty ? '（待补充答案）' : _answerCtrl.text.trim();

    final quota = await ref.read(quotaProvider.future);
    if (quota.libraryFull) {
      if (mounted) {
        PaywallSheet.show(
            context: context, reason: '记忆库已满 ${Quota.maxLibraryCards} 张');
      }
      return;
    }

    final lang = langCodeOf(detectLang(prompt));
    final repo = ref.read(itemRepositoryProvider);
    await repo.createManualCard(
      prompt: prompt,
      answer: answer,
      kind: _kind,
      lang: lang,
      tags: _tags.toList(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      collectionId: _collectionId,
    );
    ref.read(analyticsProvider).track(
      AnalyticsEvents.itemCollected,
      props: {'source': 'manual', 'kind': _kind},
    );

    if (mounted) {
      Navigator.of(context).pop();
      ref.invalidate(inboxItemsProvider);
      ref.invalidate(libraryItemsProvider);
      ref.invalidate(quotaProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已收藏，明天开始第一次复习')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final collections = ref.watch(collectionsProvider);

    return Padding(
      // 键盘弹出时顶起表单
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('收藏', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '保存后自动进入复习队列，明天首次复习',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                    value: 'word',
                    label: Text('词条'),
                    icon: Icon(Icons.translate)),
                ButtonSegment(
                    value: 'quote',
                    label: Text('语录'),
                    icon: Icon(Icons.format_quote)),
                ButtonSegment(
                    value: 'idea',
                    label: Text('灵感'),
                    icon: Icon(Icons.lightbulb_outline)),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: _kind == 'word' ? '词条 / 单词' : '内容',
                hintText: _kind == 'word' ? '如：食べる（查词库自动补释义）' : '支持 Markdown',
                border: const OutlineInputBorder(),
                suffixIcon: _kind == 'word'
                    ? IconButton(
                        tooltip: '查词库填充',
                        icon: const Icon(Icons.manage_search),
                        onPressed: _dictionaryFill,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _answerCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '背面 / 答案',
                hintText: '释义、例句或要点',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: '备注（为什么收）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                      labelText: '标签',
                      hintText: '回车添加',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (t) {
                      final tag = t.trim();
                      if (tag.isNotEmpty) {
                        setState(() => _tags.add(tag));
                        _tagCtrl.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: collections.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (cols) => DropdownButtonFormField<int?>(
                      initialValue: _collectionId,
                      decoration: const InputDecoration(
                        labelText: '分组',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('未分类'),
                        ),
                        ...cols.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _collectionId = v),
                    ),
                  ),
                ),
              ],
            ),
            if (_tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
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
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('收藏并安排复习'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
