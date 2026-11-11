import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quranpak/services/prayerTimer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class AzanService {
  static const String _channelId = 'azan_alarm_channel_v2';
  static const String _channelName = 'Azan Alarm';
  static const String _channelDesc = 'Prayer-time Azan and Namaz reminders';
  static const String _enabledKey = 'namaz_alarm_enabled';
  static const String _prayerAlarmPrefix = 'namaz_alarm_';
  static const int _baseId = 2000;
  static int get _daysToSchedule => Platform.isIOS ? 6 : 30;
  static const int _slotsPerDay = 11;

  static AudioPlayer? _audioPlayer;

  static const List<String> prayers = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];
  static const List<String> nawafil = [
    'Tahajjud',
    'Witr',
    'Ishraq',
    'Duha (Chasht)',
    'Awwabin',
  ];
  static const String jummah = 'Jummah';

  static bool defaultAlarmEnabled(String prayer) => !nawafil.contains(prayer);

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('azan'),
        enableVibration: true,
        ongoing: false,
        autoCancel: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(''),
      );

  static const DarwinNotificationDetails _iosDetails =
      DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'azan.mp3',
      );

  static Future<void> init(FlutterLocalNotificationsPlugin plugin) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
      },
    );

    if (Platform.isAndroid) {
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      try {
        await android?.deleteNotificationChannel(channelId: 'azan_channel_v1');
      } catch (_) {}

      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('azan'),
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        ),
      );
    }
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final plugin = FlutterLocalNotificationsPlugin();
      final android = plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      bool notificationsAllowed = true;
      try {
        final granted = await android?.requestNotificationsPermission();
        if (granted != null) {
          notificationsAllowed = granted;
        }
      } catch (e) {
        debugPrint('requestNotificationsPermission error: $e');
      }

      // Check / request exact alarms permission
      try {
        final canExact = await android?.canScheduleExactNotifications();
        if (canExact == false) {
          await android?.requestExactAlarmsPermission();
        }
      } catch (e) {
        debugPrint('Exact alarms check error: $e');
        try {
          if (!await Permission.scheduleExactAlarm.isGranted) {
            await Permission.scheduleExactAlarm.request();
          }
        } catch (_) {}
      }

      // Request ignore battery optimizations so background execution is not killed
      try {
        if (!await Permission.ignoreBatteryOptimizations.isGranted) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      } catch (e) {
        debugPrint('ignoreBatteryOptimizations request error: ');
      }

      return notificationsAllowed;
    } else if (Platform.isIOS) {
      final plugin = FlutterLocalNotificationsPlugin();
      final granted = await plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return true;
  }

  static Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('Error requesting battery optimization ignore: ');
      return false;
    }
  }

  static Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    // Default to true so users receive alarms once permission is granted
    return preferences.getBool(_enabledKey) ?? true;
  }

  static Future<bool> isPrayerEnabled(String name) async {
    final preferences = await SharedPreferences.getInstance();
    final globallyEnabled = preferences.getBool(_enabledKey) ?? true;
    return globallyEnabled &&
        (preferences.getBool('$_prayerAlarmPrefix$name') ??
            defaultAlarmEnabled(name));
  }

  static Future<bool> isPrayerSelected(String name) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('$_prayerAlarmPrefix$name') ??
        defaultAlarmEnabled(name);
  }

  static Future<void> setEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    final previous = preferences.getBool(_enabledKey) ?? true;
    await preferences.setBool(_enabledKey, enabled);
    if (!enabled) {
      try {
        await _cancelScheduledPrayerReminders();
      } catch (_) {
        await preferences.setBool(_enabledKey, previous);
        rethrow;
      }
      return;
    }
    try {
      await _scheduleFromCachedLocation();
    } catch (_) {
      await preferences.setBool(_enabledKey, previous);
      rethrow;
    }
  }

  static Future<void> setPrayerEnabled(
    String name,
    bool enabled, {
    double? latitude,
    double? longitude,
    String? timezone,
    String? maslak,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final key = '$_prayerAlarmPrefix$name';
    final previous = preferences.getBool(key) ?? defaultAlarmEnabled(name);
    await preferences.setBool(key, enabled);
    if (!(preferences.getBool(_enabledKey) ?? true)) return;
    try {
      await scheduleUpcomingPrayers(
        latitude: latitude ?? preferences.getDouble('cached_lat'),
        longitude: longitude ?? preferences.getDouble('cached_lon'),
        timezone: timezone ?? preferences.getString('cached_timezone'),
        maslak: maslak ?? preferences.getString('cached_maslak'),
      );
    } catch (_) {
      await preferences.setBool(key, previous);
      rethrow;
    }
  }

  static Future<void> scheduleUpcomingPrayers({
    required double? latitude,
    required double? longitude,
    required String? timezone,
    String? maslak,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool(_enabledKey) ?? true)) {
      await _cancelScheduledPrayerReminders();
      return;
    }
    if (latitude == null || longitude == null || timezone == null) {
      debugPrint('Prayer reminders not scheduled: location is unavailable.');
      return;
    }

    final location = tz.getLocation(timezone);
    final now = tz.TZDateTime.now(location);
    final prayerEnabled = <String, bool>{
      for (final name in prayers)
        name:
            preferences.getBool('$_prayerAlarmPrefix$name') ??
            defaultAlarmEnabled(name),
      for (final name in nawafil)
        name:
            preferences.getBool('$_prayerAlarmPrefix$name') ??
            defaultAlarmEnabled(name),
      jummah:
          preferences.getBool('$_prayerAlarmPrefix$jummah') ??
          defaultAlarmEnabled(jummah),
    };
    await _cancelScheduledPrayerReminders();

    for (var day = 0; day < _daysToSchedule; day++) {
      final date = now.add(Duration(days: day));
      final prayerTimes = PrayerTimeService.getPrayerTimesForDate(
        date: date,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
        maslak: maslak,
      );
      final isFriday = date.weekday == DateTime.friday;

      for (var prayerIndex = 0; prayerIndex < prayers.length; prayerIndex++) {
        final prayer = prayers[prayerIndex];
        final isNoonPrayer = (prayer == 'Dhuhr');
        final isThisJummah = isNoonPrayer && isFriday;

        // For Friday noon prayer, check jummah or Dhuhr preference
        final isEnabled = isThisJummah
            ? (prayerEnabled[jummah] ?? prayerEnabled['Dhuhr'] ?? true)
            : (prayerEnabled[prayer] == true);

        if (!isEnabled) continue;
        final time = prayerTimes[prayer];
        if (time == null || !time.isAfter(now)) continue;

        // Schedule exactly one alarm for this prayer slot
        await _scheduleOne(
          id: _baseId + day * _slotsPerDay + prayerIndex,
          prayerName: isThisJummah ? jummah : prayer,
          when: time,
          timezone: timezone,
          isJummah: isThisJummah,
        );
      }

      final sunnahTimes = PrayerTimeService.getSunnahPrayerTimes(prayerTimes);
      for (var sunnahIndex = 0; sunnahIndex < nawafil.length; sunnahIndex++) {
        final prayer = nawafil[sunnahIndex];
        if (prayerEnabled[prayer] != true) continue;
        final time = sunnahTimes[prayer];
        if (time == null || !time.isAfter(now)) continue;
        await _scheduleOne(
          id: _baseId + day * _slotsPerDay + prayers.length + 1 + sunnahIndex,
          prayerName: prayer,
          when: time,
          timezone: timezone,
          isJummah: false,
        );
      }
    }
  }

  static Future<void> rescheduleFromCachedLocation() async {
    if (!await isEnabled()) return;
    await _scheduleFromCachedLocation();
  }

  static Future<void> _scheduleFromCachedLocation() async {
    final preferences = await SharedPreferences.getInstance();
    await scheduleUpcomingPrayers(
      latitude: preferences.getDouble('cached_lat'),
      longitude: preferences.getDouble('cached_lon'),
      timezone: preferences.getString('cached_timezone'),
      maslak: preferences.getString('cached_maslak'),
    );
  }

  static Future<void> _scheduleOne({
    required int id,
    required String prayerName,
    required DateTime when,
    required String timezone,
    required bool isJummah,
  }) async {
    final plugin = FlutterLocalNotificationsPlugin();
    final title = '$prayerName - حَيَّ عَلَى الصَّلَاة';
    final body = switch (prayerName) {
      jummah =>
        'Friday reminder: Prepare for Jumu’ah and the congregational prayer.',
      'Fajr' => 'A new day begins. It is time for Fajr prayer.',
      'Dhuhr' => 'Pause your day and answer the call to Dhuhr prayer.',
      'Asr' => 'It is time for Asr prayer. Take a moment to pray.',
      'Maghrib' => 'The sun has set. It is time for Maghrib prayer.',
      'Isha' => 'It is time for Isha prayer. End your day with prayer.',
      _ => 'It is time for $prayerName prayer.',
    };

    var scheduleMode = AndroidScheduleMode.exactAllowWhileIdle;
    if (Platform.isAndroid) {
      try {
        final android = plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final canExact = await android?.canScheduleExactNotifications();
        if (canExact == false) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      } catch (_) {}
    }

    try {
      await plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.getLocation(timezone)),
        notificationDetails: const NotificationDetails(
          android: _androidDetails,
          iOS: _iosDetails,
        ),
        androidScheduleMode: scheduleMode,
        payload: isJummah ? jummah : prayerName,
      );
      debugPrint('Prayer reminder scheduled: $title at $when ($scheduleMode)');
    } on Exception catch (error, stackTrace) {
      debugPrint('Could not schedule $prayerName with $scheduleMode: $error');
      // If exact scheduling fails, fallback to inexact to guarantee the alarm fires
      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        try {
          await plugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: tz.TZDateTime.from(when, tz.getLocation(timezone)),
            notificationDetails: const NotificationDetails(
              android: _androidDetails,
              iOS: _iosDetails,
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            payload: isJummah ? jummah : prayerName,
          );
          debugPrint('Prayer reminder fallback scheduled: $title at $when');
          return;
        } catch (fallbackError) {
          debugPrint(
            'Inexact fallback also failed for $prayerName: $fallbackError',
          );
        }
      }
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Plays Azan audio directly through the Alarm audio stream
  static Future<void> playAzanSound() async {
    try {
      await stopAzanSound();
      _audioPlayer = AudioPlayer();
      await _audioPlayer!.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            audioFocus: AndroidAudioFocus.gainTransientExclusive,
            usageType: AndroidUsageType.alarm,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.duckOthers},
          ),
        ),
      );
      await _audioPlayer!.setSource(AssetSource('audio/azan.mp3'));
      await _audioPlayer!.resume();
      debugPrint('Azan audio playing...');
    } catch (e, st) {
      debugPrint('Error playing Azan audio: $e\n$st');
    }
  }

  /// Stops any currently playing Azan audio
  static Future<void> stopAzanSound() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        await _audioPlayer!.dispose();
        _audioPlayer = null;
        debugPrint('Azan audio stopped.');
      }
    } catch (e) {
      debugPrint('Error stopping Azan audio: $e');
    }
  }

  static bool get isPlayingAzan => _audioPlayer?.state == PlayerState.playing;

  /// Shows immediate alarm notification with the Azan sound
  static Future<void> showImmediateAlarm(String prayerName) async {
    final plugin = FlutterLocalNotificationsPlugin();
    final title = '$prayerName - حَيَّ عَلَى الصَّلَاة';
    final body = 'It is time for the $prayerName prayer.';
    try {
      await plugin.show(
        id: _baseId + 99,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _androidDetails,
          iOS: _iosDetails,
        ),
        payload: prayerName,
      );
    } catch (e) {
      debugPrint('Error showing immediate alarm: $e');
    }
  }

  static Future<void> _cancelScheduledPrayerReminders() async {
    final plugin = FlutterLocalNotificationsPlugin();
    final pending = await plugin.pendingNotificationRequests();
    for (final request in pending) {
      final isCurrentPrayerAlarm =
          request.id >= _baseId && request.id < _baseId + 1000;
      final isLegacyPrayerAlarm = request.id >= 100 && request.id <= 105;
      if (isCurrentPrayerAlarm || isLegacyPrayerAlarm) {
        await plugin.cancel(id: request.id);
      }
    }
  }

  static Future<void> cancelAll() async {
    await stopAzanSound();
    await _cancelScheduledPrayerReminders();
  }

  static Future<void> testNow() async {
    await playAzanSound();
    await showImmediateAlarm('Test Azan');
  }
}
