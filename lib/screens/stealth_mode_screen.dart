import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class StealthModeScreen extends StatefulWidget {
  final VoidCallback onExit;
  const StealthModeScreen({super.key, required this.onExit});

  @override
  State<StealthModeScreen> createState() => _StealthModeScreenState();
}

class _StealthModeScreenState extends State<StealthModeScreen> {
  int _tapCount = 0;
  Timer? _tapTimer;

  @override
  void initState() {
    super.initState();
    // Hide status bar and navigation bar to make it look completely dead
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.black,
    ));
  }

  @override
  void dispose() {
    // Restore UI overlays on exit
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _tapTimer?.cancel();
    super.dispose();
  }

  void _handleTap() {
    _tapCount++;
    _tapTimer?.cancel();
    _tapTimer = Timer(const Duration(seconds: 2), () {
      _tapCount = 0;
    });

    if (_tapCount >= 5) {
      widget.onExit();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure black
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
        ),
      ),
    );
  }
}
