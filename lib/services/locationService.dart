import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;

class LocationInfo {
  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String timezone;

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    required this.timezone,
  });
}

class LocationService {
  static LocationInfo? _cachedLocation;

  static Future<LocationInfo> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    if (_cachedLocation != null && !forceRefresh) {
      return _cachedLocation!;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String city = 'Unknown City';
      String country = 'Unknown Country';

      try {
        final placemarks = await Geocoding().placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;

          city = place.locality?.isNotEmpty == true
              ? place.locality!
              : place.subAdministrativeArea?.isNotEmpty == true
              ? place.subAdministrativeArea!
              : place.administrativeArea ?? city;

          country = place.country?.isNotEmpty == true
              ? place.country!
              : country;
        }
      } catch (e) {
        debugPrint('Reverse geocoding failed: $e');
      }

      String timezone;

      try {
        timezone = tzmap.latLngToTimezoneString(
          position.latitude,
          position.longitude,
        );
      } catch (e) {
        debugPrint('Timezone lookup failed: $e');

        // Device timezone as a fallback.
        timezone = DateTime.now().timeZoneName;
      }

      final info = LocationInfo(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
        timezone: timezone,
      );

      _cachedLocation = info;

      return info;
    } catch (e) {
      debugPrint('Failed to get location: $e');

      rethrow;
    }
  }

  static void clearCache() {
    _cachedLocation = null;
  }
}
