import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text, String lang) async {
    if (text.trim().isEmpty) return;

    // 언어코드 매핑
    final Map<String, String> langMap = {
      'korean': 'ko-KR',
      'english': 'en-US',
      'japanese': 'ja-JP',
      'vietnamese': 'vi-VN',
      'thai': 'th-TH',
      'indonesian': 'id-ID',
    };

    final code = langMap[lang] ?? 'en-US';

    await _tts.setLanguage(code);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);

    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
