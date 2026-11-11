import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class QuranDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    final appDir = await getApplicationDocumentsDirectory();
    final path = join(appDir.path, 'quran_offline.db');

    return await openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
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

        await db.execute('''
          CREATE TABLE ayahs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah_number INTEGER,
            number_in_surah INTEGER,
            text TEXT,
            juz INTEGER,
            manzil INTEGER,
            page INTEGER,
            ruku INTEGER,
            FOREIGN KEY (surah_number) REFERENCES surahs (number)
          )
        ''');

        await db.execute('''
          CREATE TABLE translations(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ayah_id INTEGER,
            edition_identifier TEXT,
            text TEXT,
            FOREIGN KEY (ayah_id) REFERENCES ayahs (id) ON DELETE CASCADE
          )
        ''');

        await db.execute(
            'CREATE INDEX idx_ayahs_surah ON ayahs(surah_number, number_in_surah)');
        await db.execute(
          'CREATE UNIQUE INDEX idx_ayah_surah_number '
          'ON ayahs(surah_number, number_in_surah)',
        );
        await db.execute(
            'CREATE INDEX idx_trans_ayah ON translations(ayah_id, edition_identifier)');
        await db.execute('''
          CREATE TABLE translation_editions(
            identifier TEXT PRIMARY KEY,
            language TEXT NOT NULL,
            name TEXT NOT NULL,
            englishName TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE UNIQUE INDEX idx_trans_ayah_edition '
          'ON translations(ayah_id, edition_identifier)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE translation_editions(
              identifier TEXT PRIMARY KEY,
              language TEXT NOT NULL,
              name TEXT NOT NULL,
              englishName TEXT NOT NULL
            )
          ''');
          await db.execute('''
            DELETE FROM translations
            WHERE id NOT IN (
              SELECT MIN(id)
              FROM translations
              GROUP BY ayah_id, edition_identifier
            )
          ''');
          await db.execute(
            'CREATE UNIQUE INDEX idx_trans_ayah_edition '
            'ON translations(ayah_id, edition_identifier)',
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
            INSERT OR IGNORE INTO translations (
              ayah_id, edition_identifier, text
            )
            SELECT keeper.id, translations.edition_identifier, translations.text
            FROM translations
            JOIN ayahs duplicate ON duplicate.id = translations.ayah_id
            JOIN ayahs keeper
              ON keeper.surah_number = duplicate.surah_number
             AND keeper.number_in_surah = duplicate.number_in_surah
             AND keeper.id = (
               SELECT MIN(candidate.id)
               FROM ayahs candidate
               WHERE candidate.surah_number = duplicate.surah_number
                 AND candidate.number_in_surah = duplicate.number_in_surah
             )
            WHERE duplicate.id != keeper.id
          ''');
        }
        if (oldVersion < 4) {
          try {
            await db.execute('ALTER TABLE ayahs ADD COLUMN ruku INTEGER;');
          } catch (_) {}
        }
      },
    );
  }
}
