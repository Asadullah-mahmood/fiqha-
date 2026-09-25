import 'package:adhan_dart/adhan_dart.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerTimeService {
  static CalculationParameters _getParameters(String? maslak) {
    if (maslak?.toLowerCase() == 'jafriya') {
      return CalculationMethodParameters.jafari();
    }

    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;

    return params;
  }

  static tz.Location _getTimezone(String timezone) {
    return tz.getLocation(timezone);
  }

  static Map<String, DateTime> getTodayPrayerTimes({
    required double latitude,
    required double longitude,
    required String timezone,
    String? maslak,
  }) {
    final params = _getParameters(maslak);

    final coordinates = Coordinates(latitude, longitude);

    final location = _getTimezone(timezone);

    // IMPORTANT:
    // Calculate using the local calendar date of the location.
    final localNow = tz.TZDateTime.now(location);

    final prayerTimes = PrayerTimes(
      date: localNow,
      coordinates: coordinates,
      calculationParameters: params,
      precision: true,
    );

    return {
      'Fajr': tz.TZDateTime.from(prayerTimes.fajr, location),
      'Sunrise': tz.TZDateTime.from(prayerTimes.sunrise, location),
      'Dhuhr': tz.TZDateTime.from(prayerTimes.dhuhr, location),
      'Asr': tz.TZDateTime.from(prayerTimes.asr, location),
      'Maghrib': tz.TZDateTime.from(prayerTimes.maghrib, location),
      'Isha': tz.TZDateTime.from(prayerTimes.isha, location),
    };
  }

  static MapEntry<String, DateTime>? getNextPrayer({
    required double latitude,
    required double longitude,
    required String timezone,
    String? maslak,
  }) {
    final params = _getParameters(maslak);
    final coordinates = Coordinates(latitude, longitude);
    final location = _getTimezone(timezone);

    final localNow = tz.TZDateTime.now(location);

    final prayerTimes = PrayerTimes(
      date: localNow,
      coordinates: coordinates,
      calculationParameters: params,
      precision: true,
    );

    final prayers = {
      'Fajr': tz.TZDateTime.from(prayerTimes.fajr, location),
      'Dhuhr': tz.TZDateTime.from(prayerTimes.dhuhr, location),
      'Asr': tz.TZDateTime.from(prayerTimes.asr, location),
      'Maghrib': tz.TZDateTime.from(prayerTimes.maghrib, location),
      'Isha': tz.TZDateTime.from(prayerTimes.isha, location),
    };

    for (final entry in prayers.entries) {
      if (entry.value.isAfter(localNow)) {
        return entry;
      }
    }

    // If all prayers passed today, next is Fajr tomorrow
    final tomorrow = localNow.add(const Duration(days: 1));
    final tomorrowTimes = PrayerTimes(
      date: tomorrow,
      coordinates: coordinates,
      calculationParameters: params,
      precision: true,
    );
    
    return MapEntry(
      'Fajr', 
      tz.TZDateTime.from(tomorrowTimes.fajr, location)
    );
  }
}
