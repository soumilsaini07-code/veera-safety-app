import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SafetyService {
  // Shake Detection
  static const double shakeThreshold = 15.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastShakeTime;

  // Speech to Text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  final VoidCallback onSOS;

  SafetyService({required this.onSOS});

  void init() {
    _initShakeDetection();
    _initSpeechDetection();
  }

  void _initShakeDetection() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      double acceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      // Remove gravity effect (approx 9.8)
      if (acceleration > shakeThreshold + 9.8) {
        final now = DateTime.now();
        if (_lastShakeTime == null || now.difference(_lastShakeTime!) > const Duration(seconds: 3)) {
          _lastShakeTime = now;
          onSOS(); // Trigger SOS
        }
      }
    });
  }

  void _initSpeechDetection() async {
    bool available = await _speech.initialize();
    if (available) {
      startListening();
    }
  }

  void startListening() {
    if (!_isListening) {
      _speech.listen(onResult: (result) {
        String recognizedWords = result.recognizedWords.toLowerCase();
        if (recognizedWords.contains('help me') || 
            recognizedWords.contains('emergency') || 
            recognizedWords.contains('save me')) {
          onSOS(); // Trigger SOS
        }
      });
      _isListening = true;
    }
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  void dispose() {
    _accelerometerSubscription?.cancel();
    stopListening();
  }
}
