import 'dart:convert';
import 'package:http/http.dart' as http; // Correct import for HTTP requests
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Request permission for iOS devices (required for receiving notifications)
  Future<void> requestNotificationPermissions() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('User denied permission');
    }
  }

  // Notify contacts and nearby users by sending data to a backend service
  Future<void> notifyContactsAndNearbyUsers(double latitude, double longitude) async {
    // Fetch saved contacts from Firestore
    List<DocumentSnapshot> contacts = await _getSavedContacts();

    // Collect all FCM tokens of saved contacts
    List<String> tokens = contacts.map((contact) => contact['fcmToken'].toString()).toList();

    // Fetch nearby users' tokens
    List<DocumentSnapshot> nearbyUsers = await _getNearbyUsers(latitude, longitude);
    tokens.addAll(nearbyUsers.map((user) => user['fcmToken'].toString()).toList());

    // Send notification data to backend
    await _sendNotificationDataToBackend(tokens, 'Emergency Alert', 'Please assist immediately.');
  }

  // This method sends the token list and message data to a server for processing
  Future<void> _sendNotificationDataToBackend(List<String> tokens, String title, String body) async {
    // Use an HTTP request to send data to the backend
    final response = await http.post(
      Uri.parse('https://<your-cloud-function-url>/sendNotification'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'tokens': tokens,
        'title': title,
        'body': body,
      }),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  }

  Future<List<DocumentSnapshot>> _getSavedContacts() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('contacts').get();
    return snapshot.docs;
  }

  Future<List<DocumentSnapshot>> _getNearbyUsers(double latitude, double longitude) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
    return snapshot.docs;  // Filter nearby users based on location.
  }

  // Initialize Firebase Messaging
  void initializeFirebaseMessaging() async {
    // Get FCM token for the device
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Listen for incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a message while the app is in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });

    // Handle background message processing
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
    });
  }
}
