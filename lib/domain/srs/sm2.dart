/// SM-2 间隔重复引擎（纯函数，无任何 Flutter 依赖，可单独单测）。
///
/// 依据《技术调研-核心技术选型》：MVP 用自写 SM-2（<100 行），
/// review_log 保留完整字段（quality/interval/ease），≥4 周数据后可切 FSRS。
library;

/// 单卡 SRS 调度状态（不可变）。
class Sm2State {
  const Sm2State({
    this.repetitions = 0,
    this.easeFactor = defaultEase,
    this.intervalDays = 0,
  });

  /// 连续答对次数。答错归零（重学路径）。
  final int repetitions;

  /// 难度系数，钳制在 [minEase, maxEase]。
  final double easeFactor;

  /// 当前间隔（天）。0 表示新卡尚未排期。
  final int intervalDays;

  static const double defaultEase = 2.5;
  static const double minEase = 1.3;
  static const double maxEase = 3.0;

  Sm2State copyWith({int? repetitions, double? easeFactor, int? intervalDays}) {
    return Sm2State(
      repetitions: repetitions ?? this.repetitions,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Sm2State &&
        other.repetitions == repetitions &&
        other.easeFactor == easeFactor &&
        other.intervalDays == intervalDays;
  }

  @override
  int get hashCode => Object.hash(repetitions, easeFactor, intervalDays);

  @override
  String toString() =>
      'Sm2State(reps=$repetitions, ef=${easeFactor.toStringAsFixed(2)}, I=$intervalDays)';
}

/// 一次复习的结果：新的调度状态 + 下次到期时间。
class Sm2Result {
  const Sm2Result({required this.state, required this.dueAt});

  final Sm2State state;
  final DateTime dueAt;
}

/// 三键评级（UI 层直接使用的语义）。
enum ReviewRating {
  /// 忘了（答错，quality 1）
  forgot,

  /// 模糊（quality 3）
  fuzzy,

  /// 记得（quality 4）
  remembered,
}

/// 三键评级 → SM-2 quality（0~5）。
int sm2QualityFor(ReviewRating rating) {
  return switch (rating) {
    ReviewRating.forgot => 1,
    ReviewRating.fuzzy => 3,
    ReviewRating.remembered => 4,
  };
}

/// 对 [state] 执行一次 quality 为 [quality] 的复习，返回新状态与下次到期时间。
///
/// - quality 0~2 视为答错：repetitions 归零、间隔重置为 1 天（重学路径）。
/// - quality 3 以上视为答对：间隔按 1 → 6 → round(I × EF) 增长。
/// - EF 更新遵循 SM-2 公式：EF' = EF + (0.1 - (5-q)(0.08 + (5-q)·0.02))，钳制 [1.3, 3.0]。
///
/// [now] 必须显式传入（可测试性），到期时间 = now + 新间隔。
Sm2Result sm2Review(Sm2State state, int quality, {required DateTime now}) {
  if (quality < 0 || quality > 5) {
    throw ArgumentError.value(quality, 'quality', 'must be in 0..5');
  }

  var repetitions = state.repetitions;
  var easeFactor = state.easeFactor;
  var interval = state.intervalDays;

  if (quality >= 3) {
    interval = switch (repetitions) {
      0 => 1,
      1 => 6,
      _ => (interval * easeFactor).round(),
    };
    repetitions += 1;
    easeFactor += 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02);
  } else {
    // 答错：EF 不变（经典 SM-2），重学路径从 1 天重新开始。
    repetitions = 0;
    interval = 1;
  }

  if (easeFactor < Sm2State.minEase) easeFactor = Sm2State.minEase;
  if (easeFactor > Sm2State.maxEase) easeFactor = Sm2State.maxEase;
  // 间隔上限（≈100 年）：防止长周期模拟/异常数据导致 DateTime 溢出
  if (interval < 1) interval = 1;
  if (interval > maxIntervalDays) interval = maxIntervalDays;

  final next = Sm2State(
    repetitions: repetitions,
    easeFactor: easeFactor,
    intervalDays: interval,
  );
  return Sm2Result(state: next, dueAt: now.add(Duration(days: interval)));
}

/// 间隔上限（天，约 100 年），防御性钳制。
const int maxIntervalDays = 36500;

/// 新卡首次排期：明天首复。
DateTime firstReviewDueAt(DateTime now) => now.add(const Duration(days: 1));

/// 卡片是否到期（dueAt <= now，秒级精度）。
bool isDue(DateTime dueAt, DateTime now) => !dueAt.isAfter(now);

/// 是否进入"已掌握"（投影规则之一：间隔 ≥ 90 天视为掌握）。
bool isMastered(Sm2State state) => state.intervalDays >= 90;

/// 是否冷置（超过 [coldDays] 未复习，默认 30 天，见防囤积机制）。
bool isCold({required DateTime? lastReviewedAt, required DateTime now, int coldDays = 30}) {
  if (lastReviewedAt == null) return false;
  return now.difference(lastReviewedAt).inDays > coldDays;
}