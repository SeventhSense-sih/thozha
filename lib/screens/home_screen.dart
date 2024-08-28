
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentMode = "Off"; // Initial mode is "Off"

  void _changeMode(String mode) {
    setState(() {
      _currentMode = mode;
    });

    // Handle the mode change with the necessary actions
    switch (mode) {
      case "Off":
        print("Monitoring turned off.");
        break;
      case "Low":
        print("Low-level monitoring activated.");
        break;
      case "Medium":
        print("Medium mode activated. Sending alerts and monitoring.");
        break;
      case "High":
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
