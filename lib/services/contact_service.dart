// lib/services/contact_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/contact_model.dart';

class ContactService {
  static const String _contactsKey = 'emergency_contacts';

  // Save contacts to SharedPreferences
  Future<void> saveContacts(List<ContactModel> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson =
        contacts.map((contact) => jsonEncode(contact.toMap())).toList();
    prefs.setStringList(_contactsKey, contactsJson);
  }

  // Load contacts from SharedPreferences
  Future<List<ContactModel>> loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = prefs.getStringList(_contactsKey) ?? [];
    return contactsJson
        .map((contact) => ContactModel.fromMap(jsonDecode(contact)))
        .toList();
  }

  // Add a single contact
  Future<void> addContact(ContactModel contact) async {
    final contacts = await loadContacts();
    contacts.add(contact);
    await saveContacts(contacts);
  }

  // Remove a single contact
  Future<void> removeContact(String phoneNumber) async {
    final contacts = await loadContacts();
    contacts.removeWhere((contact) => contact.phoneNumber == phoneNumber);
    await saveContacts(contacts);
  }
}
