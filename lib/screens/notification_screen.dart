import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  final CollectionReference alertsCollection =
      FirebaseFirestore.instance.collection('alerts');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            alertsCollection.orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final alert = notifications[index];
              return ListTile(
                title: Text(alert['message']),
                subtitle: Text(
                    'Location: ${alert['latitude']}, ${alert['longitude']}'),
              );
            },
          );
        },
      ),
    );
  }
}
