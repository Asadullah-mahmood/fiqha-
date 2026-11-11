import 'dart:async' show Timer, unawaited;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quranpak/helper/getDate.dart';
import 'package:quranpak/models/weatherData.dart';
import 'package:quranpak/screens/AllDuasScreen.dart';
import 'package:quranpak/screens/Audio.dart';
import 'package:quranpak/screens/HadithBooksScreen.dart';
import 'package:quranpak/screens/IslamicCalendarScreen.dart';
import 'package:quranpak/screens/QiblaFinder.dart';
import 'package:quranpak/screens/SurahReaderScreen.dart';
import 'package:quranpak/screens/BookmarksScreen.dart';
import 'package:quranpak/screens/WeatherDetailScreen.dart';
import 'package:quranpak/screens/counter.dart';
import 'package:quranpak/services/AzanService.dart';
import 'package:quranpak/services/locationService.dart';
import 'package:quranpak/services/weatherServices.dart';
import 'package:quranpak/services/prayerTimer.dart';
import 'package:quranpak/widgets/AdhkarItem.dart';
import 'package:quranpak/widgets/customIcons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:quranpak/services/DuaApiService.dart';

import '../models/DuaModel.dart';
import '../models/LastReadProgress.dart';
import '../utils/AppTheme.dart';
import '../utils/LastReadProvider.dart';
import '../utils/islamicDuaData.dart';
import '../models/DailyAyah.dart';
import '../models/DailyHadees.dart';
import '../services/DailyContentService.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onQuranTap;
  DashboardScreen({super.key, this.onQuranTap});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _QuickMenuItem {
  final String title;
  final IconData icon;
  final Widget screen;
  final VoidCallback? onTapOverride;

  const _QuickMenuItem({
    required this.title,
    required this.icon,
    required this.screen,
    this.onTapOverride,
  });
}

// ─────────────────────────────────────────────────────────────
// Independent horizontal action list
// ─────────────────────────────────────────────────────────────
class _HorizontalQuickActions extends StatefulWidget {
  final List<_QuickMenuItem> items;
  final VoidCallback? onQuranTap;

  const _HorizontalQuickActions({required this.items, this.onQuranTap});

  @override
  State<_HorizontalQuickActions> createState() =>
      _HorizontalQuickActionsState();
}

