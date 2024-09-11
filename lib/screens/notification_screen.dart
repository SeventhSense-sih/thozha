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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            'Alert Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (alert['userProfilePic'] != null) ...[
                  CircleAvatar(
                    backgroundImage: NetworkImage(alert['userProfilePic']),
                    radius: 40,
                  ),
                  SizedBox(height: 10),
                ],
                _buildDetailRow('Name', alert['userName']),
                _buildDetailRow('Age', alert['userAge']),
                _buildDetailRow('Gender', alert['userGender']),
                _buildDetailRow('Phone', alert['userPhone']),
                SizedBox(height: 10),
                _buildDetailRow('Message', alert['message']),
                _buildDetailRow('Latitude', alert['latitude']),
                _buildDetailRow('Longitude', alert['longitude']),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    final double? latitude = alert['latitude']?.toDouble();
                    final double? longitude = alert['longitude']?.toDouble();
                    if (latitude != null && longitude != null) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => PanicScreen(
                            victimLatitude: latitude,
                            victimLongitude: longitude,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invalid location data. Unable to track.'),
                        ),
                      );
                    }
                  },
                  child: Text('Track Location'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              '$value',
              style: TextStyle(color: Colors.black87, fontSize: 16),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: Image.asset('assets/back_arrow.png'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: alertsCollection.orderBy('timestamp', descending: true).snapshots(),
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
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  title: Text(
                    alert['message'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Location: ${alert['latitude']}, ${alert['longitude']}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey),
                  onTap: () => _showAlertDetails(context, alert),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
