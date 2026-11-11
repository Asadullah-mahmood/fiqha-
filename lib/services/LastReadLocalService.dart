import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/LastReadProgress.dart';

class LastReadLocalService {
  static final LastReadLocalService _instance = LastReadLocalService._();

  factory LastReadLocalService() => _instance;

  LastReadLocalService._();

  Database? _database;
  Future<Database>? _openingDatabase;

  Future<Database> get _db async {
    if (_database != null) return _database!;
    return _openingDatabase ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final directory = await getDatabasesPath();
    _database = await openDatabase(
      join(directory, 'last_read.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE last_read (
            userId TEXT PRIMARY KEY,
            surahNumber INTEGER NOT NULL,
            ayahNumber INTEGER NOT NULL,
            juzNumber INTEGER NOT NULL,
            surahName TEXT NOT NULL,
            surahEnglishName TEXT NOT NULL,
            readerType TEXT NOT NULL,
            readerSectionNumber INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL,
            syncState INTEGER NOT NULL DEFAULT 1
          )
        ''');
      },
    );
    return _database!;
  }

  Future<LastReadProgress?> getForUser(String userId) async {
    final db = await _db;
    final rows = await db.query(
      'last_read',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return LastReadProgress.fromMap(rows.first);
  }

  Future<void> save(String userId, LastReadProgress progress) async {
    final db = await _db;
    await db.insert(
      'last_read',
      progress.toMap(userId: userId, syncState: 1),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> markSynced(String userId, int timestamp) async {
    final db = await _db;
    await db.update(
      'last_read',
      {'syncState': 0},
      where: 'userId = ? AND updatedAt = ?',
      whereArgs: [userId, timestamp],
    );
  }
}
