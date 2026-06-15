import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class PlacesService {
  // Ensure you put your valid Google Maps API key here
  static const String _apiKey = 'AIzaSyAJ8pPVoNhsEAf_-CQ1dlFNHA_sP275EJI';

  Future<List<Map<String, dynamic>>> getNearbyPoliceStations(Position position) async {
    final String url = 
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${position.latitude},${position.longitude}'
      '&radius=5000'
      '&type=police'
      '&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['results']);
        }
      }
    } catch (e) {
      print('Error fetching places: $e');
    }
    return [];
  }
}
