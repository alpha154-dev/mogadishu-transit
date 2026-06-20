import 'package:geolocator/geolocator.dart';
import '../models/stop.dart';

class LocationService {
  /// Requests permission if needed and returns the current position.
  /// Throws an exception with a clear message if location can't be obtained.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Enable it in app settings.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Returns the stop closest to the given position, with its distance in meters.
  ({Stop stop, double distanceMeters}) findNearestStop(
      Position position,
      List<Stop> stops,
      ) {
    Stop? nearest;
    double nearestDistance = double.infinity;

    for (final stop in stops) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        stop.latitude,
        stop.longitude,
      );
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = stop;
      }
    }

    if (nearest == null) {
      throw Exception('No stops available.');
    }

    return (stop: nearest, distanceMeters: nearestDistance);
  }
}