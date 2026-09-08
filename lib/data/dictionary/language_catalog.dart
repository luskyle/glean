/// 语言包目录（词库付费分级）。
///
/// 商业模式（2026-09 讨论确认）：**日语/英语免费**；更多小语种
/// （韩语/法语/西班牙语…）需 Pro 订阅解锁（跟随现有订阅墙）。
library;

class LanguageInfo {
  const LanguageInfo({
    required this.code,
    required this.name,
    required this.badge,
    required this.free,
    required this.desc,
  });

  final String code;
  final String name;

  /// 列表徽标文字（避免依赖平台 emoji flag 字体）。
  final String badge;
  final bool free;
  final String desc;
}

class LanguageCatalog {
  const LanguageCatalog._();

  static const _freeLangs = {'ja', 'en'};

  static const entries = <LanguageInfo>[
    LanguageInfo(
      code: 'ja',
      name: '日语',
      badge: '日',
      free: true,
      desc: '五十音 + JLPT N5~N4（697 词）',
    ),
    LanguageInfo(
      code: 'en',
      name: '英语',
      badge: '英',
      free: true,
      desc: '核心词库（COCA 基线，示例包 15 词）',
    ),
    LanguageInfo(
      code: 'ko',
      name: '韩语',
      badge: '韩',
      free: false,
      desc: '谚文口语核心（示例包 20 词）',
    ),
    LanguageInfo(
      code: 'fr',
      name: '法语',
      badge: '法',
      free: false,
      desc: '入门核心（示例包 15 词）',
    ),
    LanguageInfo(
      code: 'es',
      name: '西班牙语',
      badge: '西',
      free: false,
      desc: '入门核心（示例包 15 词）',
    ),
  ];

  static bool isFree(String lang) => _freeLangs.contains(lang);

  static bool unlocked(String lang, {required bool isPro}) =>
      isFree(lang) || isPro;
}