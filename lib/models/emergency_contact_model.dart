class EmergencyContactModel {
  final String contactId;
  final String name;
  final String phone;

  EmergencyContactModel({
    required this.contactId,
    required this.name,
    required this.phone,
  });

  factory EmergencyContactModel.fromMap(Map<String, dynamic> map, String id) {
    return EmergencyContactModel(
      contactId: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
    };
  }
}
