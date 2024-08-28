import 'package:flutter/material.dart';
import 'package:thozha/services/sensor_service.dart';
import 'package:thozha/services/voice_recognition_service.dart';
import 'package:thozha/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestMicrophonePermission() async {
  var status = await Permission.microphone.status;
  if (!status.isGranted) {
    status = await Permission.microphone.request();
    if (status.isGranted) {
      print("Microphone permission granted.");
    } else {
      print("Microphone permission denied.");
    }
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentMode = "Off"; // Initial mode is "Off"
  SensorService sensorService = SensorService();
  VoiceRecognitionService voiceService = VoiceRecognitionService();
  NotificationService notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    notificationService.initialize(); // Initialize notifications
  }

  void _changeMode(String mode) {
    setState(() {
      _currentMode = mode;
    });

    switch (mode) {
      case "Off":
        // Stop monitoring
        sensorService.disconnectFromDevice();
        voiceService.stopListening();
        print("Monitoring turned off.");
        break;
      case "Low":
        // Start low-level monitoring
        requestMicrophonePermission().then((_) async {
          if (await Permission.microphone.isGranted) {
            await voiceService
                .initialize(); // Ensure voice service is initialized
            sensorService.connectToWatch();
            voiceService.startListening((keyword) {
              print("Code word detected: $keyword");
              _changeMode("Medium");
            });
            print("Low-level monitoring activated.");
          } else {
            print("Microphone permission not granted.");
          }
        });
        break;
      case "Medium":
        // Send alerts, start recording, etc.
        notificationService.sendAlert("Medium Alert: User needs help!");
        print("Medium mode activated. Sending alerts and monitoring.");
        break;
      case "High":
        // Frequent alerts, alarm triggers, etc.
        notificationService
            .sendAlert("High Alert: Immediate assistance needed!");
        print("High mode activated. Immediate alerts and alarms.");
        break;
      default:
        break;
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
              // Navigate to settings screen if needed
              print("Navigating to settings.");
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Mode: $_currentMode',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
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
          ],
        ),
      ),
    );
  }
}
