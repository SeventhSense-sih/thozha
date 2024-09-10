import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  Future<LocationData?> getCurrentLocation() async {
    try {
      bool _serviceEnabled = await _location.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await _location.requestService();
        if (!_serviceEnabled) {
          return null;
        }
      }

      PermissionStatus _permissionGranted = await _location.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await _location.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          return null;
        }
      }

      return await _location.getLocation();
    } catch (e) {
      print('Error fetching location: $e');
      return null;
    }
  }
}

