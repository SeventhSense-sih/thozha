// home_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../models/contact_model.dart';
import '../services/voice_recognition_service.dart';
import '../services/notification_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentMode = "Off";
  VoiceRecognitionService voiceService = VoiceRecognitionService();
  NotificationService notificationService = NotificationService();
  List<ContactModel> _contacts = [];

  @override
  void initState() {
    super.initState();
    notificationService.initialize();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsString = prefs.getString('contacts') ?? '[]';
    final List<dynamic> contactList = json.decode(contactsString);
    setState(() {
      _contacts = contactList
          .map((contact) => ContactModel(
                name: contact['name'],
                phoneNumber: contact['phoneNumber'],
              ))
          .toList();
    });
  }

  Future<void> _sendAlertToContacts() async {
    final alertMessage =
        "Alert! The user is in danger and needs immediate help.";

    for (var contact in _contacts) {
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: contact.phoneNumber,
        query: 'body=$alertMessage',
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        print(
            'Could not send SMS to ${contact.name} at ${contact.phoneNumber}');
      }
    }
  }

  void _changeMode(String mode) {
    setState(() {
      _currentMode = mode;
    });

    switch (mode) {
      case "Off":
        voiceService.stopListening();
        print("Monitoring turned off.");
        break;
      case "Low":
        voiceService.startListening((keyword) {
          print("Code word detected: $keyword");
          _changeMode("Medium");
        });
        print("Low-level monitoring activated.");
        break;
      case "Medium":
        voiceService.stopListening();
        _sendAlertToContacts(); // Send SMS alerts to contacts
        notificationService.sendAlert("Medium Alert: User needs help!");
        print("Medium mode activated. Sending alerts and monitoring.");
        break;
      case "High":
        voiceService.stopListening();
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
              Navigator.of(context)
                  .push(
                      MaterialPageRoute(builder: (context) => SettingsScreen()))
                  .then((_) {
                _loadContacts(); // Reload contacts when returning from settings
              });
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
