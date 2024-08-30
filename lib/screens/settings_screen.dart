import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_screen.dart'; // Import the ProfileScreen for viewing/editing profile
import 'login_screen.dart'; // Import the LoginScreen for logging out

class SettingsScreen extends StatefulWidget {
  final String currentMode;
  final Function(String) onModeChange;

  SettingsScreen({required this.currentMode, required this.onModeChange});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isMonitoringOn; // Track the toggle state based on the current mode

  @override
  void initState() {
    super.initState();
    // Initialize the toggle state based on the current mode passed from HomeScreen
    isMonitoringOn = widget.currentMode != "Off";
  }

  // Function to handle user logout
  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    bool shouldLogout = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false), // User chose 'No'
            child: Text('No'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(true), // User chose 'Yes'
            child: Text('Yes'),
          ),
        ],
      ),
    );

    // If user confirms, perform logout
    if (shouldLogout) {
      try {
        await FirebaseAuth.instance.signOut(); // Sign out the user
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => LoginScreen()), // Navigate to login screen
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      } catch (e) {
        print('Logout failed: $e'); // Handle logout errors
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to log out. Please try again.'),
        ));
      }
    }
  }

  // Function to toggle monitoring mode
  void _toggleMonitoring(bool value) {
    setState(() {
      isMonitoringOn = value;
      String newMode = isMonitoringOn ? "Low" : "Off";
      widget.onModeChange(newMode); // Update the mode in HomeScreen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
              child: Text('View/Edit Profile'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20), // Space between buttons
            SwitchListTile(
              title: Text('Monitoring'),
              subtitle: Text(widget.currentMode == "High"
                  ? 'High Mode'
                  : (isMonitoringOn ? 'On (Low Mode)' : 'Off')),
              value: isMonitoringOn,
              onChanged: _toggleMonitoring, // Toggle the monitoring state
              activeColor: Colors.green,
              inactiveThumbColor: Colors.grey,
            ),
            SizedBox(height: 20), // Space between buttons
            ElevatedButton(
              onPressed: () {
                // Implement add contact functionality here
              },
              child: Text('Add Emergency Contact'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20), // Space between buttons
            ElevatedButton(
              onPressed: () => _logout(context), // Call the logout function
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
          ],
        ),
      ),
    );
  }
}
