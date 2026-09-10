import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

/// 一首诗的原始数据（未挖空）。
class Poem {
  const Poem({required this.title, required this.author, required this.lines});

  final String title;
  final String author;
  final List<String> lines; // 每句（不含标点）
}

/// 诗句中的单个挖空位置。
class PuzzleBlank {
  const PuzzleBlank({
    required this.lineIndex,
    required this.start,
    required this.length,
  });

  final int lineIndex;
  final int start; // 该句内起始字符下标
  final int length; // 挖掉字数（1 或 2）

  /// 被挖掉的原文。
  String answerIn(List<String> lines) =>
      lines[lineIndex].substring(start, start + length);
}

/// 一道填空题：随机选一首诗 + 挖空若干处。
class PoetryPuzzle {
  const PoetryPuzzle({
    required this.poem,
    required this.blanks,
  });

  final Poem poem;
  final List<PuzzleBlank> blanks;

  /// 挖空后某句的展示片段（文字段落 + 空位标记 [start, end)）。
  List<LineSegment> segmentsOf(int lineIndex) {
    final line = poem.lines[lineIndex];
    final segments = <LineSegment>[];
    var cursor = 0;
    for (final b in blanks.where((b) => b.lineIndex == lineIndex)) {
      if (b.start > cursor) {
        segments.add(LineSegment.text(line.substring(cursor, b.start)));
      }
      segments.add(LineSegment.blank(b));
      cursor = b.start + b.length;
    }
    if (cursor < line.length) {
      segments.add(LineSegment.text(line.substring(cursor)));
    }
    return segments;
  }
}

/// 展示片段：原文字段或挖空。
class LineSegment {
  const LineSegment.text(this.text) : blank = null;
  const LineSegment.blank(this.blank) : text = null;

  final String? text;
  final PuzzleBlank? blank;
}

/// 挖空：每句至多一处，随机挑 [count] 个候选（短句不挖）。
///
/// 挖单字为主，较长句有 30% 概率挖双字，保证空位间不重叠。
List<PuzzleBlank> createBlanks(
  List<String> lines, {
  int count = 4,
  Random? random,
}) {
  final rng = random ?? Random();
  final candidates = <PuzzleBlank>[];
  for (var li = 0; li < lines.length; li++) {
    final len = lines[li].length;
    if (len < 3) continue; // 太短不挖，避免整句被挖光
    final maxStart = len >= 5 ? len - 2 : len - 1;
    final start = rng.nextInt(maxStart + 1);
    final length = len >= 5 && rng.nextInt(10) < 3 ? 2 : 1;
    candidates.add(
      PuzzleBlank(lineIndex: li, start: start, length: length),
    );
  }
  candidates.shuffle(rng);
  return candidates.take(count).toList();
}

/// 校验用户填入的空是否正确。
bool blankIsCorrect(PuzzleBlank blank, List<String> lines, String input) =>
    input.trim() == blank.answerIn(lines);

/// 诗词库（内置资产）。
class PoetryLibrary {
  static const _assetPath = 'lib/assets/poetry/poems.json';

  /// 加载全部诗（未挖空）。
  static Future<List<Poem>> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final e in list)
        Poem(
          title: e['title'] as String,
          author: e['author'] as String,
          lines: (e['lines'] as List<dynamic>).cast<String>(),
        ),
    ];
  }

  /// 随机挑一首诗生成填空谜题。
  static Future<PoetryPuzzle> randomPuzzle({
    List<Poem>? from,
    int blankCount = 4,
    Random? random,
  }) async {
    final poems = from ?? await load();
    final rng = random ?? Random();
    final poem = poems[rng.nextInt(poems.length)];
    return PoetryPuzzle(
      poem: poem,
      blanks: createBlanks(poem.lines, count: blankCount, random: rng),
    );
  }
}