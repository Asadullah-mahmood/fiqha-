import 'dart:convert';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:quranpak/helper/QuranDatabase.dart';
import 'package:sqflite/sqflite.dart';

class QuranDownloadService {
  // This function runs in a separate isolate
  static Future<void> downloadFullQuran(dynamic message) async {
    RootIsolateToken? rootToken;
    String? edition;

    if (message is List && message.isNotEmpty) {
      rootToken = message[0] as RootIsolateToken?;
      if (message.length > 1) {
        edition = message[1] as String?;
      }
    } else if (message is RootIsolateToken) {
      rootToken = message;
    }

    if (rootToken != null) {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootToken);
    }

    final db = await QuranDatabase.database;

    // 1. Download Chapters (Surahs) from quran.com API
    final chaptersRes = await http.get(
      Uri.parse('https://api.quran.com/api/v4/chapters'),
      headers: {'User-Agent': 'Mozilla/5.0'},
    );
    if (chaptersRes.statusCode != 200) {
      throw Exception('Failed to download chapters from quran.com');
    }
    final chaptersData =
        json.decode(chaptersRes.body)['chapters'] as List<dynamic>;

    await db.transaction((txn) async {
      Batch batch = txn.batch();

      for (var ch in chaptersData) {
        batch.insert(
          'surahs',
          {
            'number': ch['id'],
            'name': ch['name_arabic'],
            'english_name': ch['name_simple'],
            'english_name_translation': ch['translated_name']['name'],
            'number_of_ayahs': ch['verses_count'],
            'revelation_type': ch['revelation_place'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });

    // 2. Download Verses (Indo-Pak text + metadata + ruku) chapter by chapter (1 to 114)
    for (int surahNum = 1; surahNum <= 114; surahNum++) {
      final indopakRes = await http.get(
        Uri.parse(
          'https://api.quran.com/api/v4/quran/verses/indopak?chapter_number=$surahNum&per_page=300',
        ),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );
      final metaRes = await http.get(
        Uri.parse(
          'https://api.quran.com/api/v4/verses/by_chapter/$surahNum?fields=juz_number,page_number,manzil_number,ruku_number&per_page=300',
        ),
        headers: {'User-Agent': 'Mozilla/5.0'},
      );

      if (indopakRes.statusCode != 200 || metaRes.statusCode != 200) continue;

      final indopakVerses =
          json.decode(indopakRes.body)['verses'] as List<dynamic>;
      final metaVerses = json.decode(metaRes.body)['verses'] as List<dynamic>;

      final Map<String, String> textMap = {};
      for (var v in indopakVerses) {
        textMap[v['verse_key']] = v['text_indopak'] ?? '';
      }

      await db.transaction((txn) async {
        Batch batch = txn.batch();
        for (var m in metaVerses) {
          final verseKey = m['verse_key']; // e.g. "1:1"
          final numberInSurah = m['verse_number'];
          final text = textMap[verseKey] ?? '';
          final juz = m['juz_number'] ?? 1;
          final page = m['page_number'] ?? 1;
          final manzil = m['manzil_number'] ?? 1;
          final ruku = m['ruku_number'];

          batch.insert(
            'ayahs',
            {
              'surah_number': surahNum,
              'number_in_surah': numberInSurah,
              'text': text,
              'juz': juz,
              'page': page,
              'manzil': manzil,
              'ruku': ruku,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    }

    // 3. If a specific translation edition is requested, download and save it
    if (edition != null && edition.isNotEmpty) {
      final url = 'https://api.alquran.cloud/v1/quran/$edition';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download translation $edition (status ${response.statusCode})',
        );
      }

      final data = json.decode(response.body)['data'];
      final List<dynamic> surahs = data['surahs'];

      final ayahRows = await db.rawQuery(
        'SELECT id, surah_number, number_in_surah FROM ayahs',
      );
      final Map<String, int> ayahIdMap = {};
      for (var row in ayahRows) {
        final key = '${row['surah_number']}:${row['number_in_surah']}';
        ayahIdMap[key] = row['id'] as int;
      }

      await db.transaction((txn) async {
        Batch batch = txn.batch();
        for (var surah in surahs) {
          final surahNum = surah['number'];
          final List<dynamic> ayahs = surah['ayahs'];
          for (var ayah in ayahs) {
            final numInSurah = ayah['numberInSurah'];
            final key = '$surahNum:$numInSurah';
            final ayahId = ayahIdMap[key];
            if (ayahId != null) {
              batch.insert(
                'translations',
                {
                  'ayah_id': ayahId,
                  'edition_identifier': edition,
                  'text': ayah['text'],
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
        await batch.commit(noResult: true);
      });
    }
  }
}
