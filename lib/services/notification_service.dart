// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'contact_service.dart';
import '../models/contact_model.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final ContactService contactService = ContactService();

  Future<void> initialize() async {
    // Request permissions for iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          print('Notification payload: ${response.payload}');
          // Handle the payload action
        }
      },
    );

    // Listen to messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received a foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
  }

  Future<void> sendAlert(
      String message, double? latitude, double? longitude) async {
    // Save alert details with location to Firestore
    try {
      CollectionReference alerts =
          FirebaseFirestore.instance.collection('alerts');
      await alerts.add({
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Alert sent: $message with location: ($latitude, $longitude)');

      // Fetch emergency contacts
      List<ContactModel> contacts = await contactService.loadContacts();
      for (ContactModel contact in contacts) {
        await _sendSms(contact.phoneNumber, message, latitude, longitude);
      }
    } catch (e) {
      print('Failed to send alert: $e');
    }
  }

  Future<void> _sendSms(String phoneNumber, String message, double? latitude,
      double? longitude) async {
    String smsMessage =
        '$message\nLocation: https://www.google.com/maps?q=$latitude,$longitude';
    String url = 'sms:$phoneNumber?body=${Uri.encodeComponent(smsMessage)}';

    // Use canLaunchUrl instead of canLaunch
    if (await canLaunchUrl(Uri.parse(url))) {
      // Use launchUrl instead of launch
      await launchUrl(Uri.parse(url));
    } else {
      print('Could not launch $url');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data['payload'],
    );
  }
}
