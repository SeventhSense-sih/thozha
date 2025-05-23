import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart'; // Import SplashScreen
import 'screens/notification_screen.dart'; // Import the NotificationsScreen
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Create an instance of FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  _showLocalNotification(
      message.notification?.title, message.notification?.body);
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
    payload:
    'navigateToNotificationsScreen', // Use payload to indicate navigation
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == 'navigateToNotificationsScreen') {
        ThozhaApp.navigatorKey.currentState!.push(
          MaterialPageRoute(builder: (context) => NotificationsScreen()),
        );
      }
    },
  );

  await initializeFirebaseMessaging();

  runApp(ThozhaApp());
}

class ThozhaApp extends StatelessWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,  // This removes the debug banner
      title: 'Thozha',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashScreen(), // Set SplashScreen as the initial screen
      navigatorKey: navigatorKey, // Add a navigator key for navigation
    );
  }
}

// Initialize Firebase Messaging and handle subscriptions
Future<void> initializeFirebaseMessaging() async {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  NotificationSettings settings = await _firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else {
    print('User declined or has not accepted permission');
  }

  String? token = await _firebaseMessaging.getToken();
  print("FCM Token: $token");

  _firebaseMessaging.subscribeToTopic('high-alerts').then((_) {
    print('Successfully subscribed to topic: high-alerts');
  }).catchError((e) {
    print('Failed to subscribe to topic: $e');
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Message received in foreground: ${message.notification?.body}');
    _showLocalNotification(
        message.notification?.title, message.notification?.body);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('Notification opened with data: ${message.data}');
    // Navigate to NotificationsScreen when a notification is tapped
    ThozhaApp.navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (context) => NotificationsScreen()),
    );
  });
}
