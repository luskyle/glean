import 'dart:convert';

import 'package:flutter/services.dart';

/// 离线词库（成卡引擎的本地兜底层）。

/// 词条（与 drift 的 words 表字段对齐）。
class DictionaryEntry {
  const DictionaryEntry({
    required this.lang,
    required this.headword,
    this.reading,
    this.meaning,
    this.level,
  });

  final String lang;
  final String headword;
  final String? reading;
  final String? meaning;
  final String? level;
}

/// 内置微型词库（兜底样例：日英入门词）。
const List<DictionaryEntry> kSampleDictionary = [
  // ---- 日语（考纲词汇，含读音与中文释义）----
  DictionaryEntry(
      lang: 'ja', headword: '食べる', reading: 'たべる', meaning: '吃', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '飲む', reading: 'のむ', meaning: '喝', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '見る', reading: 'みる', meaning: '看', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '行く', reading: 'いく', meaning: '去', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '来る', reading: 'くる', meaning: '来', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '話す', reading: 'はなす', meaning: '说，讲', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '読む', reading: 'よむ', meaning: '读', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '書く', reading: 'かく', meaning: '写', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '聞く', reading: 'きく', meaning: '听；问', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '覚える', reading: 'おぼえる', meaning: '记住', level: 'N4'),
  DictionaryEntry(
      lang: 'ja', headword: '忘れる', reading: 'わすれる', meaning: '忘记', level: 'N4'),
  DictionaryEntry(
      lang: 'ja',
      headword: '勉強する',
      reading: 'べんきょうする',
      meaning: '学习',
      level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '水', reading: 'みず', meaning: '水', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '時間', reading: 'じかん', meaning: '时间', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '本', reading: 'ほん', meaning: '书', level: 'N5'),
  DictionaryEntry(
      lang: 'ja', headword: '友達', reading: 'ともだち', meaning: '朋友', level: 'N5'),
  DictionaryEntry(
      lang: 'ja',
      headword: 'ありがとう',
      reading: 'arigatou',
      meaning: '谢谢',
      level: 'N5'),
  DictionaryEntry(
      lang: 'ja',
      headword: 'すみません',
      reading: 'sumimasen',
      meaning: '对不起；劳驾',
      level: 'N5'),
  DictionaryEntry(
      lang: 'ja',
      headword: 'おはよう',
      reading: 'ohayou',
      meaning: '早上好',
      level: 'N5'),
  DictionaryEntry(
      lang: 'ja',
      headword: 'こんにちは',
      reading: 'konnichiwa',
      meaning: '你好（白天）',
      level: 'N5'),
  DictionaryEntry(
      lang: 'ja',
      headword: 'さようなら',
      reading: 'sayounara',
      meaning: '再见',
      level: 'N5'),
  // ---- 英语样例（COCA 前 2000 的一部分）----
  DictionaryEntry(
      lang: 'en', headword: 'remember', meaning: '记得；想起', level: 'A1'),
  DictionaryEntry(lang: 'en', headword: 'forget', meaning: '忘记', level: 'A1'),
  DictionaryEntry(lang: 'en', headword: 'learn', meaning: '学习', level: 'A1'),
  DictionaryEntry(
      lang: 'en', headword: 'review', meaning: '复习；回顾', level: 'A2'),
  DictionaryEntry(
      lang: 'en',
      headword: 'spaced',
      meaning: '间隔的（spaced repetition 间隔重复）',
      level: 'B2'),
  DictionaryEntry(
      lang: 'en', headword: 'improve', meaning: '改进；提高', level: 'A2'),
  DictionaryEntry(lang: 'en', headword: 'habit', meaning: '习惯', level: 'A2'),
  DictionaryEntry(lang: 'en', headword: 'goal', meaning: '目标', level: 'A2'),
];

