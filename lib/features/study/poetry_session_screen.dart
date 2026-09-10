import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/poetry/poetry_puzzle.dart';

/// 古诗词填空挑战：随机一首古诗，句中若干字词划线待填，
/// 点「检查」后显示完整诗句与正误（对号 → 背面答案）。
class PoetrySessionScreen extends ConsumerStatefulWidget {
  const PoetrySessionScreen({super.key});

  @override
  ConsumerState<PoetrySessionScreen> createState() =>
      _PoetrySessionScreenState();
}

class _PoetrySessionScreenState extends ConsumerState<PoetrySessionScreen> {
  static Future<List<Poem>>? _poemsCache;

  final _rng = Random();
  List<Poem>? _poems;
  PoetryPuzzle? _puzzle;
  final List<TextEditingController> _controllers = [];
  bool _loading = true;
  bool _checked = false;
  int _roundScore = 0; // 本首答对空数
  int _roundTotal = 0; // 本首总空数
  int _totalCorrect = 0; // 累计答对
  int _totalBlanks = 0; // 累计空数

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _init() async {
    final future = _poemsCache ??= PoetryLibrary.load();
    final loaded = await future;
    if (!mounted) return;
    setState(() {
      _poems = loaded;
      _loading = false;
    });
    _next();
  }

  void _next() {
    final poems = _poems;
    if (poems == null) return;
    final poem = poems[_rng.nextInt(poems.length)];
    final blanks = createBlanks(poem.lines, count: 5, random: _rng);
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    for (var i = 0; i < blanks.length; i++) {
      _controllers.add(TextEditingController());
    }
    setState(() {
      _puzzle = PoetryPuzzle(poem: poem, blanks: blanks);
      _checked = false;
      _roundScore = 0;
      _roundTotal = blanks.length;
    });
  }

  void _check() {
    final puzzle = _puzzle!;
    var correct = 0;
    for (var i = 0; i < puzzle.blanks.length; i++) {
      if (blankIsCorrect(puzzle.blanks[i], puzzle.poem.lines,
          _controllers[i].text)) {
        correct++;
      }
    }
    setState(() {
      _checked = true;
      _roundScore = correct;
      _totalCorrect += correct;
      _totalBlanks += puzzle.blanks.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final puzzle = _puzzle;
    if (puzzle == null) {
      return const Scaffold(body: Center(child: Text('诗词加载失败')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('古诗词填空')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: _PoemCard(
              puzzle: puzzle,
              controllers: _controllers,
              checked: _checked,
              onCheck: _check,
              onNext: _next,
              roundScore: _roundScore,
              roundTotal: _roundTotal,
              totalCorrect: _totalCorrect,
              totalBlanks: _totalBlanks,
            ),
          ),
        ),
      ),
    );
  }
}

/// 诗卡：题目作者 + 挖空诗句 + 底部操作（检查 / 下一首）。
class _PoemCard extends StatelessWidget {
  const _PoemCard({
    required this.puzzle,
    required this.controllers,
    required this.checked,
    required this.onCheck,
    required this.onNext,
    required this.roundScore,
    required this.roundTotal,
    required this.totalCorrect,
    required this.totalBlanks,
  });

  final PoetryPuzzle puzzle;
  final List<TextEditingController> controllers;
  final bool checked;
  final VoidCallback onCheck;
  final VoidCallback onNext;
  final int roundScore;
  final int roundTotal;
  final int totalCorrect;
  final int totalBlanks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final poem = puzzle.poem;

    // 空位下标 → 对应 controller / 结果判定
    final indexByBlank = {
      for (var i = 0; i < puzzle.blanks.length; i++) puzzle.blanks[i]: i,
    };

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              poem.title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              '【${poem.author}】',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            for (var li = 0; li < poem.lines.length; li++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LineRow(
                  segments: puzzle.segmentsOf(li),
                  checked: checked,
                  controllers: controllers,
                  indexByBlank: indexByBlank,
                  lines: poem.lines,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              checked
                  ? '本首答对 $roundScore/$roundTotal · 累计 $totalCorrect/$totalBlanks'
                  : '在划线处补全诗句',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: checked
                  ? FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.skip_next, size: 20),
                      label: const Text('下一首'),
                    )
                  : FilledButton.icon(
                      onPressed: onCheck,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('检查'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 一行诗句：文字片段与输入空位交替渲染。
class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.segments,
    required this.checked,
    required this.controllers,
    required this.indexByBlank,
    required this.lines,
  });

  final List<LineSegment> segments;
  final bool checked;
  final List<TextEditingController> controllers;
  final Map<PuzzleBlank, int> indexByBlank;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final seg in segments)
          if (seg.text != null)
            Text(
              seg.text!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    height: 1.4,
                  ),
            )
          else
            _BlankInput(
              blank: seg.blank!,
              index: indexByBlank[seg.blank]!,
              controller: controllers[indexByBlank[seg.blank]!],
              checked: checked,
              lines: lines,
            ),
      ],
    );
  }
}

/// 挖空输入框：未检查时可输入；检查后显示正误（绿对 / 红叉 + 答案）。
class _BlankInput extends StatelessWidget {
  const _BlankInput({
    required this.blank,
    required this.index,
    required this.controller,
    required this.checked,
    required this.lines,
  });

  final PuzzleBlank blank;
  final int index;
  final TextEditingController controller;
  final bool checked;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final answer = blank.answerIn(lines);
    final input = controller.text.trim();
    final isCorrect = input == answer;

    if (!checked) {
      return SizedBox(
        width: blank.length * 24.0 + 18,
        height: 44,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
    }

    // 检查后：正确绿点，错误红色 + 正确答案
    final correct = isCorrect;
    return Tooltip(
      message: isCorrect ? answer : '正确答案：$answer',
      child: Container(
        width: blank.length * 24.0 + 18,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: correct
              ? Colors.green.withValues(alpha: 0.14)
              : Colors.red.withValues(alpha: 0.12),
          border: Border.all(
            color: correct ? Colors.green : Colors.red,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          isCorrect ? answer : (controller.text.isEmpty ? '×' : input),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: correct ? Colors.green.shade700 : Colors.red.shade700,
          ),
        ),
      ),
    );
  }
}