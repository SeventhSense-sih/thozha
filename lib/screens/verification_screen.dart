import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class AdminVerificationScreen extends StatelessWidget {
  final CollectionReference verificationsCollection =
  FirebaseFirestore.instance.collection('verifications');

  final FirebaseAuth _auth = FirebaseAuth.instance; // Initialize FirebaseAuth

  // Function to fetch user details
  Future<Map<String, dynamic>> _getUserDetails(String userId) async {
    DocumentSnapshot userDoc =
    await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    }
    throw Exception('User not found');
  }

  // Function to show user details in a dialog
  Future<void> _showUserDetailsDialog(
      BuildContext context, String userId) async {
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
              borderRadius: BorderRadius.circular(20.0), // Rounded dialog
            ),
            title: Text(
              'User Verification Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Picture
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: Image.network(profilePicUrl, height: 100, width: 100),
                    ),
                  ),
                  SizedBox(height: 20),
                  // User Details
                  Text('Name: ${userDetails['name']}', style: TextStyle(fontSize: 16)),
                  Text('Gender: ${userDetails['gender']}', style: TextStyle(fontSize: 16)),
                  Text('Age: ${userDetails['age']}', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  // Proof Document Image
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
                  Navigator.pop(context); // Close the dialog
                },
                child: Text('Accept', style: TextStyle(color: Colors.green)),
              ),
              TextButton(
                onPressed: () {
                  _rejectVerification(context, userId);
                  Navigator.pop(context); // Close the dialog
                },
                child: Text('Reject', style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error fetching user details: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load user details. Please try again.'),
      ));
    }
  }

  Future<void> _approveVerification(BuildContext context, String userId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'isVerified': true,
          'verificationStatus': 'approved',
        });
        await FirebaseFirestore.instance
            .collection('verifications')
            .doc(userId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User verification approved.'),
        ));
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error approving verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to approve verification. Please try again.'),
      ));
    }
  }

  Future<void> _rejectVerification(BuildContext context, String userId) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'isVerified': false,
          'verificationStatus': 'rejected',
        });
        await FirebaseFirestore.instance
            .collection('verifications')
            .doc(userId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User verification rejected.'),
        ));
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      print('Error rejecting verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to reject verification. Please try again.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Verification',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Image.asset('assets/back_arrow.png'), // Custom back arrow icon
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: verificationsCollection
              .where('status', isEqualTo: 'pending')
              .snapshots(),
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
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    title: FutureBuilder<Map<String, dynamic>>(
                      future: _getUserDetails(verification.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text('Loading...', style: TextStyle(fontWeight: FontWeight.bold));
                        }
                        if (snapshot.hasError) {
                          return Text('Error loading name');
                        }
                        return Text(snapshot.data?['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold));
                      },
                    ),
                    subtitle: Text('Status: ${verification['status']}'),
                    trailing: IconButton(
                      icon: Icon(Icons.visibility, color: Colors.blueAccent),
                      onPressed: () => _showUserDetailsDialog(context, verification.id),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
