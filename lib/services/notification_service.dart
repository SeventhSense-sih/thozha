import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final CollectionReference alertsCollection =
      FirebaseFirestore.instance.collection('alerts');
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      _firebaseMessaging.subscribeToTopic('high-alerts').then((_) {
        print('Subscribed to high-alerts topic');
      }).catchError((e) {
        print('Failed to subscribe to high-alerts topic: $e');
      });
    } else {
      print('User declined or has not accepted permission');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in foreground: ${message.notification?.body}');
      _showLocalNotification(
          message.notification?.title, message.notification?.body);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened with data: ${message.data}');
    });

    // Listen to Firestore for new alerts
    alertsCollection.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var alertData = change.doc.data()
              as Map<String, dynamic>?; // Cast to Map<String, dynamic>
          if (alertData != null) {
            _showLocalNotification(alertData['message'], 'New Alert');
          }
        }
      }
    });
  }

  Future<void> sendAlert(
      String message, double? latitude, double? longitude) async {
    try {
      await alertsCollection.add({
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print('Alert saved to Firestore.');
    } catch (e) {
      print('Failed to send alert: $e');
    }
  }

  void _showLocalNotification(String? title, String? body) {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_alerts_channel', // channel ID
      'High Alerts', // channel name
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    flutterLocalNotificationsPlugin.show(
      0, // notification ID
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
