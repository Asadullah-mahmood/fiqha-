import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quranpak/services/AzanService.dart';
import 'package:quranpak/services/prayerTimer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('calculates reminder times for Sunnah and Nawafil prayers', () {
    final prayers = {
      'Fajr': DateTime(2026, 10, 8, 5),
      'Sunrise': DateTime(2026, 10, 8, 6),
      'Dhuhr': DateTime(2026, 10, 8, 12),
      'Maghrib': DateTime(2026, 10, 8, 18),
      'Isha': DateTime(2026, 10, 8, 20),
    };

    final reminders = PrayerTimeService.getSunnahPrayerTimes(prayers);

    expect(reminders['Tahajjud'], DateTime(2026, 10, 8, 3));
    expect(reminders['Witr'], DateTime(2026, 10, 8, 21));
    expect(reminders['Ishraq'], DateTime(2026, 10, 8, 6, 15));
    expect(reminders['Duha (Chasht)'], DateTime(2026, 10, 8, 9));
    expect(reminders['Awwabin'], DateTime(2026, 10, 8, 18, 20));
  });

  test('identifies the prayer interval that contains the current time including Shuruq/Sunrise rule', () {
    final prayers = {
      'Fajr': DateTime(2026, 10, 8, 5),
      'Sunrise': DateTime(2026, 10, 8, 6),
      'Dhuhr': DateTime(2026, 10, 8, 12),
      'Asr': DateTime(2026, 10, 8, 15),
      'Maghrib': DateTime(2026, 10, 8, 18),
      'Isha': DateTime(2026, 10, 8, 20),
    };

    // Between Fajr (5:00) and Sunrise (6:00) -> Fajr
    expect(
      PrayerTimeService.getCurrentPrayerName(
        prayerTimes: prayers,
        now: DateTime(2026, 10, 8, 5, 30),
      ),
      'Fajr',
    );

    // After Sunrise (6:00) until Dhuhr (12:00) -> null (no prayer indicated)
    expect(
      PrayerTimeService.getCurrentPrayerName(
        prayerTimes: prayers,
        now: DateTime(2026, 10, 8, 9, 0),
      ),
      isNull,
    );

    // Dhuhr (12:00) -> Dhuhr
    expect(
      PrayerTimeService.getCurrentPrayerName(
        prayerTimes: prayers,
        now: DateTime(2026, 10, 8, 12, 10),
      ),
      'Dhuhr',
    );

    // Asr (15:00) -> Asr
    expect(
      PrayerTimeService.getCurrentPrayerName(
        prayerTimes: prayers,
        now: DateTime(2026, 10, 8, 16, 0),
      ),
      'Asr',
    );

    // Isha (20:00) -> Isha
    expect(
      PrayerTimeService.getCurrentPrayerName(
        prayerTimes: prayers,
        now: DateTime(2026, 10, 8, 21, 0),
      ),
      'Isha',
    );
  });

  test('nawafil alarms are off by default and fard alarms are on', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await AzanService.isPrayerSelected('Tahajjud'), isFalse);
    expect(await AzanService.isPrayerSelected('Fajr'), isTrue);
  });
}
