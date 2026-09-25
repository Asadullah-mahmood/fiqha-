import 'package:flutter/foundation.dart';
import 'package:quranpak/models/models.dart';
import 'package:sqflite/sqflite.dart';

import '../helper/QuranDatabase.dart';
import '../services/QuranDownloadService.dart'; // Assuming you have your models here

class QuranRepository {

  // 1. Check if we need to download
  Future<bool> isDatabaseEmpty() async {
    final db = await QuranDatabase.database;
    final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ayahs'));
    return (count ?? 0) == 0;
  }

  // 2. Trigger the background download
  Future<void> ensureOfflineData() async {
    if (await isDatabaseEmpty()) {
      // Run the heavy download in a background isolate
      await compute(QuranDownloadService.downloadFullQuran, null);
    }
  }

  // 3. Read Surahs from Local DB
  Future<List<Surah>> getAllSurahs() async {
    final db = await QuranDatabase.database;
    final maps = await db.query('surahs', orderBy: 'number ASC');
    // Map SQL rows to your Surah model
    return maps.map((m) => Surah.fromJson(m)).toList();
  }

  // 4. Read Ayahs from Local DB
  Future<List<Ayah>> getAyahsForSurah(int surahNumber) async {
    final db = await QuranDatabase.database;
    final maps = await db.query(
      'ayahs',
      where: 'surah_number = ?',
      whereArgs: [surahNumber],
      orderBy: 'number_in_surah ASC',
    );
    return maps.map((m) => Ayah.fromJson(m)).toList();
  }
}