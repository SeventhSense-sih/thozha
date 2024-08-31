import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:thozha/screens/panic_screen.dart';

class NotificationsScreen extends StatelessWidget {
  final CollectionReference alertsCollection =
      FirebaseFirestore.instance.collection('alerts');

  void _showAlertDetails(BuildContext context, DocumentSnapshot alert) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Alert Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Display profile picture
                if (alert['userProfilePic'] != null) ...[
                  CircleAvatar(
                    backgroundImage: NetworkImage(alert['userProfilePic']),
                    radius: 40,
                  ),
                  SizedBox(height: 10),
                ],
                Text('Name: ${alert['userName']}'),
                Text('Age: ${alert['userAge']}'),
                Text('Gender: ${alert['userGender']}'),
                Text('Phone: ${alert['userPhone']}'),
                SizedBox(height: 10),
                Text('Message: ${alert['message']}'),
                Text('Latitude: ${alert['latitude']}'),
                Text('Longitude: ${alert['longitude']}'),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to the PanicScreen and pass the coordinates
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PanicScreen(
                          latitude: alert['latitude'],
                          longitude: alert['longitude'],
                        ),
                      ),
                    );
                  },
                  child: Text('Track Location'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

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
                onTap: () => _showAlertDetails(context, alert),
              );
            },
          );
        },
      ),
    );
  }
}
