import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/DailyAyah.dart';
import '../models/DailyHadees.dart';

class DailyContentService {
  static const _ayahKey = 'daily_ayah_v1';
  static const _hadeesKey = 'daily_hadees_v1';
  static const _dateKey = 'daily_content_date';

  // ---------- AYAH ----------
  Future<DailyAyah> getDailyAyah() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();

    // Return cached if same day
    if (prefs.getString(_dateKey) == today) {
      final cached = prefs.getString(_ayahKey);
      if (cached != null) {
        try {
          return DailyAyah.fromJson(jsonDecode(cached));
        } catch (_) {/* fall through and fetch fresh */}
      }
    }

    // Fetch fresh (random ayah)
    final ayah = await _fetchRandomAyah();

    // Save
    await prefs.setString(_ayahKey, jsonEncode(ayah.toJson()));
    await prefs.setString(_hadeesKey, jsonEncode((await _fetchRandomHadees()).toJson()));
    await prefs.setString(_dateKey, today);

    return ayah;
  }

  // ---------- HADEES ----------
  Future<DailyHadees> getDailyHadees() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayStr();

    if (prefs.getString(_dateKey) == today) {
      final cached = prefs.getString(_hadeesKey);
      if (cached != null) {
        try {
          return DailyHadees.fromJson(jsonDecode(cached));
        } catch (_) {}
      }
    }
    final hadeeth = await _fetchRandomHadees();
    await prefs.setString(_hadeesKey, jsonEncode(hadeeth.toJson()));
    await prefs.setString(_dateKey, today);
    return hadeeth;
  }

  // ---------- FETCHERS ----------
  // API: alquran.cloud  (no key needed)
  Future<DailyAyah> _fetchRandomAyah() async {
    try {
      final rnd = Random();
      // Total ayat in Quran = 6236
      final ayahNumber = rnd.nextInt(6236) + 1;

      // English + Arabic
      final arRes = await http.get(Uri.parse(
          'https://api.alquran.cloud/v1/ayah/$ayahNumber/quran-uthmani'));
      // Urdu
      final urRes = await http.get(
          Uri.parse('https://api.alquran.cloud/v1/ayah/$ayahNumber/ur.jalandhry'));
      // English
      final enRes = await http.get(
          Uri.parse('https://api.alquran.cloud/v1/ayah/$ayahNumber/en.sahih'));

      if (arRes.statusCode != 200 ||
          urRes.statusCode != 200 ||
          enRes.statusCode != 200) {
        throw Exception('Failed to load ayah');
      }

      final arJson = jsonDecode(arRes.body)['data'];
      final urJson = jsonDecode(urRes.body)['data'];
      final enJson = jsonDecode(enRes.body)['data'];

      return DailyAyah(
        arabic: arJson['text'] ?? '',
        english: enJson['text'] ?? '',
        urdu: urJson['text'] ?? '',
        surahName: arJson['surah']['englishName'] ?? '',
        surahNumber: arJson['surah']['number'] ?? 0,
        ayahNumber: arJson['numberInSurah'] ?? 0,
        audioUrl: arJson['audio'] ?? enJson['audio'],
      );
    } catch (e) {
      // Offline fallback
      return _fallbackAyah();
    }
  }

  // Hadith API: hadithapi.com requires an API key — we'll use a curated list
  // rotated by day-of-year so it feels random but is free & reliable.
  Future<DailyHadees> _fetchRandomHadees() async {
    final list = _hadeesList;
    final idx = DateTime.now().difference(DateTime(2024, 1, 1)).inDays %
        list.length;
    return list[idx];
  }

  // ---------- HELPERS ----------
  String _todayStr() =>
      DateTime.now().toIso8601String().split('T').first;

  DailyAyah _fallbackAyah() => DailyAyah(
        arabic:
            'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ الْعُسْرِ يُسْرًا',
        english:
            'For indeed, with hardship [will be] ease. Indeed, with hardship [will be] ease.',
        urdu: 'پس بے شک تنگی کے ساتھ آسانی ہے، بے شک تنگی کے ساتھ آسانی ہے۔',
        surahName: 'Ash-Sharh',
        surahNumber: 94,
        ayahNumber: 5,
        audioUrl:
            'https://cdn.islamic.network/quran/audio/128/ar.alafasy/6096.mp3',
      );

  // -------- Small curated hadees list (English + Urdu + Reference) --------
  final List<DailyHadees> _hadeesList = [
    DailyHadees(
      english:
          'The best among you are those who learn the Quran and teach it.',
      urdu:
          'تم میں سب سے بہتر وہ ہے جو قرآن سیکھے اور دوسروں کو سکھائے۔',
      reference: 'Sahih al-Bukhari 5027',
    ),
    DailyHadees(
      english:
          'None of you truly believes until he loves for his brother what he loves for himself.',
      urdu:
          'تم میں سے کوئی اس وقت تک مومن نہیں ہو سکتا جب تک وہ اپنے بھائی کے لیے وہی پسند نہ کرے جو اپنے لیے پسند کرتا ہے۔',
      reference: 'Sahih al-Bukhari 13',
    ),
    DailyHadees(
      english:
          'The strong is not the one who overcomes people by his strength, but the one who controls himself while in anger.',
      urdu:
          'طاقتور وہ نہیں جو کشتی میں غالب آ جائے، طاقتور وہ ہے جو غصے کے وقت اپنے آپ پر قابو رکھے۔',
      reference: 'Sahih al-Bukhari 6114',
    ),
    DailyHadees(
      english:
          'Make things easy and do not make them difficult; give glad tidings and do not repel people.',
      urdu:
          'آسانی پیدا کرو، مشکل نہ بناؤ، خوشخبری دو، نفرت نہ دلاؤ۔',
      reference: 'Sahih al-Bukhari 69',
    ),
    DailyHadees(
      english:
          'Whoever believes in Allah and the Last Day should speak good or remain silent.',
      urdu:
          'جو اللہ اور آخرت کے دن پر ایمان رکھتا ہے وہ اچھی بات کہے یا خاموش رہے۔',
      reference: 'Sahih al-Bukhari 6018',
    ),
  ];
}