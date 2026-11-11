import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quranpak/models/models.dart';

class QuranService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  static const String _arabicEdition = 'quran-uthmani';
  static const String _urduEdition = 'ur.ahmedali';
  static const String _englishEdition = 'en.sahih';

  Future<List<Surah>> getAllSurahs() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/surah'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> surahList = data['data'];
        return surahList.map((s) => Surah.fromJson(s)).toList();
      }
    } catch (e) {
      throw Exception('Failed to load surahs: $e');
    }
    return [];
  }

  Future<SurahDetail> getSurahWithTranslations(
      int surahNumber, {
        bool loadUrdu = false,
        bool loadEnglish = false,
      }) async {
    try {
      String editions = _arabicEdition;
      bool multiple = false;
      if (loadUrdu) { editions += ',$_urduEdition'; multiple = true; }
      if (loadEnglish) { editions += ',$_englishEdition'; multiple = true; }

      final url = multiple
          ? '$_baseUrl/surah/$surahNumber/editions/$editions'
          : '$_baseUrl/surah/$surahNumber/$_arabicEdition';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final editionData = multiple ? data['data'] : [data['data']];

        final arabicData = editionData[0];
        final surah = Surah.fromJson(arabicData);

        final arabicAyahs = arabicData['ayahs'] as List<dynamic>;
        List<dynamic>? urduAyahs;
        List<dynamic>? englishAyahs;

        int idx = 1;
        if (loadUrdu && editionData.length > idx) {
          urduAyahs = editionData[idx]['ayahs'] as List<dynamic>;
          idx++;
        }
        if (loadEnglish && editionData.length > idx) {
          englishAyahs = editionData[idx]['ayahs'] as List<dynamic>;
        }

        final ayahs = arabicAyahs.asMap().entries.map((entry) {
          final i = entry.key;
          final ayahJson = entry.value as Map<String, dynamic>;
          ayahJson['surah'] = {'number': surahNumber, 'name': surah.name, 'englishName': surah.englishName};
          return Ayah.fromJson(
            ayahJson,
            urdu: urduAyahs != null && i < urduAyahs.length ? urduAyahs[i]['text'] : null,
            english: englishAyahs != null && i < englishAyahs.length ? englishAyahs[i]['text'] : null,
          );
        }).toList();

        return SurahDetail(surah: surah, ayahs: ayahs);
      }
    } catch (e) {
      throw Exception('Failed to load surah $surahNumber: $e');
    }
    throw Exception('Network error');
  }

  Future<List<Ayah>> getJuzWithTranslations(
      int juzNumber, {
        bool loadUrdu = false,
        bool loadEnglish = false,
      }) async {
    try {
      // Al-Quran Cloud API does not allow multi-edition querying on Juz endpoints.
      // We perform clean, highly optimized parallel HTTP calls and merge them locally.
      final futures = <Future<http.Response>>[
        http.get(Uri.parse('$_baseUrl/juz/$juzNumber/$_arabicEdition')),
      ];

      if (loadUrdu) {
        futures.add(http.get(Uri.parse('$_baseUrl/juz/$juzNumber/$_urduEdition')));
      }
      if (loadEnglish) {
        futures.add(http.get(Uri.parse('$_baseUrl/juz/$juzNumber/$_englishEdition')));
      }

      final responses = await Future.wait(futures);

      if (responses[0].statusCode != 200) {
        throw Exception('Failed to fetch Arabic Juz data. Status code: ${responses[0].statusCode}');
      }

      final arabicData = json.decode(responses[0].body)['data'];
      final List<dynamic> arabicAyahs = arabicData['ayahs'];

      List<dynamic>? urduAyahs;
      List<dynamic>? englishAyahs;

      int idx = 1;
      if (loadUrdu && responses.length > idx) {
        if (responses[idx].statusCode == 200) {
          final urduData = json.decode(responses[idx].body)['data'];
          urduAyahs = urduData['ayahs'];
        }
        idx++;
      }
      if (loadEnglish && responses.length > idx) {
        if (responses[idx].statusCode == 200) {
          final englishData = json.decode(responses[idx].body)['data'];
          englishAyahs = englishData['ayahs'];
        }
      }

      final List<Ayah> ayahs = [];
      for (int i = 0; i < arabicAyahs.length; i++) {
        final ayahJson = arabicAyahs[i] as Map<String, dynamic>;
        final String? urduText = (urduAyahs != null && i < urduAyahs.length) ? urduAyahs[i]['text'] as String? : null;
        final String? englishText = (englishAyahs != null && i < englishAyahs.length) ? englishAyahs[i]['text'] as String? : null;

        ayahs.add(Ayah.fromJson(
          ayahJson,
          urdu: urduText,
          english: englishText,
        ));
      }

      // Spara 4 correction: Must start with 3:92 ("Lan Tana Loo")
      if (juzNumber == 4) {
        try {
          final verse3_92 = await getSpecificAyah(3, 92);
          if (verse3_92 != null) {
            ayahs.insert(0, verse3_92);
          }
        } catch (_) {}
      }
      // Spara 7 correction: Must start with 5:83 ("Wa Iza Sami'u"), remove 5:82 ("Latajidanna")
      else if (juzNumber == 7) {
        if (ayahs.isNotEmpty && ayahs[0].surahNumber == 5 && ayahs[0].numberInSurah == 82) {
          ayahs.removeAt(0);
        }
      }
      // Spara 3 correction: Ends at 3:91 (since 3:92 is moved to Spara 4)
      else if (juzNumber == 3) {
        if (ayahs.isNotEmpty && ayahs.last.surahNumber == 3 && ayahs.last.numberInSurah == 92) {
          ayahs.removeLast();
        }
      }
      // Spara 6 correction: Ends at 5:82 (since 5:82 is removed from Spara 7)
      else if (juzNumber == 6) {
        try {
          final verse5_82 = await getSpecificAyah(5, 82);
          if (verse5_82 != null) {
            ayahs.add(verse5_82);
          }
        } catch (_) {}
      }

      return ayahs;
    } catch (e) {
      throw Exception('Failed to load Juz content: $e');
    }
  }

  Future<Ayah?> getSpecificAyah(int surahNumber, int ayahNumber) async {
    try {
      final ref = '$surahNumber:$ayahNumber';
      final url = '$_baseUrl/ayah/$ref/editions/$_arabicEdition,$_urduEdition,$_englishEdition';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> editions = data['data'];
        final arabicAyah = editions[0] as Map<String, dynamic>;
        final urduText = editions.length > 1 ? editions[1]['text'] as String? : null;
        final englishText = editions.length > 2 ? editions[2]['text'] as String? : null;
        return Ayah.fromJson(arabicAyah, urdu: urduText, english: englishText);
      }
    } catch (e) {
      throw Exception('Failed to fetch ayah: $e');
    }
    return null;
  }
}