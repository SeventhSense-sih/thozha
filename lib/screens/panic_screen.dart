import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

class PanicScreen extends StatefulWidget {
  final double victimLatitude;
  final double victimLongitude;

  const PanicScreen({Key? key, required this.victimLatitude, required this.victimLongitude})
      : super(key: key);

  @override
  _PanicScreenState createState() => _PanicScreenState();
}

class _PanicScreenState extends State<PanicScreen> {
  late GoogleMapController mapController;
  LocationData? currentLocation;

  // Method to initialize the Google Map controller
  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _getCurrentLocation();
  }

  // Method to get the current location of the user
  Future<void> _getCurrentLocation() async {
    Location location = Location();
    currentLocation = await location.getLocation();
    setState(() {});
  }

  // Method to launch Google Maps with directions from current location to victim's location
  Future<void> _launchMaps() async {
    if (currentLocation != null) {
      final url =
          'https://www.google.com/maps/dir/?api=1&origin=${currentLocation!.latitude},${currentLocation!.longitude}&destination=${widget.victimLatitude},${widget.victimLongitude}&travelmode=driving';
      if (await canLaunch(url)) {
        await launch(url);
      } else {
        throw 'Could not launch $url';
      }
    } else {
      // Handle the case where the current location is not available
      print('Current location is not available');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to get current location. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panic Location'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.victimLatitude, widget.victimLongitude),
                zoom: 15.0,
              ),
              markers: {
                // Marker for victim's location
                Marker(
                  markerId: MarkerId('panicLocation'),
                  position: LatLng(widget.victimLatitude, widget.victimLongitude),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
                // Marker for current location if available
                if (currentLocation != null)
                  Marker(
                    markerId: MarkerId('currentLocation'),
                    position: LatLng(currentLocation!.latitude!, currentLocation!.longitude!),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue),
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
