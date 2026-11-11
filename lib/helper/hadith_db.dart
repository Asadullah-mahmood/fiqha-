import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/HadithBook.dart';
import '../models/ChapterModel.dart';
import '../models/HadithItemModel.dart';

class HadithDb {
  HadithDb._();

  static const dbVersion = 1;
  static final Map<String, Database> _dbs = {};

  static Future<Database> open(String dbFileName) async {
    if (_dbs.containsKey(dbFileName)) return _dbs[dbFileName]!;

    final dir = await getDatabasesPath();
    final path = join(dir, dbFileName);
    final marker = File('$path.v');
    final assetPath = 'assets/db/$dbFileName';

    final installed =
        await File(path).exists() &&
        await marker.exists() &&
        (await marker.readAsString()).trim() == '$dbVersion';

    if (!installed) {
      await Directory(dir).create(recursive: true);
      final data = await rootBundle.load(assetPath);
      final tmp = File('$path.tmp');
      await tmp.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true,
      );
      if (await File(path).exists()) await File(path).delete();
      await tmp.rename(path);
      await marker.writeAsString('$dbVersion');
    }
    final db = await openDatabase(path, readOnly: true);
    _dbs[dbFileName] = db;
    return db;
  }

  static Future<List<HadithBookModel>> getBooks(String dbFileName) async {
    final db = await open(dbFileName);
    final rows = await db.query('books', orderBy: 'book_number');
    return rows.map(HadithBookModel.fromMap).toList();
  }

  static Future<List<ChapterModel>> getChapters(
    String dbFileName,
    int bookNumber,
  ) async {
    final db = await open(dbFileName);
    final rows = await db.rawQuery(
      '''
      SELECT c.*, COUNT(h.hadith_id) as hadiths_count
      FROM chapters c
      LEFT JOIN hadiths h ON h.chapter_id = c.chapter_id
      WHERE c.book_number = ?
      GROUP BY c.chapter_id
      ORDER BY c.chapter_number
    ''',
      [bookNumber],
    );
    return rows.map(ChapterModel.fromMap).toList();
  }

  static Future<List<HadithItemModel>> getHadiths(
    String dbFileName,
    int chapterId,
  ) async {
    final db = await open(dbFileName);
    final rows = await db.rawQuery(
      '''
      SELECT hadith_id, hadith_number, reference,
             hadith_arabic, hadith_urdu, hadith_eng,
             heading_ar, heading_ur, heading_en, category
      FROM hadiths
      WHERE chapter_id = ?
      ORDER BY hadith_number, hadith_id;
      ''',
      [chapterId],
    );
    return rows.map(HadithItemModel.fromMap).toList();
  }

  static Future<List<HadithItemModel>> getHadithsByBook(
    String dbFileName,
    int bookNumber,
  ) async {
    final db = await open(dbFileName);
    final rows = await db.rawQuery(
      '''
      SELECT h.hadith_id, h.hadith_number, h.reference,
             h.hadith_arabic, h.hadith_urdu, h.hadith_eng,
             h.heading_ar, h.heading_ur, h.heading_en, h.category
      FROM hadiths h
      JOIN chapters c ON h.chapter_id = c.chapter_id
      WHERE c.book_number = ?
      ORDER BY h.hadith_number, h.hadith_id;
      ''',
      [bookNumber],
    );
    return rows.map(HadithItemModel.fromMap).toList();
  }

  static Future<List<HadithItemModel>> getAllHadithsOfCollection(
    String dbFileName,
  ) async {
    final db = await open(dbFileName);
    final rows = await db.query('hadiths', orderBy: 'hadith_number, hadith_id');
    return rows.map(HadithItemModel.fromMap).toList();
  }
}
