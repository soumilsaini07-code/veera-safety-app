import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class JourneyService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    } 

    return await Geolocator.getCurrentPosition();
  }

  Future<String> startJourney(String userId, String destination) async {
    Position pos = await getCurrentLocation();
    
    DatabaseReference ref = _db.ref().child('Journeys').push();
    await ref.set({
      'userId': userId,
      'startLocation': '${pos.latitude}, ${pos.longitude}',
      'destination': destination,
      'startTime': DateTime.now().toIso8601String(),
      'status': 'active',
    });

    return ref.key ?? "mock-journey";
  }

  Future<void> endJourney(String journeyId) async {
    await _db.ref().child('Journeys').child(journeyId).update({
      'endTime': DateTime.now().toIso8601String(),
      'status': 'completed',
    });
  }
}
