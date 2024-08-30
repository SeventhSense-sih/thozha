// lib/models/contact_model.dart
class ContactModel {
  String name;
  String phoneNumber;

  ContactModel({required this.name, required this.phoneNumber});

  // Convert a ContactModel to a Map for storage
  Map<String, String> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  // Create a ContactModel from a Map
  factory ContactModel.fromMap(Map<String, String> map) {
    return ContactModel(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }
}
