import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/emergency_contact_model.dart';

class RealtimeDatabaseService {
  FirebaseDatabase? _db;

  RealtimeDatabaseService() {
    try {
      _db = FirebaseDatabase.instance;
    } catch (e) {
      debugPrint("Realtime Database not initialized");
    }
  }

  bool get _isDbReady => _db != null;

  // Contacts
  Future<void> addContact(String userId, String name, String phone) async {
    if (!_isDbReady) return;
    await _db!.ref().child('Users').child(userId).child('EmergencyContacts').push().set({
      'name': name,
      'phone': phone,
    });
  }

  Stream<List<EmergencyContactModel>> getContacts(String userId) {
    if (!_isDbReady) return Stream.value([]);
    return _db!.ref().child('Users').child(userId).child('EmergencyContacts').onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.value == null) return <EmergencyContactModel>[];
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.entries.map((e) {
        return EmergencyContactModel.fromMap(Map<String, dynamic>.from(e.value as Map), e.key);
      }).toList();
    });
  }

  Future<void> deleteContact(String userId, String contactId) async {
    if (!_isDbReady) return;
    await _db!.ref().child('Users').child(userId).child('EmergencyContacts').child(contactId).remove();
  }

  // SOS Events
  Future<String?> logSOSEvent(String userId, Map<String, dynamic> eventData) async {
    if (!_isDbReady) return "mock-sos-id";
    final ref = _db!.ref().child('sos_events').push();
    await ref.set({
      'userId': userId,
      ...eventData,
      'timestamp': ServerValue.timestamp,
    });
    return ref.key;
  }

  Future<void> updateSOSEvent(String sosId, Map<String, dynamic> updateData) async {
    if (!_isDbReady) return;
    await _db!.ref().child('sos_events').child(sosId).update(updateData);
  }
}
