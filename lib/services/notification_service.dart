import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> initialize() async {
    // Request permission for notifications
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

    // Configure foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in foreground: ${message.notification?.body}');
    });
  }

  Future<void> sendAlert(
      String message, double? latitude, double? longitude) async {
    try {
      // Save alert to Firestore for further processing and use
      await FirebaseFirestore.instance.collection('alerts').add({
        'message': message,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Fetch users within a 2 km radius
      QuerySnapshot querySnapshot = await usersCollection.get();
      for (var doc in querySnapshot.docs) {
        // Check if 'location' field exists
        if (doc.exists && doc['location'] != null) {
          GeoPoint userLocation = doc['location'];
          if (_isNearby(latitude, longitude, userLocation.latitude,
              userLocation.longitude)) {
            _sendNotificationToUser(doc.id, message);
          }
        } else {
          print('Location data not available for user: ${doc.id}');
        }
      }

      print('Alert sent successfully to nearby users.');
    } catch (e) {
      print('Failed to send alert: $e');
    }
  }

  bool _isNearby(double? lat1, double? lon1, double lat2, double lon2) {
    // Simple distance calculation to check if the user is within 2 km
    const double distanceThreshold = 2.0; // km
    double distance = _calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= distanceThreshold;
  }

  double _calculateDistance(
      double? lat1, double? lon1, double lat2, double lon2) {
    // Implement a simple formula to calculate distance between two lat/lon points
    // For simplicity, you can use the Haversine formula or similar
    // This is a placeholder function
    return 1.0; // Replace with actual distance calculation
  }

  void _sendNotificationToUser(String userId, String message) {
    _firebaseMessaging.subscribeToTopic(userId);
    // Send notification via FCM
    _firebaseMessaging.sendMessage(
      to: '/topics/$userId',
      data: {
        'title': 'Thozha Alert',
        'body': message,
      },
    );
  }
}
