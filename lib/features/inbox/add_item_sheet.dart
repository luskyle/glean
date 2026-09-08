import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics/analytics_service.dart';
import '../../data/settings/settings_store.dart';
import '../../domain/tagging/language.dart';
import '../../providers.dart';
import '../settings/paywall_sheet.dart';

/// 手录收藏：**一个输入框收藏，其余全自动**（零摩擦）。
///
/// - 输入内容 → 自动识别语言、查词库补释义/读音、默认未分类
/// - 「更多选项」折叠：类型 / 答案 / 备注 / 标签 / 分组（可后补）
/// - 保存即成卡：进入记忆库 + SRS 首次排期（明天首复）
class AddItemSheet extends ConsumerStatefulWidget {
  const AddItemSheet({super.key});

  @override
  ConsumerState<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends ConsumerState<AddItemSheet> {
  final _contentCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  String _customAnswer = ''; // 词库自动补的释义（可人工改）
  bool _moreOpen = false;
  String _kind = 'auto';
  final Set<String> _tags = {};
  int? _collectionId;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _answerCtrl.dispose();
    _noteCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  /// 输入变化 → 自动补卡面（词条命中词库则预填释义）。
  void _autoFill() {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) return;
    final dict = ref.read(dictionaryServiceProvider);
    final hits = dict.lookup(text);
    if (hits.isNotEmpty) {
      setState(() {
        _customAnswer = dict.buildWordAnswer(hits.first);
        _answerCtrl.text = _customAnswer;
      });
    }
  }

  String _guessedKind(String text) {
    if (text.contains(RegExp(r'[\s\u3000]{2,}|\p{P}', unicode: true)) &&
        text.length > 20) {
      return 'quote';
    }
    return 'word';
  }

  Future<void> _save() async {
    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('先输入要收藏的内容')));
      return;
    }

    final quota = await ref.read(quotaProvider.future);
    if (quota.libraryFull) {
      if (mounted) {
        PaywallSheet.show(
            context: context, reason: '记忆库已满 ${Quota.maxLibraryCards} 张');
      }
      return;
    }

    final lang = langCodeOf(detectLang(content));
    final kind = _kind == 'auto' ? _guessedKind(content) : _kind;
    final answer = _answerCtrl.text.trim().isEmpty
        ? (_customAnswer.isNotEmpty ? _customAnswer : '（待补充答案）')
        : _answerCtrl.text.trim();

    await ref.read(itemRepositoryProvider).createManualCard(
          prompt: content,
          answer: answer,
          kind: kind,
          lang: lang,
          tags: _tags.toList(),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          collectionId: _collectionId,
        );
    ref.read(analyticsProvider).track(
      AnalyticsEvents.itemCollected,
      props: {'source': 'manual', 'kind': kind},
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
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('收藏', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(
              '一句话就够了：输入内容，其余自动完成',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            // ---- 主输入（唯一必填）----
            TextField(
              controller: _contentCtrl,
              autofocus: true,
              maxLines: 3,
              onChanged: (_) => _autoFill(),
              decoration: InputDecoration(
                hintText: '想记住的内容：单词、句子、灵感…',
                suffixIcon: _contentCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _contentCtrl.clear();
                          _answerCtrl.clear();
                          setState(() {});
                        },
                      ),
              ),
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 14),
            // ---- 分类选择（主界面直接可选）----
            collections.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (cols) => Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<int?>(
                  value: _collectionId,
                  underline: const SizedBox.shrink(),
                  hint: const Text('放到未分类'),
                  icon: const Icon(Icons.folder_outlined, size: 20),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('未分类'),
                    ),
                    ...cols.where((c) => c.isSystem || c.id != -1).map(
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
            const SizedBox(height: 6),
            // ---- 收起/展开更多 ----
            InkWell(
              onTap: () => setState(() => _moreOpen = !_moreOpen),
              child: Row(
                children: [
                  Icon(
                    _moreOpen ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '更多选项 · 释义可改',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (_moreOpen) ...[
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'auto', label: Text('自动')),
                  ButtonSegment(value: 'word', label: Text('词条')),
                  ButtonSegment(value: 'quote', label: Text('语录')),
                  ButtonSegment(value: 'idea', label: Text('灵感')),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _answerCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '答案 / 释义',
                  hintText: '词库会自动补，可改',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: '备注（为什么收）'),
              ),
              const SizedBox(height: 12),
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
            ],
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
