import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quranpak/helper/QuranDatabase.dart';
import 'package:sqflite/sqflite.dart';

class QuranDownloadService {
  // This function runs in a separate isolate
  static Future<void> downloadFullQuran(dynamic message) async {
    final db = await QuranDatabase.database;

    // Download the complete Uthmani text
    final response = await http.get(Uri.parse('https://api.alquran.cloud/v1/quran/quran-uthmani'));
    if (response.statusCode != 200) throw Exception('Failed to download Quran');

    final data = json.decode(response.body)['data'];
    final List<dynamic> surahs = data['surahs'];

    // Use a transaction for massive performance gains
    await db.transaction((txn) async {
      Batch batch = txn.batch();

      for (var surah in surahs) {
        // Insert Surah Metadata
        batch.insert('surahs', {
          'number': surah['number'],
          'name': surah['name'],
          'english_name': surah['englishName'],
          'english_name_translation': surah['englishNameTranslation'],
          'number_of_ayahs': surah['numberOfAyahs'],
          'revelation_type': surah['revelationType'],
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Insert Ayahs
        final List<dynamic> ayahs = surah['ayahs'];
        for (var ayah in ayahs) {
          // We need the auto-generated ID of the ayah to link translations later.
          // For the Arabic bulk download, we insert into 'ayahs'.
          batch.insert('ayahs', {
            'surah_number': surah['number'],
            'number_in_surah': ayah['numberInSurah'],
            'text': ayah['text'],
            'juz': ayah['juz'],
            'page': ayah['page'],
          });
        }
      }
      await batch.commit(noResult: true);
    });
  }
}