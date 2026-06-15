import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geolocator/geolocator.dart';

class AIService {
  // In a real app, this should be fetched from a secure backend or remote config
  // For the hackathon, we are leaving it as a placeholder string that the user must fill
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';
  
  late final GenerativeModel _model;

  AIService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-pro',
      apiKey: _geminiApiKey,
    );
  }

  /// AI SafeRoute Engine
  /// Analyzes a potential route based on user description or waypoints.
  Future<String> evaluateRouteSafety(String startLocation, String destination) async {
    try {
      final prompt = '''
        Act as an AI SafeRoute Engine for a women safety application in India.
        Evaluate the safety of travelling from "$startLocation" to "$destination" right now.
        Consider factors like typical footfall, lighting, and general safety. 
        Provide a short 2-3 sentence recommendation on whether it's safe or if they should take precautions.
      ''';
      
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Unable to evaluate route at this time.';
    } catch (e) {
      return 'Error connecting to AI SafeRoute: $e';
    }
  }

  /// AI Risk Score
  /// Calculates a dynamic risk score (0-100) based on current context.
  Future<int> calculateRiskScore(Position currentPosition, DateTime time, double deviationDistanceMeters) async {
    try {
      final prompt = '''
        Act as an AI Risk Assessor. Calculate a risk score from 0 (very safe) to 100 (extreme danger).
        Context:
        - Current Time: ${time.toLocal().toString()}
        - Route Deviation: $deviationDistanceMeters meters
        - Coordinates: ${currentPosition.latitude}, ${currentPosition.longitude}
        
        Rules:
        - If time is late night (10 PM to 5 AM), increase score by 30.
        - If deviation > 500 meters, increase score by 40.
        - If deviation > 1000 meters, set score to at least 85.
        
        Output ONLY the integer score.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      final scoreString = response.text?.trim() ?? '0';
      return int.tryParse(scoreString) ?? 0;
    } catch (e) {
      return -1; // Error
    }
  }
}
