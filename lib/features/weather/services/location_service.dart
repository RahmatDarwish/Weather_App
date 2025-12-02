import 'package:geolocator/geolocator.dart';

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}

class LocationService {
  Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw LocationException('Location services are OFF. Please enable GPS.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException('Permission denied. Please allow location.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Permission permanently denied. Enable it in app settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
