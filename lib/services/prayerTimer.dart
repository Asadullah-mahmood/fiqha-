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
    final location = _getTimezone(timezone);
    return getPrayerTimesForDate(
      date: tz.TZDateTime.now(location),
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      maslak: maslak,
    );
  }

  static Map<String, DateTime> getPrayerTimesForDate({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String timezone,
    String? maslak,
  }) {
    final params = _getParameters(maslak);
    final coordinates = Coordinates(latitude, longitude);
    final location = _getTimezone(timezone);
    final localDate = tz.TZDateTime(location, date.year, date.month, date.day);

    final prayerTimes = PrayerTimes(
      date: localDate,
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

  static Map<String, DateTime> getSunnahPrayerTimes(
    Map<String, DateTime> prayers,
  ) {
    final fajr = prayers['Fajr'];
    final isha = prayers['Isha'];
    final sunrise = prayers['Sunrise'];
    final dhuhr = prayers['Dhuhr'];
    final maghrib = prayers['Maghrib'];
    final sunnah = <String, DateTime>{};

    if (fajr != null) {
      sunnah['Tahajjud'] = fajr.subtract(const Duration(hours: 2));
    }
    if (isha != null) {
      sunnah['Witr'] = isha.add(const Duration(hours: 1));
    }
    if (sunrise != null) {
      sunnah['Ishraq'] = sunrise.add(const Duration(minutes: 15));
    }
    if (sunrise != null && dhuhr != null) {
      sunnah['Duha (Chasht)'] = sunrise.add(
        Duration(minutes: dhuhr.difference(sunrise).inMinutes ~/ 2),
      );
    }
    if (maghrib != null) {
      sunnah['Awwabin'] = maghrib.add(const Duration(minutes: 20));
    }
    return sunnah;
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
      'Sunrise': tz.TZDateTime.from(prayerTimes.sunrise, location),
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

    return MapEntry('Fajr', tz.TZDateTime.from(tomorrowTimes.fajr, location));
  }

  static String? getCurrentPrayerName({
    required Map<String, DateTime> prayerTimes,
    required DateTime now,
  }) {
    final fajr = prayerTimes['Fajr'];
    final sunrise = prayerTimes['Sunrise'];
    final dhuhr = prayerTimes['Dhuhr'];
    final asr = prayerTimes['Asr'];
    final maghrib = prayerTimes['Maghrib'];
    final isha = prayerTimes['Isha'];

    if (fajr == null) return null;

    if (now.isBefore(fajr)) return 'Isha';

    if (sunrise != null && !now.isBefore(fajr) && now.isBefore(sunrise)) {
      return 'Fajr';
    }

    if (sunrise != null && dhuhr != null && !now.isBefore(sunrise) && now.isBefore(dhuhr)) {
      return null;
    }

    if (dhuhr != null && asr != null && !now.isBefore(dhuhr) && now.isBefore(asr)) {
      return 'Dhuhr';
    }

    if (asr != null && maghrib != null && !now.isBefore(asr) && now.isBefore(maghrib)) {
      return 'Asr';
    }

    if (maghrib != null && isha != null && !now.isBefore(maghrib) && now.isBefore(isha)) {
      return 'Maghrib';
    }

    if (isha != null && !now.isBefore(isha)) {
      return 'Isha';
    }

    return 'Isha';
  }
}