class _HorizontalQuickActionsState extends State<_HorizontalQuickActions> {
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(_QuickMenuItem item) {
    if (item.title == 'Quran' && widget.onQuranTap != null) {
      widget.onQuranTap!();
      return;
    }
    if (item.onTapOverride != null) {
      item.onTapOverride!();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => item.screen));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: widget.items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return _ActionTile(
            icon: item.icon,
            label: item.title,
            onTap: () => _onTap(item),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Action tile — same visual style as your original _buildActionButton
// ─────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // width: 60,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(icon, size: 26, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textScaler: TextScaler.linear(1.2),
          ),
        ],
      ),
    );
  }
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  WeatherData? _weatherData;

  String? _maslak;

  String? _currentLocation;
  String? _timezone;
  double? _latitude;
  double? _longitude;
  bool _azanEnabled = false;
  final Map<String, bool> _prayerAlarmSelections = {};

  Map<String, DateTime>? _todayPrayers;
  MapEntry<String, DateTime>? _nextPrayer;
  String? _currentPrayer;

  Duration? _timeUntilNextPrayer;

  Timer? _timer;
  String? _lastAlarmedPrayerKey;
  // ── Random Dua (from UmmahAPI, cached 24h) ──
  DuaApiModel? _randomDua;
  bool _loadingDua = true;
  DailyAyah? _dailyAyah;
  DailyHadees? _dailyHadees;
  bool _loadingDailyContent = true;
  final _dailyService = DailyContentService();

  final ScrollController _prayerTimelineController = ScrollController();
  final Map<String, GlobalKey> _prayerKeys = {
    'Fajr': GlobalKey(),
    'Sunrise': GlobalKey(),
    'Dhuhr': GlobalKey(),
    'Asr': GlobalKey(),
    'Maghrib': GlobalKey(),
    'Isha': GlobalKey(),
  };

  // Row 1 — top 5 quick actions
  static const List<_QuickMenuItem> _primaryMenus = [
    _QuickMenuItem(
      title: 'Quran',
      icon: customIcons.quran,
      screen: SurahReaderScreen(),
    ),
    _QuickMenuItem(
      title: 'Audio',
      icon: customIcons.audio,
      screen: AudioDownloadsScreen(),
    ),
    _QuickMenuItem(
      title: 'Duas',
      icon: customIcons.dua,
      screen: AllDuasScreen(),
    ),
    _QuickMenuItem(
      title: 'Counter',
      icon: customIcons.counter,
      screen: TasbihScreen(),
    ),
    _QuickMenuItem(
      title: 'Qibla',
      icon: customIcons.direction,
      screen: QiblaScreen(),
    ),
  ];

  // Row 2 — next 5 quick actions
  static const List<_QuickMenuItem> _secondaryMenus = [
    _QuickMenuItem(
      title: 'Hadith',
      icon: customIcons.book,
      screen: HadithBooksScreen(),
    ),

    _QuickMenuItem(
      title: 'Calendar',
      icon: Icons.calendar_today_outlined,
      screen: IslamicCalendarScreen(),
    ),

    _QuickMenuItem(
      title: 'Bookmarks',
      icon: customIcons.Save,
      screen: BookmarksScreen(),
    ),
  ];

  bool _isPrayerAlarmSelected(String prayer) =>
      _prayerAlarmSelections[prayer] ?? AzanService.defaultAlarmEnabled(prayer);

  String? get _activePrayerName {
    final prayerTimes = _todayPrayers;
    final timezone = _timezone;
    if (prayerTimes == null || timezone == null) return _currentPrayer;
    return PrayerTimeService.getCurrentPrayerName(
      prayerTimes: prayerTimes,
      now: tz.TZDateTime.now(tz.getLocation(timezone)),
    );
  }

  Future<void> _loadDailyContent() async {
    try {
      final ayah = await _dailyService.getDailyAyah();
      final hadees = await _dailyService.getDailyHadees();
      if (!mounted) return;
      setState(() {
        _dailyAyah = ayah;
        _dailyHadees = hadees;
        _loadingDailyContent = false;
      });
    } catch (e) {
      debugPrint('Daily content load failed: $e');
      if (!mounted) return;
      setState(() => _loadingDailyContent = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _initAlarmsAndPermissions();
    _loadWeatherData();
    _loadPrayerTimes();
    _loadAlarmSettings();
    _loadRandomDua();
    _loadDailyContent();
  }

  Future<void> _initAlarmsAndPermissions() async {
    try {
      await AzanService.requestPermissions();
    } catch (e) {
      debugPrint('Error requesting alarm permissions on init: $e');
    }
  }

  Future<void> _loadAlarmSettings() async {
    try {
      final enabled = await AzanService.isEnabled();
      final selections = <String, bool>{};
      for (final prayer in [...AzanService.prayers, AzanService.jummah]) {
        selections[prayer] = await AzanService.isPrayerSelected(prayer);
      }
      if (!mounted) return;
      setState(() {
        _azanEnabled = enabled;
        _prayerAlarmSelections
          ..clear()
          ..addAll(selections);
      });
    } catch (error, stackTrace) {
      debugPrint('Could not load prayer alarm preferences: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _togglePrayerAlarm(
    String prayer, {
    required bool enabled,
    StateSetter? updateSheet,
  }) async {
    if (!_azanEnabled) {
      final granted = await AzanService.requestPermissions();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission is needed for Azan alarms. Please enable it in Settings.',
            ),
          ),
        );
      }
      await AzanService.setEnabled(true);
      if (mounted) {
        setState(() => _azanEnabled = true);
        updateSheet?.call(() => _azanEnabled = true);
      }
    }

    final previous = _isPrayerAlarmSelected(prayer);
    final isNoon = (prayer == 'Dhuhr' || prayer == AzanService.jummah);
    setState(() {
      _prayerAlarmSelections[prayer] = enabled;
      if (isNoon) {
        _prayerAlarmSelections['Dhuhr'] = enabled;
        _prayerAlarmSelections[AzanService.jummah] = enabled;
      }
    });
    updateSheet?.call(() {
      _prayerAlarmSelections[prayer] = enabled;
      if (isNoon) {
        _prayerAlarmSelections['Dhuhr'] = enabled;
        _prayerAlarmSelections[AzanService.jummah] = enabled;
      }
    });
    try {
      await AzanService.setPrayerEnabled(
        prayer,
        enabled,
        latitude: _latitude,
        longitude: _longitude,
        timezone: _timezone,
        maslak: _maslak,
      );
      if (isNoon) {
        await AzanService.setPrayerEnabled(
          prayer == 'Dhuhr' ? AzanService.jummah : 'Dhuhr',
          enabled,
          latitude: _latitude,
          longitude: _longitude,
          timezone: _timezone,
          maslak: _maslak,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled ? '$prayer alarm turned ON' : '$prayer alarm turned OFF',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error, stackTrace) {
      if (!mounted) return;
      setState(() => _prayerAlarmSelections[prayer] = previous);
      updateSheet?.call(() => _prayerAlarmSelections[prayer] = previous);
      debugPrint('Could not update $prayer alarm: $error');
      debugPrintStack(stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update $prayer alarm: $error')),
      );
    }
  }

  Future<void> _schedulePrayerAlarms() async {
    try {
      await AzanService.scheduleUpcomingPrayers(
        latitude: _latitude,
        longitude: _longitude,
        timezone: _timezone,
        maslak: _maslak,
      );
    } catch (error, stackTrace) {
      debugPrint('Could not schedule prayer alarms: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _prayerTimelineController.dispose();
    AzanService.stopAzanSound();
    super.dispose();
  }

  Future<void> _loadRandomDua() async {
    try {
      final dua = await DuaApiService().getRandomDua();
      if (!mounted) return;
      setState(() {
        _randomDua = dua;
        _loadingDua = false;
      });
    } catch (e) {
      debugPrint('Failed to load random dua: $e');
      if (!mounted) return;
      setState(() => _loadingDua = false);
    }
  }

  void _openLastRead(LastReadProgress? progress) {
    final screen = progress == null
        ? const SurahReaderScreen(surahNumber: 1, scrollToAyah: 1)
        : progress.readerType == 'juz'
        ? SurahReaderScreen(
            juzNumber: progress.readerSectionNumber,
            scrollToAyah: progress.ayahNumber,
            scrollToSurah: progress.surahNumber,
          )
        : SurahReaderScreen(
            surahNumber: progress.surahNumber,
            scrollToAyah: progress.ayahNumber,
          );
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _scrollToNextPrayer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final activePrayer =
          _activePrayerName ?? _currentPrayer ?? _nextPrayer?.key;
      if (activePrayer == null) return;

      final key = _prayerKeys[activePrayer];
      if (key == null) return;

      final context = key.currentContext;
      if (context == null) return;

      if (!_prayerTimelineController.hasClients) return;

      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final itemCenter = box.localToGlobal(Offset.zero).dx + box.size.width / 2;
      final screenWidth = MediaQuery.of(context).size.width;
      final target =
          _prayerTimelineController.offset + itemCenter - screenWidth / 2;

      _prayerTimelineController.animateTo(
        target.clamp(0.0, _prayerTimelineController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  bool get _isTodayFriday {
    if (_timezone != null) {
      try {
        return tz.TZDateTime.now(tz.getLocation(_timezone!)).weekday ==
            DateTime.friday;
      } catch (_) {}
    }
    return DateTime.now().weekday == DateTime.friday;
  }

  String _getDisplayName(String? prayerKey) {
    if (prayerKey == null) return '...';
    if (prayerKey == 'Dhuhr' && _isTodayFriday) {
      return 'Jumma';
    }
    if (prayerKey == 'Sunrise') {
      return 'Sunrise';
    }
    return prayerKey;
  }

  Future<void> _loadPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      final cachedDate = prefs.getString('cached_prayer_date');

      if (cachedDate == todayStr) {
        final loc = prefs.getString('cached_location_text');
        final tzName = prefs.getString('cached_timezone');
        final mas = prefs.getString('cached_maslak');
        final f = prefs.getString('cached_fajr');
        final s = prefs.getString('cached_sunrise');
        final d = prefs.getString('cached_dhuhr');
        final a = prefs.getString('cached_asr');
        final m = prefs.getString('cached_maghrib');
        final i = prefs.getString('cached_isha');

        if (loc != null &&
            tzName != null &&
            f != null &&
            s != null &&
            d != null &&
            a != null &&
            m != null &&
            i != null) {
          final location = tz.getLocation(tzName);
          DateTime toLocal(String iso) =>
              tz.TZDateTime.from(DateTime.parse(iso), location);

          final Map<String, DateTime> todayMap = {
            'Fajr': toLocal(f),
            'Sunrise': toLocal(s),
            'Dhuhr': toLocal(d),
            'Asr': toLocal(a),
            'Maghrib': toLocal(m),
            'Isha': toLocal(i),
          };

          final cachedLat = prefs.getDouble('cached_lat') ?? 0.0;
          final cachedLon = prefs.getDouble('cached_lon') ?? 0.0;

          final next = PrayerTimeService.getNextPrayer(
            latitude: cachedLat,
            longitude: cachedLon,
            timezone: tzName,
            maslak: mas,
          );

          if (mounted) {
            setState(() {
              _maslak = mas;
              _currentLocation = loc;
              _timezone = tzName;
              _latitude = cachedLat;
              _longitude = cachedLon;
              _todayPrayers = todayMap;
              _nextPrayer = next;
            });
            _updatePrayerCountdown();
            _startTimer();
            _scrollToNextPrayer();
            unawaited(_schedulePrayerAlarms());
          }
          return;
        }
      }

      final cachedLat = prefs.getDouble('cached_lat');
      final cachedLon = prefs.getDouble('cached_lon');
      final cachedTimezone = prefs.getString('cached_timezone');
      if (cachedLat != null && cachedLon != null && cachedTimezone != null) {
        final cachedMaslak = prefs.getString('cached_maslak');
        final today = PrayerTimeService.getTodayPrayerTimes(
          latitude: cachedLat,
          longitude: cachedLon,
          timezone: cachedTimezone,
          maslak: cachedMaslak,
        );
        final next = PrayerTimeService.getNextPrayer(
          latitude: cachedLat,
          longitude: cachedLon,
          timezone: cachedTimezone,
          maslak: cachedMaslak,
        );

        if (!mounted) return;
        setState(() {
          _todayPrayers = today;
          _nextPrayer = next;
          _currentLocation = prefs.getString('cached_location_text');
          _timezone = cachedTimezone;
          _latitude = cachedLat;
          _longitude = cachedLon;
          _maslak = cachedMaslak;
        });
        _updatePrayerCountdown();
        _startTimer();
        _scrollToNextPrayer();
        unawaited(_schedulePrayerAlarms());
        return;
      }

      // Get user's Maslak
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          _maslak = doc.data()?['maslak'];
        }
      }

      // Get location, city, country and timezone
      final location = await LocationService.getCurrentLocation();

      debugPrint('Prayer Location: ${location.city}, ${location.country}');
      debugPrint('Latitude: ${location.latitude}');
      debugPrint('Longitude: ${location.longitude}');
      debugPrint('Timezone: ${location.timezone}');
      debugPrint('Maslak: $_maslak');

      // Calculate today's prayers
      final today = PrayerTimeService.getTodayPrayerTimes(
        latitude: location.latitude,
        longitude: location.longitude,
        timezone: location.timezone,
        maslak: _maslak,
      );

      // Calculate next prayer
      final next = PrayerTimeService.getNextPrayer(
        latitude: location.latitude,
        longitude: location.longitude,
        timezone: location.timezone,
        maslak: _maslak,
      );

      if (!mounted) return;

      setState(() {
        _todayPrayers = today;
        _nextPrayer = next;
        _currentLocation = '${location.city}, ${location.country}';
        _timezone = location.timezone;
        _latitude = location.latitude;
        _longitude = location.longitude;
      });

      _updatePrayerCountdown();
      _startTimer();
      _scrollToNextPrayer();
      unawaited(_schedulePrayerAlarms());

      // Persist after rendering the prayer card so storage latency does not
      // delay its initial countdown.
      await prefs.setString('cached_prayer_date', todayStr);
      await prefs.setDouble('cached_lat', location.latitude);
      await prefs.setDouble('cached_lon', location.longitude);
      await prefs.setString(
        'cached_location_text',
        '${location.city}, ${location.country}',
      );
      await prefs.setString('cached_timezone', location.timezone);
      if (_maslak != null) await prefs.setString('cached_maslak', _maslak!);
      if (today['Fajr'] != null)
        await prefs.setString('cached_fajr', today['Fajr']!.toIso8601String());
      if (today['Sunrise'] != null)
        await prefs.setString(
          'cached_sunrise',
          today['Sunrise']!.toIso8601String(),
        );
      if (today['Dhuhr'] != null)
        await prefs.setString(
          'cached_dhuhr',
          today['Dhuhr']!.toIso8601String(),
        );
      if (today['Asr'] != null)
        await prefs.setString('cached_asr', today['Asr']!.toIso8601String());
      if (today['Maghrib'] != null)
        await prefs.setString(
          'cached_maghrib',
          today['Maghrib']!.toIso8601String(),
        );
      if (today['Isha'] != null)
        await prefs.setString('cached_isha', today['Isha']!.toIso8601String());
    } catch (e, stackTrace) {
      debugPrint("Can't load prayer times: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _updatePrayerCountdown() {
    if (_nextPrayer == null || _timezone == null) return;

    final location = tz.getLocation(_timezone!);

    final now = tz.TZDateTime.now(location);

    final diff = _nextPrayer!.value.difference(now);
    final currentPrayer = _todayPrayers == null
        ? null
        : PrayerTimeService.getCurrentPrayerName(
            prayerTimes: _todayPrayers!,
            now: now,
          );

    if (!mounted) return;

    setState(() {
      _timeUntilNextPrayer = diff.isNegative ? Duration.zero : diff;
      _currentPrayer = currentPrayer;
    });
  }

  void _handlePrayerTimeArrived(String prayerName, DateTime now) {
    if (prayerName == 'Sunrise') return;

    final alarmKey = '${prayerName}_${now.year}_${now.month}_${now.day}';
    if (_lastAlarmedPrayerKey == alarmKey) return;
    _lastAlarmedPrayerKey = alarmKey;

    final isAlarmSelected = _isPrayerAlarmSelected(prayerName);
    if (!_azanEnabled || !isAlarmSelected) return;

    // 1. Play Azan sound directly via alarm audio stream
    AzanService.playAzanSound();

    // 2. Show in-app Alarm Dialog (scheduled notification already handles system notification)
    if (mounted) {
      _showAzanAlarmDialog(prayerName);
    }
  }

  void _showAzanAlarmDialog(String prayerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF0F3D26).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Color(0xFF0F3D26),
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$prayerName Time',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F3D26),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'حَيَّ عَلَى الصَّلَاة • حَيَّ عَلَى الْفَلَاح',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 18,
                color: const Color(0xFFD4AF37),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'It is now time for the $prayerName prayer. The Azan is currently sounding.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  AzanService.stopAzanSound();
                  Navigator.of(ctx).pop();
                },
                icon: const Icon(
                  Icons.stop_circle_outlined,
                  color: Colors.white,
                ),
                label: Text(
                  'Stop Azan',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3D26),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_nextPrayer == null) return;

      if (_timezone == null) return;
      final location = tz.getLocation(_timezone!);
      final now = tz.TZDateTime.now(location);

      final diff = _nextPrayer!.value.difference(now);

      if (diff.isNegative || diff == Duration.zero) {
        timer.cancel();

        final arrivedPrayer = _nextPrayer!.key;
        _handlePrayerTimeArrived(arrivedPrayer, now);

        _loadPrayerTimes();

        return;
      }

      if (!mounted) return;

      final currentPrayer = _todayPrayers == null
          ? null
          : PrayerTimeService.getCurrentPrayerName(
              prayerTimes: _todayPrayers!,
              now: now,
            );
      setState(() {
        _timeUntilNextPrayer = diff;
        _currentPrayer = currentPrayer;
      });
    });
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '--:--:--';
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds remaining';
  }

  String _formatTimeSingleLine(DateTime? t) {
    if (t == null) return '--:-- --';
    final h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${hour12.toString().padLeft(2, '0')}:$m $period';
  }

  Future<void> _loadWeatherData() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services are disabled");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permission permanently denied");
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final data = await WeatherService().getCurrentWeather(
        position.latitude,
        position.longitude,
      );

      // Save as fallback for offline use
      if (data != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('cached_temperature', data.temperature);
        await prefs.setString('cached_condition', data.condition);
        await prefs.setString('cached_icon', data.icon);
      }

      if (!mounted) return;
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Weather load failed: $e");

      // Fallback: show last-known values
      final prefs = await SharedPreferences.getInstance();
      final temp = prefs.getDouble('cached_temperature');
      final cond = prefs.getString('cached_condition');
      final icon = prefs.getString('cached_icon');

      if (!mounted) return;
      setState(() {
        if (temp != null && cond != null && icon != null) {
          _weatherData = WeatherData(
            temperature: temp,
            condition: cond,
            icon: icon,
          );
        } else {
          _weatherData = null;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    // Run both loads in parallel
    await Future.wait([_loadWeatherData(), _loadPrayerTimes()]);

    // Optional: also refresh the random dua
    // await _loadRandomDua();

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.split(' ').first ?? 'Guest';
    final photoUrl = user?.photoURL;

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F1),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF0F3D26), // primary green
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          displacement: 60,
          onRefresh: _onRefresh, // ✅ new method
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B5E20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SvgPicture.asset(
                            'assets/image/fiqha_logo.svg',
                            color: Colors.white,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fiqha'.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: Colors.grey.shade600,
                              ),
                              textScaler: TextScaler.linear(1),
                            ),
                            Text(
                              'Home',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textScaler: TextScaler.linear(1),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 16),
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null
                              ? const Icon(
                                  customIcons.profile,
                                  size: 22,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Greeting & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8D6E63),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SANCTUARY OF LIGHT',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                color: const Color(0xFF8D6E63),
                              ),
                              textScaler: TextScaler.linear(1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Assalam-u-Alaikum, $userName',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.linear(0.9),
                        ),
                        const SizedBox(height: 4),

                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IslamicCalendarScreen(),
                            ),
                          ),
                          child: Text(
                            '${formatFullDate()}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            textScaler: TextScaler.linear(0.9),
                          ),
                        ),
                      ],
                    ),

                    //Weather Information
                    GestureDetector(
                      onTap: () => {
                        if (_latitude != null && _longitude != null)
                          {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WeatherDetailScreen(
                                  latitude: _latitude!,
                                  longitude: _longitude!,
                                  locationName:
                                      _currentLocation ?? 'Current Location',
                                ),
                              ),
                            ),
                          },
                      },
                      child: Column(
                        children: [
                          if (_isLoading)
                            const SizedBox.shrink()
                          else if (_weatherData != null) ...[
                            Text(
                              '${_weatherData!.temperature.round()}°C',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8D6E63),
                              ),
                              textScaler: TextScaler.linear(1),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${_weatherData!.condition}",
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF8D6E63),
                                fontWeight: FontWeight.w500,
                              ),
                              textScaler: TextScaler.linear(1),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.cloud_off,
                              color: Color(0xFF8D6E63),
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'N/A',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: const Color(0xFF8D6E63),
                                fontWeight: FontWeight.w500,
                              ),
                              textScaler: TextScaler.linear(1),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Prayer Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3D26),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _nextPrayer?.key == 'Sunrise'
                                    ? 'FAJR END TIME'
                                    : 'NEXT PRAYER',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: Colors.white70,
                                ),
                                textScaler: TextScaler.linear(1),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE2B76C),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _timeUntilNextPrayer != null
                                      ? _formatDuration(_timeUntilNextPrayer)
                                      : 'Loading...',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textScaler: TextScaler.linear(1),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _getDisplayName(_nextPrayer?.key).toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimeSingleLine(_nextPrayer?.value),
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFFE2B76C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Timeline
                      _todayPrayers == null
                          ? const Center()
                          : SingleChildScrollView(
                              controller: _prayerTimelineController,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _buildPrayerTime(
                                    'Fajr',
                                    _formatTime(
                                      _todayPrayers!['Fajr'] ?? DateTime.now(),
                                    ),
                                    _activePrayerName == 'Fajr',
                                    key: _prayerKeys['Fajr'],
                                  ),
                                  const SizedBox(width: 6),
                                  _buildPrayerTime(
                                    'Sunrise',
                                    _formatTime(_todayPrayers!['Sunrise']!),
                                    false,
                                    key: _prayerKeys['Sunrise'],
                                  ),
                                  const SizedBox(width: 6),
                                  _buildPrayerTime(
                                    _isTodayFriday ? 'Jumma' : 'Dhuhr',
                                    _formatTime(_todayPrayers!['Dhuhr']!),
                                    _activePrayerName == 'Dhuhr',
                                    key: _prayerKeys['Dhuhr'],
                                  ),
                                  const SizedBox(width: 6),
                                  _buildPrayerTime(
                                    'Asr',
                                    _formatTime(_todayPrayers!['Asr']!),
                                    _activePrayerName == 'Asr',
                                    key: _prayerKeys['Asr'],
                                  ),
                                  const SizedBox(width: 6),
                                  _buildPrayerTime(
                                    'Maghrib',
                                    _formatTime(_todayPrayers!['Maghrib']!),
                                    _activePrayerName == 'Maghrib',
                                    key: _prayerKeys['Maghrib'],
                                  ),
                                  const SizedBox(width: 6),
                                  _buildPrayerTime(
                                    'Isha',
                                    _formatTime(_todayPrayers!['Isha']!),
                                    _activePrayerName == 'Isha',
                                    key: _prayerKeys['Isha'],
                                  ),
                                ],
                              ),
                            ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white54,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentLocation ?? 'Detecting location...'} '
                                '(${_maslak ?? 'Hanafi'})',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white54,
                                ),
                                textScaler: TextScaler.linear(1),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: _showFullTimetable,
                                child: Text(
                                  'Full Timetable',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE2B76C),
                                  ),
                                  textScaler: TextScaler.linear(1),
                                ),
                              ),

                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward,
                                color: Color(0xFFE2B76C),
                                size: 14,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Action Buttons — two rows, each with 5 items
                _HorizontalQuickActions(
                  items: _primaryMenus,
                  onQuranTap: widget.onQuranTap,
                ),
                const SizedBox(height: 10),
                _HorizontalQuickActions(
                  items: _secondaryMenus,
                  onQuranTap: null,
                ),
                const SizedBox(height: 24),

                // Last Recited
                Consumer<LastReadProvider>(
                  builder: (context, lastRead, _) {
                    final progress = lastRead.progress;
                    final juzNumber = progress?.juzNumber ?? 1;
                    final juzName = juzNamesArabic[juzNumber - 1];
                    final surahName = progress == null
                        ? 'Al-Fatihah'
                        : progress.surahEnglishName.isNotEmpty
                        ? progress.surahEnglishName
                        : 'Surah ${progress.surahNumber}';
                    final details = progress == null
                        ? 'Start at Ayah 1 • Juz 1 · $juzName'
                        : 'Ayah ${progress.ayahNumber} • Juz $juzNumber · $juzName';

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F2EB),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book,
                                      size: 16,
                                      color: Color(0xFF5A6B53),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    progress == null
                                        ? 'START RECITING'
                                        : 'LAST RECITED',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                      color: const Color(0xFF8D6E63),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Juz $juzNumber • $juzName',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Surah $surahName',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    progress == null
                                        ? details
                                        : '${progress.surahName} • $details',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _openLastRead(progress),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B5E20),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      progress == null
                                          ? 'Start Quran'
                                          : 'Continue',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Ramadan Challenge
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3D26),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.stars,
                            color: Color(0xFFE2B76C),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'RAMADAN KHATAM CHALLENGE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                              color: const Color(0xFFE2B76C),
                            ),
                            textScaler: TextScaler.linear(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Complete the Noble Quran this\nHoly Month',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textScaler: TextScaler.linear(1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join 84,200 believers worldwide on a 4-\npages-after-each-prayer journey',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        textScaler: TextScaler.linear(1),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8D6E63),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Join Challenge',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textScaler: TextScaler.linear(1),
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 16,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2B76C),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white30,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: Colors.white30,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Ayah of the day
                _buildAyahOfTheDay(),
                const SizedBox(height: 16),
                _buildHadeesOfTheDay(),
                const SizedBox(height: 24),

                //After Salah Adhkar
                const SizedBox(height: 12),
                const AfterSalahDuasSection(),

                const SizedBox(height: 40),

                _buildRandomDuaCard(),

                const SizedBox(height: 40),

                _buildDuasHubCard(context),

                ElevatedButton(
                  onPressed: () async {
                    await AzanService.testNow();
                    if (mounted) {
                      _showAzanAlarmDialog('Test Azan');
                    }
                  },
                  child: const Text("Test Azan"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDuasHubCard(BuildContext context) {
    final sections = IslamicDuasData.allSections;
    final totalCount = sections.fold<int>(0, (a, b) => a + b.value.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.30),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.gold.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book,
                  color: AppTheme.gold,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Islamic Duas',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalCount duas across ${sections.length} categories',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: AppTheme.gold,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sections.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.gold.withOpacity(0.30)),
                ),
                child: Text(
                  '${s.key} · ${s.value.length}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRandomDuaCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16), // ← keep bottom margin
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withOpacity(0.18),
            AppTheme.gold.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withOpacity(0.35), width: 1.2),
      ),
      child: _loadingDua
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: SizedBox.shrink()),
            )
          : _randomDua == null
          ? const Text(
              'Could not load a dua right now.',
              style: TextStyle(color: AppTheme.textSecondary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withOpacity(0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AppTheme.gold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'DUA OF THE DAY',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  _randomDua!.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 10),

                // Arabic
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    _randomDua!.arabic,
                    style: GoogleFonts.amiriQuran(
                      fontSize: 20,
                      color: AppTheme.primary,
                      height: 2.0,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),

                // Translation
                Text(
                  _randomDua!.translation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // Footer
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 12,
                      color: AppTheme.textSecondary.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _randomDua!.source,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_randomDua!.repeat > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Repeat ×${_randomDua!.repeat}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildAyahOfTheDay() {
    if (_loadingDailyContent) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_dailyAyah == null) {
      return const SizedBox.shrink();
    }
    final a = _dailyAyah!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sunny, color: Color(0xFFD6C09C), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'AYAH OF THE\nDAY',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF8D6E63),
                      height: 1.2,
                    ),
                    textScaler: TextScaler.linear(1),
                  ),
                ],
              ),
              Text(
                a.reference,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
                textScaler: TextScaler.linear(1),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Arabic
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              a.arabic,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 24,
                height: 2,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Urdu
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              a.urdu,
              textAlign: TextAlign.right,
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 14,
                height: 2.2,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // English
          Text(
            '"${a.english}"',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.black87,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _iconAction(
                    Icons.volume_up_outlined,
                    onTap: a.audioUrl == null
                        ? null
                        : () {
                            /* play audio */
                          },
                  ),
                  const SizedBox(width: 16),
                  _iconAction(Icons.bookmark_border),
                  const SizedBox(width: 16),
                  _iconAction(Icons.share_outlined),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHadeesOfTheDay() {
    if (_loadingDailyContent || _dailyHadees == null) {
      return const SizedBox.shrink();
    }
    final h = _dailyHadees!;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_stories,
                    color: Color(0xFF8D6E63),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'HADEES OF THE\nDAY',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF8D6E63),
                      height: 1.2,
                    ),
                    textScaler: TextScaler.linear(1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3D26).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  h.reference,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F3D26),
                  ),
                  textScaler: TextScaler.linear(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // English
          Text(
            '"${h.english}"',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),

          // Urdu
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              h.urdu,
              textAlign: TextAlign.right,
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 14,
                height: 2.2,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _iconAction(Icons.bookmark_border),
                  const SizedBox(width: 16),
                  _iconAction(Icons.share_outlined),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconAction(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 20, color: Colors.black54),
      ),
    );
  }

  Widget _buildPrayerTime(String name, String time, bool isActive, {Key? key}) {
    return Container(
      key: key,
      width: 62,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: const Color(0xFFE2B76C).withValues(alpha: 0.7))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE2B76C),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                'NOW',
                style: GoogleFonts.inter(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF17241D),
                ),
                textScaler: TextScaler.linear(1),
              ),
            ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
            textScaler: TextScaler.linear(1),
          ),
          const SizedBox(height: 4),

          Text(
            time,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isActive ? const Color(0xFFE2B76C) : Colors.white70,
              height: 1.2,
            ),
            textScaler: TextScaler.linear(1),
          ),
          const SizedBox(height: 6),

          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? const Color(0xFFE2B76C) : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback ontap) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: ontap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, size: 28, color: Colors.black87),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          textScaler: TextScaler.linear(1),
        ),
      ],
    );
  }

  Widget _buildAdhkarChip(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8D6E63)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showFullTimetable() async {
    await _loadAlarmSettings();
    if (!mounted) return;
    final isFriday = _todayPrayers?['Dhuhr']?.weekday == DateTime.friday;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFBF8F1),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Full Prayer Timetable',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            if (_currentLocation != null)
                              Text(
                                _currentLocation!,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 40),
                        children: [
                          _buildSectionHeader('FARD PRAYERS', Icons.mosque),

                          _buildTimetableRow(
                            'Fajr',
                            _todayPrayers?['Fajr'],
                            alarmName: 'Fajr',
                            alarmOn: _prayerAlarmSelections['Fajr'],
                            onAlarmTap: () => _togglePrayerAlarm(
                              'Fajr',
                              enabled: !_isPrayerAlarmSelected('Fajr'),
                              updateSheet: setModalState,
                            ),
                          ),
                          _buildTimetableRow(
                            isFriday ? 'Jummah' : 'Dhuhr',
                            _todayPrayers?['Dhuhr'],
                            isHighlight: isFriday,
                            alarmName: isFriday ? AzanService.jummah : 'Dhuhr',
                            alarmOn:
                                _prayerAlarmSelections[isFriday
                                    ? AzanService.jummah
                                    : 'Dhuhr'],
                            onAlarmTap: () {
                              final prayerName = isFriday
                                  ? AzanService.jummah
                                  : 'Dhuhr';
                              _togglePrayerAlarm(
                                prayerName,
                                enabled: !_isPrayerAlarmSelected(prayerName),
                                updateSheet: setModalState,
                              );
                            },
                          ),
                          _buildTimetableRow(
                            'Asr',
                            _todayPrayers?['Asr'],
                            alarmName: 'Asr',
                            alarmOn: _prayerAlarmSelections['Asr'],
                            onAlarmTap: () => _togglePrayerAlarm(
                              'Asr',
                              enabled: !_isPrayerAlarmSelected('Asr'),
                              updateSheet: setModalState,
                            ),
                          ),
                          _buildTimetableRow(
                            'Maghrib',
                            _todayPrayers?['Maghrib'],
                            alarmName: 'Maghrib',
                            alarmOn: _prayerAlarmSelections['Maghrib'],
                            onAlarmTap: () => _togglePrayerAlarm(
                              'Maghrib',
                              enabled: !_isPrayerAlarmSelected('Maghrib'),
                              updateSheet: setModalState,
                            ),
                          ),
                          _buildTimetableRow(
                            'Isha',
                            _todayPrayers?['Isha'],
                            alarmName: 'Isha',
                            alarmOn: _prayerAlarmSelections['Isha'],
                            onAlarmTap: () => _togglePrayerAlarm(
                              'Isha',
                              enabled: !_isPrayerAlarmSelected('Isha'),
                              updateSheet: setModalState,
                            ),
                          ),

                          const SizedBox(height: 24),

                          _buildSectionHeader(
                            'SUNNAH & NAWAFIL',
                            Icons.star_outline,
                          ),

                          _buildTimetableRow(
                            'Tahajjud',
                            _computeTahajjud(_todayPrayers?['Fajr']),
                            subtitle: 'Last third of the night',
                            alarmName: 'Tahajjud',
                            alarmOn: _prayerAlarmSelections['Tahajjud'],
                            onAlarmTap: () => _togglePrayerAlarm(
                              'Tahajjud',
                              enabled: !_isPrayerAlarmSelected('Tahajjud'),
                              updateSheet: setModalState,
                            ),
                          ),

                          _buildTimetableRow(
                            'Witr',
                            _computeWitr(
                              _todayPrayers?['Isha'],
                              _todayPrayers?['Fajr'],
                            ),
                            subtitle: 'After Isha until Fajr',
                            alarmName: 'Witr',
                            alarmOn: _prayerAlarmSelections['Witr'],
                            onAlarmTap: () => _togglePrayerAlarm(
                              'Witr',
                              enabled: !_isPrayerAlarmSelected('Witr'),
                              updateSheet: setModalState,
                            ),
                          ),

                          _buildTimetableRow(
                            'Ishraq',
                            _addMinutes(_todayPrayers?['Sunrise'], 15),
                            subtitle: '15 min after sunrise',
                            alarmName: 'Ishraq',
                            alarmOn: _prayerAlarmSelections['Ishraq'],
                            onAlarmTap: () => _togglePrayerAlarm(
                              'Ishraq',
                              enabled: !_isPrayerAlarmSelected('Ishraq'),
                              updateSheet: setModalState,
                            ),
                          ),

                          _buildTimetableRow(
                            'Duha (Chasht)',
                            _computeDuha(
                              _todayPrayers?['Sunrise'],
                              _todayPrayers?['Dhuhr'],
                            ),
                            subtitle: 'Mid-morning',
                            alarmName: 'Duha (Chasht)',
                            alarmOn: _prayerAlarmSelections['Duha (Chasht)'],
                            onAlarmTap: () => _togglePrayerAlarm(
                              'Duha (Chasht)',
                              enabled:
                                  !(_prayerAlarmSelections['Duha (Chasht)'] ??
                                      true),
                              updateSheet: setModalState,
                            ),
                          ),

                          _buildTimetableRow(
                            'Awwabin',
                            _addMinutes(_todayPrayers?['Maghrib'], 20),
                            subtitle: 'After Maghrib',
                            alarmName: 'Awwabin',
                            alarmOn: _prayerAlarmSelections['Awwabin'],
                            onAlarmTap: () => _togglePrayerAlarm(
                              'Awwabin',
                              enabled: !_isPrayerAlarmSelected('Awwabin'),
                              updateSheet: setModalState,
                            ),
                          ),

                          const SizedBox(height: 24),

                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F3D26).withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                  0xFF0F3D26,
                                ).withOpacity(0.15),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Color(0xFF0F3D26),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Nawafil timings are approximate. Consult your local mosque for exact congregation times.',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF0F3D26),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF8D6E63)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF8D6E63),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(thickness: 0.5)),
        ],
      ),
    );
  }

  Widget _buildTimetableRow(
    String name,
    DateTime? time, {
    bool isHighlight = false,
    bool isSecondary = false,
    String? subtitle,
    String? alarmName,
    bool? alarmOn,
    VoidCallback? onAlarmTap,
  }) {
    final formatted = time == null ? '--:--' : _formatTime(time);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              formatted,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSecondary
                    ? Colors.grey.shade400
                    : isHighlight
                    ? const Color(0xFFE2B76C)
                    : const Color(0xFF0F3D26),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                    color: isSecondary ? Colors.grey.shade400 : Colors.black87,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),

          if (isHighlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE2B76C).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Today',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8D6E63),
                ),
              ),
            ),
          if (alarmName != null)
            IconButton(
              tooltip: !_azanEnabled
                  ? 'Namaz alarms are off in Settings'
                  : _isPrayerAlarmSelected(alarmName)
                  ? 'Turn off $name alarm'
                  : 'Turn on $name alarm',
              onPressed:
                  onAlarmTap ??
                  () => _togglePrayerAlarm(
                    alarmName,
                    enabled: !_isPrayerAlarmSelected(alarmName),
                  ),
              icon: Icon(
                _azanEnabled && (alarmOn ?? _isPrayerAlarmSelected(alarmName))
                    ? Icons.notifications_active
                    : Icons.notifications_off_outlined,
                color:
                    _azanEnabled &&
                        (alarmOn ?? _isPrayerAlarmSelected(alarmName))
                    ? const Color(0xFF0F3D26)
                    : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  DateTime? _addMinutes(DateTime? base, int minutes) {
    if (base == null) return null;
    return base.add(Duration(minutes: minutes));
  }

  DateTime? _computeTahajjud(DateTime? fajr) {
    if (fajr == null) return null;
    return fajr.subtract(const Duration(hours: 2));
  }

  DateTime? _computeWitr(DateTime? isha, DateTime? fajr) {
    if (isha == null) return null;
    return isha.add(const Duration(hours: 1));
  }

  DateTime? _computeDuha(DateTime? sunrise, DateTime? dhuhr) {
    if (sunrise == null || dhuhr == null) return null;
    final diff = dhuhr.difference(sunrise);
    return sunrise.add(Duration(minutes: diff.inMinutes ~/ 2));
  }
}
