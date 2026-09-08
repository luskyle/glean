import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../providers.dart';
import '../review/flashcard.dart';

/// 学习会话：词库未学词 → 闪卡（先看再自测）→ 「学会」即入复习队列。
/// 机制闭环：主动学习产出新卡，复习页明天开始接手 SRS 排期。
class StudySessionScreen extends ConsumerStatefulWidget {
  const StudySessionScreen(
      {super.key, required this.lang, this.batchSize = 20});

  final String lang;
  final int batchSize;

  @override
  ConsumerState<StudySessionScreen> createState() => _StudySessionScreenState();
}

class _StudySessionScreenState extends ConsumerState<StudySessionScreen> {
  List<WordRow> _queue = const [];
  int _index = 0;
  int _learnedCount = 0;
  bool _loading = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(itemRepositoryProvider);
    final words = await repo.unstudiedWords(
      lang: widget.lang,
      limit: widget.batchSize,
    );
    setState(() {
      _queue = words;
      _finished = words.isEmpty;
      _loading = false;
    });
  }

  Future<void> _learned() async {
    final word = _queue[_index];
    final dict = ref.read(dictionaryServiceProvider);
    final hits = dict.lookup(word.headword);
    final answer = hits.isNotEmpty
        ? dict.buildWordAnswer(hits.first)
        : '${word.reading ?? ''}\n（待补充释义）'.trim();

    await ref.read(itemRepositoryProvider).createManualCard(
          prompt: word.headword,
          answer: answer,
          kind: 'word',
          lang: widget.lang,
          wordId: word.id, // 关联官方词条，避免重复学习
          source: 'study',
        );

    _advance();
  }

  void _skip() => _advance();

  void _advance() {
    setState(() {
      _learnedCount += 1;
      if (_index + 1 >= _queue.length) {
        _finished = true;
      } else {
        _index += 1;
      }
    });
    if (_finished) {
      ref.invalidate(reviewOverviewProvider);
      ref.invalidate(quotaProvider);
    }
  }

  Future<void> _leave() async {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final langName = LanguageName.of(widget.lang);

    if (_finished) {
      return Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 56, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  _queue.isEmpty ? '暂无未学词' : '本次学习完成',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _queue.isEmpty
                      ? '「$langName」词库中还没有可学的新词。'
                      : '「$langName」已学 $_learnedCount 词，明天开始首次复习',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _leave,
                  child: const Text('完成'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final word = _queue[_index];
    final hits = ref.read(dictionaryServiceProvider).lookup(word.headword);
    final entry = hits.isNotEmpty ? hits.first : null;

    return Scaffold(
      appBar:
          AppBar(title: Text('学习 · $langName ${_index + 1}/${_queue.length}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Flashcard(
                  key: ValueKey(word.id),
                  front: CardFace(
                    hint: '点按翻面看释义',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          word.headword,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (word.reading != null &&
                            word.reading!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            word.reading!,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                  back: CardFace(
                    child: Text(
                      entry != null ? entry.meaning ?? '' : '（待补充释义）',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _skip,
                      icon: const Icon(Icons.skip_next, size: 20),
                      label: const Text('跳过'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _learned,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('学会了'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 语言显示名（学习页标题用）。
class LanguageName {
  const LanguageName._();

  static String of(String code) {
    return switch (code) {
      'ja' => '日语',
      'en' => '英语',
      'ko' => '韩语',
      'fr' => '法语',
      'es' => '西班牙语',
      _ => code,
    };
  }
}
