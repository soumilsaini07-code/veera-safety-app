import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LiveTrackingService {
  static const String _serverUrl = 'http://3.111.147.106:3000/api/update';
  Timer? _trackingTimer;
  final Battery _battery = Battery();

  void startTracking() {
    if (_trackingTimer != null && _trackingTimer!.isActive) return;

    // Send updates every 10 seconds
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _sendUpdate(true);
    });
    
    // Send first update immediately
    _sendUpdate(true);
  }

  void stopTracking() async {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    await _sendUpdate(false);
  }

  Future<void> _sendUpdate(bool isSosActive) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get Location
      Position? position;
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
        }
      } catch (e) {
        debugPrint("Live tracking location error: $e");
      }

      // Get Battery
      int batteryLevel = 100;
      try {
        batteryLevel = await _battery.batteryLevel;
      } catch (e) {
        debugPrint("Battery error: $e");
      }

      final payload = {
        'uid': user.uid,
        'name': user.displayName ?? 'Unknown',
        'lat': position?.latitude ?? 0.0,
        'lng': position?.longitude ?? 0.0,
        'battery': batteryLevel,
        'isSosActive': isSosActive,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint("Failed to send live tracking update: $e");
    }
  }
}
