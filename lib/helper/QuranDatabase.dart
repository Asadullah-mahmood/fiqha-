import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class QuranDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quran_offline.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => await db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        // Surah Metadata
        await db.execute('''
          CREATE TABLE surahs(
            number INTEGER PRIMARY KEY,
            name TEXT,
            english_name TEXT,
            english_name_translation TEXT,
            number_of_ayahs INTEGER,
            revelation_type TEXT
          )
        ''');

        // Ayahs (Arabic Text)
        await db.execute('''
          CREATE TABLE ayahs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah_number INTEGER,
            number_in_surah INTEGER,
            text TEXT,
            juz INTEGER,
            page INTEGER,
            FOREIGN KEY (surah_number) REFERENCES surahs (number)
          )
        ''');

        // Translations (Normalized for multiple languages)
        await db.execute('''
          CREATE TABLE translations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ayah_id INTEGER,
            edition_identifier TEXT,
            text TEXT,
            FOREIGN KEY (ayah_id) REFERENCES ayahs (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }
}