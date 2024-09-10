import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:thozha/screens/notification_screen.dart';
import '../main.dart'; // Assuming this contains your `navigatorKey` and app initialization


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
      ThozhaApp.navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => NotificationsScreen()),
      );
    });

    alertsCollection.snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var alertData = change.doc.data() as Map<String, dynamic>?;
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
      // Fetch user details from the user's collection
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      Map<String, dynamic> userDetails = userDoc.data() as Map<String, dynamic>;

      // Save alert to Firestore with user details
      await alertsCollection.add({
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUser.uid, // Save user ID for reference
        'userName': userDetails['name'],
        'userAge': userDetails['age'],
        'userGender': userDetails['gender'],
        'userPhone': userDetails['phone'],
        'userProfilePic': userDetails[
        'profilePicture'], // Assuming this field stores the URL of the profile picture
      });

      print('Alert saved to Firestore with user details.');
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
      payload: 'navigateToNotificationsScreen', // Use payload to indicate navigation
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notifications')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('alerts').snapshots(), // Change from 'notifications' to 'alerts'
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var notification = snapshot.data!.docs[index];
              return ListTile(
                title: Text(notification['message']), // Title is the alert message
                subtitle: Text(notification['timestamp']
                    .toDate()
                    .toString()), // You can format timestamp if needed
                onTap: () {
                  // Open details or Google Maps based on notification
                  _openNotificationDialog(context, notification);
                },
              );
            },
          );
        },
      ),
    );
  }

  void _openNotificationDialog(BuildContext context, DocumentSnapshot notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(notification['message']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Location: ${notification['latitude']}, ${notification['longitude']}'),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _openGoogleMaps(notification['latitude'], notification['longitude']);
                },
                child: Text('Open Google Maps'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _openGoogleMaps(double latitude, double longitude) {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    // Use url_launcher to open the Google Maps URL
    // You need to include url_launcher package in pubspec.yaml
  }
}
