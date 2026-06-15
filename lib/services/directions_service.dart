import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DirectionsService {
  static const String _apiKey = 'AIzaSyAJ8pPVoNhsEAf_-CQ1dlFNHA_sP275EJI';

  Future<List<LatLng>?> getRoute(Position origin, String destination) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${Uri.encodeComponent(destination)}&key=$_apiKey';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final String polylinePointsStr = data['routes'][0]['overview_polyline']['points'];
        PolylinePoints polylinePoints = PolylinePoints();
        List<PointLatLng> result = polylinePoints.decodePolyline(polylinePointsStr);
        
        if (result.isNotEmpty) {
          return result.map((PointLatLng point) => LatLng(point.latitude, point.longitude)).toList();
        }
      } else {
        throw Exception('${data['status']} - ${data['error_message'] ?? 'Could not find destination. Try being more specific.'}');
      }
    } else {
      throw Exception('Failed to connect to Google Maps API');
    }
    return null;
  }

  Future<List<String>> getPlaceSuggestions(String input) async {
    if (input.trim().isEmpty) return [];
    
    final String url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input.trim())}&key=$_apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return (data['predictions'] as List)
              .map((p) => p['description'] as String)
              .toList();
        }
      }
    } catch (e) {
      debugPrint("Autocomplete Error: $e");
    }
    return [];
  }
}
