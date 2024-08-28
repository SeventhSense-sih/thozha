// voice_recognition_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  Future<void> initialize() async {
    _isAvailable = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );

    if (!_isAvailable) {
      print("Speech recognition not available.");
    } else {
      print("Speech recognition initialized successfully.");
    }
  }

  Future<void> startListening(Function(String) onKeywordDetected) async {
    if (!_isAvailable) {
      await initialize();
    }

    if (_isAvailable) {
      _speech.listen(
        onResult: (val) {
          if (val.recognizedWords.contains("danger")) {
            onKeywordDetected(val.recognizedWords);
          }
        },
        listenFor:
            Duration(seconds: 30), // Listens for 30 seconds, renews on silence
        pauseFor: Duration(
            seconds: 100), // Pauses for 5 seconds after no sound, then resumes
        partialResults: true, // Continue to get partial results
        cancelOnError: false, // Don't cancel on error, continue listening
        onSoundLevelChange: (level) => print("Sound level: $level"),
        listenMode: stt.ListenMode.dictation, // Continuous dictation mode
      );
    }
  }

  void stopListening() {
    _speech.stop();
  }
}
