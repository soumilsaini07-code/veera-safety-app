import 'package:geolocator/geolocator.dart';
import 'ai_service.dart';

class RouteDeviationService {
  final AIService _aiService = AIService();

  /// Mocks checking if a user has deviated from the path
  /// In a real app, this would be continuously called with a Stream of locations
  /// comparing against the Polyline of the expected route.
  Future<bool> checkDeviation(Position currentPosition, Position expectedPosition) async {
    double distanceInMeters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      expectedPosition.latitude,
      expectedPosition.longitude,
    );

    // If deviated by more than 500 meters
    if (distanceInMeters > 500) {
      int riskScore = await _aiService.calculateRiskScore(currentPosition, DateTime.now(), distanceInMeters);
      
      if (riskScore > 75) {
        // High risk, trigger warning
        return true;
      }
    }
    return false;
  }
}