/// 五十音 → 罗马音映射（读音标注用，词库管线产物之一）。
const Map<String, String> kKanaToRomaji = {
  'あ': 'a',
  'い': 'i',
  'う': 'u',
  'え': 'e',
  'お': 'o',
  'か': 'ka',
  'き': 'ki',
  'く': 'ku',
  'け': 'ke',
  'こ': 'ko',
  'さ': 'sa',
  'し': 'shi',
  'す': 'su',
  'せ': 'se',
  'そ': 'so',
  'た': 'ta',
  'ち': 'chi',
  'つ': 'tsu',
  'て': 'te',
  'と': 'to',
  'な': 'na',
  'に': 'ni',
  'ぬ': 'nu',
  'ね': 'ne',
  'の': 'no',
  'は': 'ha',
  'ひ': 'hi',
  'ふ': 'fu',
  'へ': 'he',
  'ほ': 'ho',
  'ま': 'ma',
  'み': 'mi',
  'む': 'mu',
  'め': 'me',
  'も': 'mo',
  'や': 'ya',
  'ゆ': 'yu',
  'よ': 'yo',
  'ら': 'ra',
  'り': 'ri',
  'る': 'ru',
  'れ': 're',
  'ろ': 'ro',
  'わ': 'wa',
  'を': 'o',
  'ん': 'n',
  'が': 'ga',
  'ぎ': 'gi',
  'ぐ': 'gu',
  'げ': 'ge',
  'ご': 'go',
  'ざ': 'za',
  'じ': 'ji',
  'ず': 'zu',
  'ぜ': 'ze',
  'ぞ': 'zo',
  'だ': 'da',
  'ぢ': 'ji',
  'づ': 'zu',
  'で': 'de',
  'ど': 'do',
  'ば': 'ba',
  'び': 'bi',
  'ぶ': 'bu',
  'べ': 'be',
  'ぼ': 'bo',
  'ぱ': 'pa',
  'ぴ': 'pi',
  'ぷ': 'pu',
  'ぺ': 'pe',
  'ぽ': 'po',
  'ア': 'a',
  'イ': 'i',
  'ウ': 'u',
  'エ': 'e',
  'オ': 'o',
  'カ': 'ka',
  'キ': 'ki',
  'ク': 'ku',
  'ケ': 'ke',
  'コ': 'ko',
  'サ': 'sa',
  'シ': 'shi',
  'ス': 'su',
  'セ': 'se',
  'ソ': 'so',
  'タ': 'ta',
  'チ': 'chi',
  'ツ': 'tsu',
  'テ': 'te',
  'ト': 'to',
  'ナ': 'na',
  'ニ': 'ni',
  'ヌ': 'nu',
  'ネ': 'ne',
  'ノ': 'no',
  'ハ': 'ha',
  'ヒ': 'hi',
  'フ': 'fu',
  'ヘ': 'he',
  'ホ': 'ho',
  'マ': 'ma',
  'ミ': 'mi',
  'ム': 'mu',
  'メ': 'me',
  'モ': 'mo',
  'ヤ': 'ya',
  'ユ': 'yu',
  'ヨ': 'yo',
  'ラ': 'ra',
  'リ': 'ri',
  'ル': 'ru',
  'レ': 're',
  'ロ': 'ro',
  'ワ': 'wa',
  'ヲ': 'o',
  'ン': 'n',
};

/// 离线词库服务：内存索引 = 内置样例 + 启动时载入的词库资产。
class DictionaryService {
  DictionaryService() {
    // 内置样例先行注入（即使词库资产加载失败也有兜底）
    for (final e in kSampleDictionary) {
      _index.putIfAbsent(e.headword, () => []).add(e);
    }
  }

  static const _assetPath = 'lib/assets/dictionary/jlpt.json';

  /// 附加语言包（英语/韩语/法语/西班牙语示例；Pro 解锁）。
  static const _extraPath = 'lib/assets/dictionary/extra_langs.json';

  final Map<String, List<DictionaryEntry>> _index = {};
  bool _loadedFromAsset = false;

  /// 词库资产是否已载入。
  bool get loadedFromAsset => _loadedFromAsset;

