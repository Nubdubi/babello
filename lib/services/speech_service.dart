import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<bool> init() async {
    return await _speech.initialize();
  }

  bool get isListening => _speech.isListening;

  Future<String> listenOnce({
    required Function(String text) onResult,
    required Function(double level) onSoundLevel,
    String localeId = 'ko_KR',
  }) async {
    String recognized = '';
    await _speech.listen(
      onResult: (result) {
        recognized = result.recognizedWords;
        onResult(recognized);
      },
      onSoundLevelChange: (level) {
        onSoundLevel(level);
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    );

    await Future.delayed(const Duration(seconds: 8));
    await _speech.stop();
    return recognized;
  }

  void stop() => _speech.stop();
}
