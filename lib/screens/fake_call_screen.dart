import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

class FakeCallScreen extends StatefulWidget {
  final String callerName;
  const FakeCallScreen({super.key, this.callerName = 'Incoming Call'});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool _isAnswered = false;
  int _callDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    FlutterRingtonePlayer().play(
      android: AndroidSounds.ringtone,
      ios: IosSounds.glass,
      looping: true,
      volume: 1.0,
      asAlarm: true, // Forces sound even if device is on silent
    );
    Vibration.hasVibrator().then((hasVibrator) {
      if (hasVibrator == true) {
        Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 1);
      }
    });
  }

  @override
  void dispose() {
    FlutterRingtonePlayer().stop();
    Vibration.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _answerCall() {
    FlutterRingtonePlayer().stop();
    Vibration.cancel();
    setState(() => _isAnswered = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
    });
  }

  void _endCall() {
    Navigator.pop(context);
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(widget.callerName, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_isAnswered ? _formatDuration(_callDuration) : 'Mobile', style: const TextStyle(color: Colors.grey, fontSize: 18)),
            const Spacer(),
            if (!_isAnswered)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(Icons.call_end, Colors.red, _endCall),
                  _buildCallButton(Icons.call, Colors.green, _answerCall),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCallButton(Icons.call_end, Colors.red, _endCall),
                ],
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton(IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 40),
      ),
    );
  }
}
