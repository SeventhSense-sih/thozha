import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PanicScreen extends StatefulWidget {
  final double latitude;
  final double longitude;

  const PanicScreen({Key? key, required this.latitude, required this.longitude})
      : super(key: key);

  @override
  _PanicScreenState createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  late GoogleMapController mapController;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _launchMaps() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&origin=${widget.latitude},${widget.longitude}&destination=${widget.latitude},${widget.longitude}&travelmode=driving';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panic Location'),
        leading: IconButton(
          icon: Image.asset('assets/back_arrow.png'), // Custom back arrow icon
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.latitude, widget.longitude),
                zoom: 15.0,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('panicLocation'),
                  position: LatLng(widget.latitude, widget.longitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _launchMaps,
              child: Text('Save the Victim'),
            ),
          ),
        ],
      ),
    );
  }
}
