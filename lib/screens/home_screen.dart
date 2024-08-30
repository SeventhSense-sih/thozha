import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:thozha/services/voice_recognition_service.dart';
import 'package:thozha/services/notification_service.dart';
import 'package:thozha/screens/settings_screen.dart'; // Import the SettingsScreen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VoiceRecognitionService voiceService = VoiceRecognitionService();
  NotificationService notificationService = NotificationService();

  Location _location = Location();
  LocationData? _currentLocation;
  String _currentMode = "Off"; // To display the current mode on the screen

  @override
  void initState() {
    super.initState();
    notificationService.initialize();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      _currentLocation = await _location.getLocation();
      setState(() {}); // Refresh the UI once location is fetched
    } catch (e) {
      print('Could not fetch location: $e');
    }
  }

  // Function to handle panic button press
  void _activatePanicMode() {
    setState(() {
      _currentMode = "High"; // Switch to High Mode
    });
    // Perform actions for high mode
    notificationService.sendAlert(
      "High Alert: Immediate assistance needed!",
      _currentLocation?.latitude,
      _currentLocation?.longitude,
    );
  }

  // Function to handle mode changes from settings
  void _changeMode(String mode) {
    setState(() {
      _currentMode = mode; // Update the mode
    });

    if (_currentMode == "Low") {
      // Start listening for voice commands in Low mode
      voiceService.startListening((keyword) {
        if (keyword == "danger") {
          // If the code word is detected, switch to High mode
          _activatePanicMode();
        }
      });
    } else {
      // Stop listening if not in Low mode
      voiceService.stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thozha - Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to the settings screen with current mode and callback
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    currentMode: _currentMode,
                    onModeChange: _changeMode,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Text(
              'Current Mode: $_currentMode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            bottom: 90, // Positioned above the panic button
            left: 28,
            right: 0,
            child: _currentLocation != null
                ? Text(
                    'Location: Lat: ${_currentLocation!.latitude}, Lon: ${_currentLocation!.longitude}',
                    style: TextStyle(fontSize: 16),
                  )
                : Text(
                    'Location: Not Available',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _activatePanicMode,
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(20),
                  backgroundColor: Colors.red, // Panic button color
                ),
                child: Text(
                  'Panic',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
