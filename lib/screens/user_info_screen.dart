import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoScreen extends StatefulWidget {
  @override
  _UserInfoScreenState createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');

  void _saveUserInfo() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await usersCollection.doc(currentUser.uid).set({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'isVerified': false,  // Default as not verified
          'verificationStatus': 'pending'
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User info saved successfully.')));
      }
    } catch (e) {
      print('Error saving user info: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save user info.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Information'),
        actions: [
          IconButton(
            icon: Icon(Icons.admin_panel_settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminVerificationScreen()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveUserInfo,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminVerificationScreen extends StatelessWidget {
  final CollectionReference verificationsCollection = FirebaseFirestore.instance.collection('verifications');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> _getUserDetails(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    throw Exception('User not found');
  }

  Future<void> _showUserDetailsDialog(BuildContext context, String userId) async {
    try {
      Map<String, dynamic> userDetails = await _getUserDetails(userId);
      String profilePicUrl = await FirebaseStorage.instance
          .ref('profile_pictures/$userId.jpg')
          .getDownloadURL();
      String proofDocUrl = await FirebaseStorage.instance
          .ref('verification_docs/$userId.jpg')
          .getDownloadURL();

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            title: Text(
              'User Verification Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(profilePicUrl, height: 100, width: 100),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Name: ${userDetails['name']}', style: TextStyle(fontSize: 16)),
                  Text('Gender: ${userDetails['gender']}', style: TextStyle(fontSize: 16)),
                  Text('Age: ${userDetails['age']}', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(proofDocUrl, height: 200, width: 200),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _approveVerification(context, userId);
                  Navigator.pop(context);
                },
                child: Text('Accept', style: TextStyle(color: Colors.green)),
              ),
              TextButton(
                onPressed: () {
                  _rejectVerification(context, userId);
                  Navigator.pop(context);
                },
                child: Text('Reject', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error fetching user details: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load user details.')));
    }
  }

  Future<void> _approveVerification(BuildContext context, String userId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'isVerified': true,
          'verificationStatus': 'approved',
        });
        await verificationsCollection.doc(userId).delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User verification approved.')));
      }
    } catch (e) {
      print('Error approving verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to approve verification.')));
    }
  }

  Future<void> _rejectVerification(BuildContext context, String userId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'isVerified': false,
          'verificationStatus': 'rejected',
        });
        await verificationsCollection.doc(userId).delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User verification rejected.')));
      }
    } catch (e) {
      print('Error rejecting verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to reject verification.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Verification'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: verificationsCollection.where('status', isEqualTo: 'pending').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final verifications = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: verifications.length,
            itemBuilder: (context, index) {
              final verification = verifications[index];
              return Card(
                child: ListTile(
                  title: FutureBuilder<Map<String, dynamic>>(
                    future: _getUserDetails(verification.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Loading...');
                      }
                      return Text(snapshot.data?['name'] ?? 'Unknown');
                    },
                  ),
                  subtitle: Text('Status: ${verification['status']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.visibility),
                    onPressed: () => _showUserDetailsDialog(context, verification.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