  /// 当前内存索引中的词条总数（样例 + 词库）。
  int get loadedCount =>
      _index.values.fold<int>(0, (acc, list) => acc + list.length);

  /// 全部词条（用于批量导入 words 表）。
  List<DictionaryEntry> get loadedEntries =>
      _index.values.expand((l) => l).toList();

  /// 按语言统计词条数（学习页语言包展示）。
  Map<String, int> countsByLang() {
    final counts = <String, int>{};
    for (final list in _index.values) {
      for (final e in list) {
        counts[e.lang] = (counts[e.lang] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// 指定语言下的全部词条（学习数据源）。
  List<DictionaryEntry> entriesForLang(String lang) {
    return _index.values.expand((l) => l).where((e) => e.lang == lang).toList();
  }

  /// 从 assets 载入词库 JSON（JLPT 词条 + 附加语言包）。失败静默（有样例兜底）。
  Future<void> loadFromAsset() async {
    if (_loadedFromAsset) return;
    try {
      final text = await rootBundle.loadString(_assetPath);
      loadJson(text);
    } catch (_) {
      // 词库缺失/加载失败不影响使用（样例词库兜底）
    }
    try {
      final extra = await rootBundle.loadString(_extraPath);
      loadJson(extra);
    } catch (_) {}
    if (loadedCount > kSampleDictionary.length) _loadedFromAsset = true;
  }

  /// 解析词库 JSON 并合并进内存索引（可测试）。
  void loadJson(String source) {
    final decoded = jsonDecode(source) as Map<String, dynamic>;
    final entries = (decoded['entries'] as List<dynamic>? ?? const []);
    var added = 0;
    for (final raw in entries) {
      final map = raw as Map<String, dynamic>;
      final headword = (map['headword'] as String?)?.trim() ?? '';
      if (headword.isEmpty) continue;
      final rawLevel = map['level'] as String?;
      String? level;
      if (rawLevel != null) {
        // 数字等级 → N 前缀（5 → N5）；五十音等自定义等级原样保留
        level = rawLevel.startsWith('N')
            ? rawLevel
            : (rawLevel == 'kana' ? rawLevel : 'N$rawLevel');
      }
      final entry = DictionaryEntry(
        lang: (map['lang'] as String?) ?? 'ja',
        headword: headword,
        reading: map['reading'] as String?,
        meaning: map['meaning'] as String?,
        level: level,
      );
      final bucket = _index.putIfAbsent(headword, () => []);
      // 同形词（headword+reading）去重
      if (bucket.any((e) => e.reading == entry.reading)) continue;
      bucket.add(entry);
      added += 1;
    }
    if (added > 0) _loadedFromAsset = true;
  }

  /// 精确查词：优先内存索引（样例 + 词库），支持多义项同形词。
  List<DictionaryEntry> lookup(String headword) {
    final trimmed = headword.trim();
    if (trimmed.isEmpty) return const [];
    return _index[trimmed] ?? const [];
  }

  /// 读音标注：若文本是整段假名，返回罗马音；否则 null。
  String? readingAnnotation(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final kanaOnly = RegExp(r'^[\u3040-\u30ff]+$').hasMatch(t);
    if (!kanaOnly) return null;
    final buf = StringBuffer();
    for (final ch in t.split('')) {
      buf.write(kKanaToRomaji[ch] ?? ch);
    }
    final romaji = buf.toString();
    if (romaji == t) return null; // 无映射
    return romaji;
  }

  /// 词条卡面：释义 + 读音 + 等级。
  String buildWordAnswer(DictionaryEntry e) {
    final buf = StringBuffer(e.meaning ?? '');
    if (e.reading != null && e.reading!.isNotEmpty) {
      buf.write('\n【${e.reading}】');
    }
    if (e.level != null && e.level!.isNotEmpty) {
      buf.write('\n等级：${e.level}');
    }
    return buf.toString();
  }
}
