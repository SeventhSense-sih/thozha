// home_screen.dart
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:thozha/services/voice_recognition_service.dart';
import 'package:thozha/services/notification_service.dart';

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

    _currentLocation = await _location.getLocation();
    setState(() {}); // Refresh the UI once location is fetched
  }

  Future<void> _changeMode(String mode) async {
    setState(() {
      _currentMode = mode; // Update mode display
    });

    switch (mode) {
      case "Off":
        voiceService.stopListening();
        break;
      case "Low":
        voiceService.startListening((keyword) {
          print("Code word detected: $keyword");
          _changeMode("Medium");
        });
        break;
      case "Medium":
        voiceService.stopListening();
        notificationService.sendAlert("Medium Alert: User needs help!");
        break;
      case "High":
        voiceService.stopListening();
        notificationService
            .sendAlert("High Alert: Immediate assistance needed!");
        break;
    }
  }

  Widget _locationButton() {
    if (_currentLocation != null) {
      return ElevatedButton(
        onPressed: () {}, // Define an appropriate action for location button
        child: Text(
            'Location: Lat: ${_currentLocation!.latitude}, Lon: ${_currentLocation!.longitude}'),
      );
    } else {
      return SizedBox
          .shrink(); // Render an empty box if location is not available
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thozha - Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Current Mode: $_currentMode', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _changeMode("Off"),
              child: Text('Turn Off Monitoring'),
            ),
            ElevatedButton(
              onPressed: () => _changeMode("Low"),
              child: Text('Activate Low Mode'),
            ),
            ElevatedButton(
              onPressed: () => _changeMode("Medium"),
              child: Text('Activate Medium Mode'),
            ),
            ElevatedButton(
              onPressed: () => _changeMode("High"),
              child: Text('Activate High Mode'),
            ),
            _locationButton(),
          ],
        ),
      ),
    );
  }
}
