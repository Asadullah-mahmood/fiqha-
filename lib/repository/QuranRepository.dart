import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:quranpak/helper/QuranDatabase.dart';
import 'package:quranpak/models/TranslationEdition.dart';
import 'package:quranpak/services/QuranDownloadService.dart';
import 'package:quranpak/models/models.dart';

class QuranRepository {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  static const String _urduEdition = 'ur.ahmedali';
  static const String _englishEdition = 'en.sahih';

  // ─────────────── BOOTSTRAP ───────────────

  Future<void> ensureOfflineData() async {
    final db = await QuranDatabase.database;
    final rootToken = RootIsolateToken.instance!;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM ayahs'),
    );
    if ((count ?? 0) > 0) return;

    await compute(QuranDownloadService.downloadFullQuran, rootToken);
  }

  Future<bool> isTranslationDownloaded(String edition) async {
    final db = await QuranDatabase.database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT a.surah_number || ':' || a.number_in_surah)
               AS translated_count,
             (SELECT COUNT(DISTINCT surah_number || ':' || number_in_surah)
              FROM ayahs) AS ayah_count
      FROM translations t
      JOIN ayahs a ON a.id = t.ayah_id
      WHERE t.edition_identifier = ?
      ''',
      [edition],
    );
    if (rows.isEmpty) return false;
    final translatedCount = rows.first['translated_count'] as int? ?? 0;
    final ayahCount = rows.first['ayah_count'] as int? ?? 0;
    return ayahCount > 0 && translatedCount == ayahCount;
  }

  Future<void> ensureTranslationDownloaded(String edition) async {
    if (await isTranslationDownloaded(edition)) return;
    await compute(QuranDownloadService.downloadFullQuran, <Object?>[
      RootIsolateToken.instance!,
      edition,
    ]);
    if (!await isTranslationDownloaded(edition)) {
      final db = await QuranDatabase.database;
      final coverage = await db.rawQuery(
        '''
        SELECT COUNT(DISTINCT a.surah_number || ':' || a.number_in_surah)
                 AS saved_count,
               (SELECT COUNT(DISTINCT surah_number || ':' || number_in_surah)
                FROM ayahs) AS expected_count
        FROM translations t
        JOIN ayahs a ON a.id = t.ayah_id
        WHERE t.edition_identifier = ?
        ''',
        [edition],
      );
      final saved = coverage.first['saved_count'] as int? ?? 0;
      final expected = coverage.first['expected_count'] as int? ?? 0;
      throw Exception(
        'Translation $edition was only saved for $saved of $expected ayahs.',
      );
    }
  }

  Future<Set<String>> getDownloadedTranslationEditions() async {
    final db = await QuranDatabase.database;
    final rows = await db.rawQuery('''
      SELECT edition_identifier
      FROM translations t
      JOIN ayahs a ON a.id = t.ayah_id
      GROUP BY edition_identifier
      HAVING COUNT(DISTINCT a.surah_number || ':' || a.number_in_surah) =
        (SELECT COUNT(DISTINCT surah_number || ':' || number_in_surah)
         FROM ayahs)
    ''');
    return rows.map((row) => row['edition_identifier'] as String).toSet();
  }

  Future<List<TranslationEdition>> getTranslationEditions({
    bool refresh = false,
  }) async {
    final db = await QuranDatabase.database;
    final cached = await _getCachedTranslationEditions(db);
    if (cached.isNotEmpty && !refresh) return cached;

    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/edition?format=text&type=translation'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to load translation editions: HTTP ${response.statusCode}.',
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final rawEditions = payload['data'] as List<dynamic>?;
      if (rawEditions == null) {
        throw const FormatException(
          'Translation catalog response has no edition list.',
        );
      }
      final editions =
          rawEditions
              .whereType<Map<String, dynamic>>()
              .map(TranslationEdition.fromJson)
              .where((edition) => edition.identifier.isNotEmpty)
              .toList()
            ..sort((a, b) {
              final languageOrder = a.language.compareTo(b.language);
              return languageOrder != 0
                  ? languageOrder
                  : a.englishName.compareTo(b.englishName);
            });
      if (editions.isEmpty) {
        throw const FormatException('Translation catalog is empty.');
      }

      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final edition in editions) {
          batch.insert(
            'translation_editions',
            edition.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
      return editions;
    } catch (error, stackTrace) {
      if (cached.isNotEmpty) {
        debugPrint(
          'Using cached translation edition catalog after refresh failed: '
          '$error\n$stackTrace',
        );
        return cached;
      }
      Error.throwWithStackTrace(
        Exception('Could not load available translations: $error'),
        stackTrace,
      );
    }
  }

  Future<List<TranslationEdition>> _getCachedTranslationEditions(
    Database db,
  ) async {
    final rows = await db.query(
      'translation_editions',
      orderBy: 'language ASC, englishName ASC',
    );
    return rows.map(TranslationEdition.fromMap).toList();
  }

  // ─────────────── SURAH LIST ───────────────

  Future<List<Surah>> getAllSurahs() async {
    final db = await QuranDatabase.database;
    final rows = await db.query('surahs', orderBy: 'number ASC');
    return rows
        .map(
          (r) => Surah(
            number: r['number'] as int,
            name: r['name'] as String? ?? '',
            englishName: r['english_name'] as String? ?? '',
            nameTranslation: r['english_name_translation'] as String? ?? '',
            numberOfAyahs: r['number_of_ayahs'] as int? ?? 0,
            revelationType: r['revelation_type'] as String?,
          ),
        )
        .toList();
  }

  // ─────────────── SURAH + AYAHS ───────────────

  Future<SurahDetail?> getSurahWithTranslations(
    int surahNumber, {
    List<String> translationEditions = const [],
  }) async {
    final db = await QuranDatabase.database;

    final sRows = await db.query(
      'surahs',
      where: 'number = ?',
      whereArgs: [surahNumber],
      limit: 1,
    );
    if (sRows.isEmpty) return null;
    final sRow = sRows.first;
    final surah = Surah(
      number: sRow['number'] as int,
      name: sRow['name'] as String? ?? '',
      englishName: sRow['english_name'] as String? ?? '',
      nameTranslation: sRow['english_name_translation'] as String? ?? '',
      numberOfAyahs: sRow['number_of_ayahs'] as int? ?? 0,
      revelationType: sRow['revelation_type'] as String?,
    );

    final rows = await db.rawQuery(
      '''
      SELECT a.id        AS ayah_id,
             a.surah_number,
             a.number_in_surah,
             a.text      AS arabic_text,
             a.juz, a.manzil, a.page,
             (SELECT t.text FROM translations t
              WHERE t.ayah_id = a.id
                AND t.edition_identifier = '$_urduEdition'
              LIMIT 1) AS urdu_text,
             (SELECT t.text FROM translations t
              WHERE t.ayah_id = a.id
                AND t.edition_identifier = '$_englishEdition'
              LIMIT 1) AS english_text,
             selected.text AS translation_text,
             second_selected.text AS second_translation_text
      FROM ayahs a
      LEFT JOIN translations selected
             ON selected.ayah_id = a.id AND selected.edition_identifier = ?
      LEFT JOIN translations second_selected
             ON second_selected.ayah_id = a.id
            AND second_selected.edition_identifier = ?
      WHERE a.surah_number = ?
      ORDER BY a.number_in_surah ASC
    ''',
      [
        translationEditions.isNotEmpty ? translationEditions[0] : null,
        translationEditions.length > 1 ? translationEditions[1] : null,
        surahNumber,
      ],
    );

    final ayahs = rows
        .map(
          (r) => Ayah.fromMap(
            r,
            surahNumber: surahNumber,
            surahName: surah.name,
            surahEnglishName: surah.englishName,
          ),
        )
        .toList();

    return SurahDetail(surah: surah, ayahs: ayahs);
  }

  // ─────────────── JUZ ───────────────

  Future<List<Ayah>> getJuzWithTranslations(
    int juzNumber, {
    List<String> translationEditions = const [],
  }) async {
    final db = await QuranDatabase.database;
    final rows = await db.rawQuery(
      '''
      SELECT a.id AS ayah_id,
             a.surah_number,
             a.number_in_surah,
             a.text AS arabic_text,
             a.juz, a.manzil, a.page,
             (SELECT t.text FROM translations t
              WHERE t.ayah_id = a.id
                AND t.edition_identifier = '$_urduEdition'
              LIMIT 1) AS urdu_text,
             (SELECT t.text FROM translations t
              WHERE t.ayah_id = a.id
                AND t.edition_identifier = '$_englishEdition'
              LIMIT 1) AS english_text,
             selected.text AS translation_text,
             second_selected.text AS second_translation_text,
             s.name           AS surah_name,
             s.english_name   AS surah_english_name
      FROM ayahs a
      LEFT JOIN translations selected
             ON selected.ayah_id = a.id AND selected.edition_identifier = ?
      LEFT JOIN translations second_selected
             ON second_selected.ayah_id = a.id
            AND second_selected.edition_identifier = ?
      LEFT JOIN surahs s ON s.number = a.surah_number
      WHERE a.juz = ?
      ORDER BY a.surah_number ASC, a.number_in_surah ASC
    ''',
      [
        translationEditions.isNotEmpty ? translationEditions[0] : null,
        translationEditions.length > 1 ? translationEditions[1] : null,
        juzNumber,
      ],
    );

    return rows
        .map(
          (r) => Ayah.fromMap(
            r,
            surahNumber: r['surah_number'] as int,
            surahName: r['surah_name'] as String? ?? '',
            surahEnglishName: r['surah_english_name'] as String? ?? '',
          ),
        )
        .toList();
  }

  // ─────────────── SINGLE AYAH ───────────────

  Future<Ayah?> getSpecificAyah(int surahNumber, int ayahNumber) async {
    final db = await QuranDatabase.database;
    final rows = await db.rawQuery(
      '''
      SELECT a.id AS ayah_id,
             a.surah_number, a.number_in_surah,
             a.text AS arabic_text, a.juz, a.manzil, a.page,
             ur.text AS urdu_text,
             en.text AS english_text,
             s.name AS surah_name,
             s.english_name AS surah_english_name
      FROM ayahs a
      LEFT JOIN translations ur
             ON ur.ayah_id = a.id AND ur.edition_identifier = ?
      LEFT JOIN translations en
             ON en.ayah_id = a.id AND en.edition_identifier = ?
      LEFT JOIN surahs s ON s.number = a.surah_number
      WHERE a.surah_number = ? AND a.number_in_surah = ?
      LIMIT 1
    ''',
      [_urduEdition, _englishEdition, surahNumber, ayahNumber],
    );

    if (rows.isEmpty) return null;
    final r = rows.first;
    return Ayah.fromMap(
      r,
      surahNumber: surahNumber,
      surahName: r['surah_name'] as String? ?? '',
      surahEnglishName: r['surah_english_name'] as String? ?? '',
    );
  }
}
