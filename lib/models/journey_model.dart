class JourneyModel {
  final String journeyId;
  final String userId;
  final String startLocation;
  final String destination;
  final DateTime startTime;
  final DateTime? endTime;
  final String status;

  JourneyModel({
    required this.journeyId,
    required this.userId,
    required this.startLocation,
    required this.destination,
    required this.startTime,
    this.endTime,
    required this.status,
  });

  factory JourneyModel.fromMap(Map<String, dynamic> map, String id) {
    return JourneyModel(
      journeyId: id,
      userId: map['userId'] ?? '',
      startLocation: map['startLocation'] ?? '',
      destination: map['destination'] ?? '',
      startTime: map['startTime'] != null ? DateTime.parse(map['startTime']) : DateTime.now(),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startLocation': startLocation,
      'destination': destination,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'status': status,
    };
  }
}
