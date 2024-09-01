import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:thozha/services/voice_recognition_service.dart';
import 'package:thozha/services/notification_service.dart';
import 'package:thozha/screens/settings_screen.dart';
import 'package:thozha/screens/notification_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  Location _location = Location();
  LocationData? _currentLocation;
  VoiceRecognitionService voiceService = VoiceRecognitionService();
  NotificationService notificationService = NotificationService();
  String _currentMode = "Off"; // To display the current mode on the screen
  final LatLng _initialPosition =
  const LatLng(37.7749, -122.4194); // Default to San Francisco

  @override
  void initState() {
    super.initState();
    notificationService.initialize();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    // Check if location service is enabled
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    // Check for location permissions
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    // Fetch the current location
    try {
      _currentLocation = await _location.getLocation();
      setState(() {
        if (_currentLocation != null) {
          _mapController.moveCamera(CameraUpdate.newLatLng(
            LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          ));
        }
      });
    } catch (e) {
      print('Could not fetch location: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
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
        backgroundColor: Color(0xFFFDE8E8), // More light pink background color
        actions: [
          IconButton(
            icon: Image.asset('assets/notification.png'), // Notification image
            onPressed: () {
              // Navigate to the notifications screen
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: Image.asset('assets/settings.png'), // Settings image
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
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 10.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Current Mode: $_currentMode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _activatePanicMode,
        backgroundColor: Colors.red, // Panic button color
        icon: Image.asset(
          'assets/alert_icon.png', // Path to your custom alert icon
          height: 24, // Adjust size as necessary
          width: 24,
        ),
        label: Text(
          'Panic',
          style: TextStyle(color: Colors.white), // Set text color to white
        ), // Button label
      ),
    );
  }
}
