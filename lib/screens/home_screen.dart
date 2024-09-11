import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:thozha/services/voice_recognition_service.dart';
import 'package:thozha/services/notification_service.dart' as notifService; // Use a prefix
import 'package:thozha/screens/settings_screen.dart';
import 'package:thozha/screens/notification_screen.dart' as notifScreen; // Use a prefix

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapController;
  Location _location = Location();
  LocationData? _currentLocation;
  VoiceRecognitionService voiceService = VoiceRecognitionService();
  notifService.NotificationService notificationService = notifService.NotificationService();
  String _currentMode = "Off"; // To display the current mode on the screen
  final LatLng _initialPosition = const LatLng(37.7749, -122.4194); // Default to San Francisco

  @override
  void initState() {
    super.initState();
    notificationService.initialize();
    _getLocation();
  }

  Future<void> _getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

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

  void _activatePanicMode() {
    setState(() {
      _currentMode = "High";
    });
    notificationService.sendAlert(
      "High Alert: Immediate assistance needed!",
      _currentLocation?.latitude,
      _currentLocation?.longitude,
    );
  }

  void _changeMode(String mode) {
    setState(() {
      _currentMode = mode;
    });

    if (_currentMode == "Low") {
      voiceService.startListening((keyword) {
        if (keyword == "danger") {
          _activatePanicMode();
        }
      });
    } else {
      voiceService.stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thozha - Home', style: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color(0xFFB71C1C), // Rich dark red for the app bar
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white, size: 30),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => notifScreen.NotificationsScreen()), // Use prefix for notification screen
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 30),
            onPressed: () {
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
            myLocationButtonEnabled: false, // Hides default button for cleaner UI
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade600,
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: Offset(4, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.yellowAccent, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Current Mode: $_currentMode',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _activatePanicMode,
        backgroundColor: Colors.redAccent, // Red for panic button
        icon: Icon(Icons.error_outline, color: Colors.white, size: 28),
        label: Text(
          'Panic',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
