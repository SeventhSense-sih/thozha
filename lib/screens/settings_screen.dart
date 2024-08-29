// settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/contact_model.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<ContactModel> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsString = prefs.getString('contacts') ?? '[]';
    final List<dynamic> contactList = json.decode(contactsString);
    setState(() {
      _contacts = contactList
          .map((contact) => ContactModel(
                name: contact['name'],
                phoneNumber: contact['phoneNumber'],
              ))
          .toList();
    });
  }

  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsString = json.encode(_contacts
        .map((contact) => {
              'name': contact.name,
              'phoneNumber': contact.phoneNumber,
            })
        .toList());
    prefs.setString('contacts', contactsString);
  }

  void _addContact(ContactModel contact) {
    setState(() {
      _contacts.add(contact);
    });
    _saveContacts();
  }

  void _removeContact(ContactModel contact) {
    setState(() {
      _contacts.remove(contact);
    });
    _saveContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                final newContact = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AddContactScreen()),
                );
                if (newContact != null) {
                  _addContact(newContact);
                }
              },
              child: Text('Add Contact'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return ListTile(
                    title: Text(contact.name),
                    subtitle: Text(contact.phoneNumber),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _removeContact(contact),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddContactScreen extends StatelessWidget {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Contact')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final contact = ContactModel(
                  name: _nameController.text,
                  phoneNumber: _phoneController.text,
                );
                Navigator.of(context).pop(contact);
              },
              child: Text('Save Contact'),
            ),
          ],
        ),
      ),
    );
  }
}
