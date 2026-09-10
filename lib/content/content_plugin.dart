/// 内容插件机制：玩法 + 内容 解耦。
///
/// - [ContentKind]：三种玩法（翻卡 / 单选 / 填空）
/// - [ContentItem]：与玩法对应的内容单元（sealed 分发）
/// - [ContentPlugin]：一个插件 = 清单信息 + 内容列表
/// - 内置插件在 [ContentRegistry.builtin] 注册；未来的在线商店只需
///   把内容源换成网络加载，玩法与播放器（ContentPlayerScreen）复用。
library;

/// 玩法类型。
enum ContentKind { flashcard, quiz, cloze }

/// 内容单元（按玩法区分）。
sealed class ContentItem {
  const ContentItem();
}

/// 翻卡：正面 / 背面（可带提示）。
class FlashcardItem extends ContentItem {
  const FlashcardItem({
    required this.front,
    required this.back,
    this.hint,
  });

  final String front;
  final String back;
  final String? hint;
}

/// 单选：题目 + 选项 + 正确下标 + 可选解析。
class QuizItem extends ContentItem {
  const QuizItem({
    required this.prompt,
    required this.options,
    required this.answerIndex,
    this.explanation,
  });

  final String prompt;
  final List<String> options;
  final int answerIndex;
  final String? explanation;
}

/// 填空：多行文本（如古诗词），空位由播放器按玩法策略动态生成。
class ClozeItem extends ContentItem {
  const ClozeItem({
    required this.title,
    required this.lines,
    this.subtitle,
  });

  final String title;

  /// 副信息（如作者/出处）。
  final String? subtitle;

  /// 正文行（不含标点）。
  final List<String> lines;
}

/// 内容插件描述。
class ContentPlugin {
  const ContentPlugin({
    required this.id,
    required this.name,
    required this.description,
    required this.kind,
    required this.items,
    this.locale = 'zh',
  });

  final String id;
  final String name;
  final String description;
  final ContentKind kind;
  final List<ContentItem> items;
  final String locale;
}