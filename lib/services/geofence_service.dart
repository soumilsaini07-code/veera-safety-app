import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeofenceService {
  StreamSubscription<Position>? _geofenceSubscription;
  bool _isGeofencing = false;
  
  void startRouteGeofence(List<LatLng> routePoints, double deviationThresholdInMeters, Function onDeviation) {
    if (_isGeofencing) return;
    _isGeofencing = true;
    _geofenceSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)
    ).listen((Position currentPosition) {
      if (routePoints.isEmpty) return;

      double minDistance = double.infinity;
      
      for (var point in routePoints) {
        double distance = Geolocator.distanceBetween(
          point.latitude, point.longitude, 
          currentPosition.latitude, currentPosition.longitude
        );
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
      
      if (minDistance > deviationThresholdInMeters) {
        onDeviation();
      }
    });
  }

  void stopGeofence() {
    _geofenceSubscription?.cancel();
    _isGeofencing = false;
  }
}
