import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class VoiceService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  bool _isListening = false;
  
  Function? onSOSDetect;

  Future<void> init() async {
    _isAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (_isListening) {
            Future.delayed(const Duration(milliseconds: 500), () => _startListening());
          }
        }
      },
      onError: (error) {
        debugPrint('Speech error: $error');
        if (_isListening) {
          Future.delayed(const Duration(milliseconds: 500), () => _startListening());
        }
      },
    );
  }

  void startListening(Function triggerSOS) async {
    onSOSDetect = triggerSOS;
    _isListening = true;
    
    if (!_isAvailable) {
      await init();
    }
    
    if (_isAvailable) {
      _startListening();
    }
  }

  void stopListening() {
    _isListening = false;
    _speech.stop();
  }

  void _startListening() {
    if (!_speech.isListening && _isListening) {
      _speech.listen(
        onResult: (result) {
          String text = result.recognizedWords.toLowerCase();
          
          int count = text.split(RegExp(r'\W+')).where((word) => word == 'help').length;
          if (count >= 3) {
            _isListening = false;
            _speech.stop();
            onSOSDetect?.call();
          }
        },
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
      );
    }
  }
}
