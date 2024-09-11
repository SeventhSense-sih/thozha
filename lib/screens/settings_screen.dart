import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_screen.dart'; // Import the ProfileScreen for viewing/editing profile
import 'contact_screen.dart'; // Import the contacts screen
import 'login_screen.dart';
import 'verify_identity.dart';
import 'verification_screen.dart'; // Import the AdminVerificationScreen

class SettingsScreen extends StatefulWidget {
  final String currentMode;
  final Function(String) onModeChange;

  SettingsScreen({required this.currentMode, required this.onModeChange});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isMonitoringOn;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    isMonitoringOn = widget.currentMode != "Off";
    currentUser = FirebaseAuth.instance.currentUser;
  }

  // Function to check if the current user is an admin from the 'admins' collection
  Future<bool> checkIfAdmin() async {
    if (currentUser != null) {
      // Check if the user's UID exists in the 'admins' collection with the 'role' field as 'admin'
      DocumentSnapshot adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(currentUser!.uid)
          .get();

      if (adminDoc.exists && adminDoc['role'] == 'admin') {
        return true;
      }
    }
    return false;
  }

  Future<void> _logout(BuildContext context) async {
    bool shouldLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldLogout) {
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } catch (e) {
        print('Logout failed: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to log out. Please try again.'),
        ));
      }
    }
  }

  void _toggleMonitoring(bool value) {
    setState(() {
      isMonitoringOn = value;
      String newMode = isMonitoringOn ? "Low" : "Off";
      widget.onModeChange(newMode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.white, // Consistent color scheme
        leading: IconButton(
          icon: Image.asset(
              'assets/back_arrow.png'), // Using a custom image for the back button
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // View/Edit Profile Button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: Text('View/Edit Profile'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.pinkAccent.shade100,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Toggle for Monitoring Mode
            Card(
              elevation: 2,
              child: SwitchListTile(
                title: Text('Monitoring'),
                subtitle: Text(widget.currentMode == "High"
                    ? 'High Mode'
                    : (isMonitoringOn ? 'On (Low Mode)' : 'Off')),
                value: isMonitoringOn,
                onChanged: _toggleMonitoring,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.grey,
              ),
            ),
            SizedBox(height: 20),

            // Manage Emergency Contacts Button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ContactsScreen()),
                );
              },
              child: Text('Manage Emergency Contacts'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.pinkAccent.shade100,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Verify Identity Button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => VerifyIdentityScreen()),
                );
              },
              child: Text('Verify Identity'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Logout Button
            ElevatedButton(
              onPressed: () => _logout(context),
              child: Text('Logout'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Admin Verification Button (only shown for admins)
            if (currentUser != null)
              FutureBuilder<bool>(
                future: checkIfAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasData && snapshot.data == true) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  AdminVerificationScreen()), // Push the verification screen
                        );
                      },
                      child: Text('Admin Verification'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                  return SizedBox();
                },
              ),
          ],
        ),
      ),
    );
  }
}
