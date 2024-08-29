// voice_recognition_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  Future<void> startListening(Function(String) onKeywordDetected) async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );

    if (available) {
      _isListening = true;
      _listen(onKeywordDetected);
    }
  }

  void _listen(Function(String) onKeywordDetected) {
    _speech.listen(
      onResult: (val) {
        if (val.recognizedWords.contains("danger")) {
          onKeywordDetected(val.recognizedWords);
          stopListening();
        }
      },
      listenFor: Duration(minutes: 5),
      pauseFor: Duration(seconds: 5),
      listenOptions:
          stt.SpeechListenOptions(cancelOnError: false, partialResults: true),
      // listenMode: stt.ListenMode.confirmation,  // Remove if deprecated
    );
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  bool get isListening => _isListening;
}
