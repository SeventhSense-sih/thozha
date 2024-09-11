import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactsScreen extends StatefulWidget {
  @override
  _ContactsScreenState createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final CollectionReference contactsCollection = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser?.uid)
      .collection('contacts');

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  void _addOrUpdateContact(String? id) {
    if (_nameController.text.isNotEmpty &&
        _relationController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty) {
      if (id == null) {
        contactsCollection.add({
          'name': _nameController.text,
          'relation': _relationController.text,
          'phoneNumber': _phoneController.text,
        });
      } else {
        contactsCollection.doc(id).update({
          'name': _nameController.text,
          'relation': _relationController.text,
          'phoneNumber': _phoneController.text,
        });
      }
      Navigator.of(context).pop();
    }
  }

  void _deleteContact(String id) {
    contactsCollection.doc(id).delete();
  }

  void _showContactDialog(
      [String? id, String? name, String? relation, String? phoneNumber]) {
    if (id != null) {
      _nameController.text = name!;
      _relationController.text = relation!;
      _phoneController.text = phoneNumber!;
    } else {
      _nameController.clear();
      _relationController.clear();
      _phoneController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          id == null ? 'Add Contact' : 'Edit Contact',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Contact Name',
                filled: true,
                fillColor: Colors.grey[200], // Light background for text field
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _relationController,
              decoration: InputDecoration(
                labelText: 'Relation',
                filled: true,
                fillColor: Colors.grey[200], // Light background for text field
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                filled: true,
                fillColor: Colors.grey[200], // Light background for text field
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => _addOrUpdateContact(id),
            child: Text(
              'Save',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emergency Contacts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent, // Applied color from design one
        leading: IconButton(
          icon: Image.asset('assets/back_arrow.png'), // Custom back arrow icon
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: contactsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final contacts = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  title: Text(
                    contact['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Text(
                    '${contact['relation']} - ${contact['phoneNumber']}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Image.asset(
                          'assets/edit_icon.png',
                          height: 24,
                          width: 24,
                        ), // Custom edit icon
                        onPressed: () => _showContactDialog(
                          contact.id,
                          contact['name'],
                          contact['relation'],
                          contact['phoneNumber'],
                        ),
                      ),
                      IconButton(
                        icon: Image.asset(
                          'assets/delete_icon.png',
                          height: 24,
                          width: 24,
                        ), // Custom delete icon
                        onPressed: () => _deleteContact(contact.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactDialog(),
        child: Icon(Icons.add, size: 28, color: Colors.white), // Used Icon instead of Image
        backgroundColor: Colors.redAccent, // Applied color from design one
        elevation: 6,
      ),
    );
  }
}
