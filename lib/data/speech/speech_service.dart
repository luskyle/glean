import 'package:flutter_tts/flutter_tts.dart';

/// 发音服务：系统 TTS（iOS AVSpeechSynthesizer / Android / 桌面视引擎）。
///
/// 依据《技术调研》§六：运行时用系统 TTS 兜底；离线语音包（云 TTS 批量
/// 预生成）作为后续增强（音频随版本发布，运行时零费用）。
/// 平台无 TTS 引擎时静默降级（影响为零）。
class SpeechService {
  final FlutterTts _tts = FlutterTts();
  bool _ok = false;

  static const Map<String, String> _locale = {
    'ja': 'ja-JP',
    'en': 'en-US',
    'ko': 'ko-KR',
    'fr': 'fr-FR',
    'es': 'es-ES',
    'zh': 'zh-CN',
  };

  Future<void> _ensure() async {
    if (_ok) return;
    try {
      await _tts.awaitSpeakCompletion(true);
      _ok = true;
    } catch (_) {
      // 无 TTS 引擎：静默降级
    }
  }

  /// 朗读文本（按语言对应系统语音）。失败静默。
  Future<void> speak(String lang, String text) async {
    await _ensure();
    if (!_ok || text.trim().isEmpty) return;
    try {
      await _tts.setLanguage(_locale[lang] ?? lang);
      await _tts.speak(text);
    } catch (_) {
      // 朗读失败不影响流程
    }
  }

  /// 是否至少可尝试（出现按钮的依据；仍可能无声）。
  bool get enabled => _ok;
}