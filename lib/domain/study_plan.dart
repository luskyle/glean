/// 学习关卡计划：渐进解锁机制。
///
/// 规则（2026-09-08 确认）：
/// - 每语言按词库 level 字段构成阶梯（如日语 五十音 → N5 → N4；英语 A1 → A2）
/// - 第一级默认解锁；下一级需要**上一级已学词数达到门槛**
/// - 门槛 = min(上一级总词数, 100)：大词级最多学 100 词即可解锁；小词级需学完
library;

class StudyPlan {
  const StudyPlan._();

  /// 语言 → 关卡顺序（对应 words.level 字段）。
  static const Map<String, List<String>> ordered = {
    'ja': ['kana', 'N5', 'N4'],
    'en': ['A1', 'A2'],
    'ko': ['入门', '进阶'],
    'fr': ['A1', 'A2'],
    'es': ['A1', 'A2'],
  };

  /// 关卡显示名。
  static const Map<String, String> labels = {
    'kana': '五十音',
    'N5': 'N5 基础',
    'N4': 'N4 进阶',
    'A1': '入门 A1',
    'A2': '进阶 A2',
    '入门': '入门',
    '进阶': '进阶',
  };

  static List<String> levelsFor(String lang) => ordered[lang] ?? [lang];

  static String labelOf(String level) => labels[level] ?? level;

  /// 解锁下一级所需学完的上一级词数。
  static int unlockRequirement(int prevTotal) =>
      prevTotal <= 100 ? prevTotal : 100;

  /// 当前关卡是否解锁：[prevLearned] 为上一级已学数，[prevTotal] 为上一级总数。
  static bool isLevelUnlocked({
    required int index,
    required int prevLearned,
    required int prevTotal,
  }) {
    if (index == 0) return true; // 第一级恒解锁
    return prevLearned >= unlockRequirement(prevTotal);
  }
}