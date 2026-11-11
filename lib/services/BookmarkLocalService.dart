import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/Bookmark.dart';

class BookmarkLocalService {
  static final BookmarkLocalService _i = BookmarkLocalService._();
  factory BookmarkLocalService() => _i;
  BookmarkLocalService._();

  Database? _db;
  Future<Database>? _openingDb;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final opening = _openingDb ??= _openDb();
    try {
      return await opening;
    } catch (_) {
      _openingDb = null;
      rethrow;
    }
  }

  Future<Database> _openDb() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'bookmarks.db');
    final databaseDirectory = Directory(databasePath);
    if (!await databaseDirectory.exists()) {
      await databaseDirectory.create(recursive: true);
    }
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (d, _) async {
        await d.execute('''
          CREATE TABLE bookmarks (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            surahNumber INTEGER NOT NULL,
            ayahNumber INTEGER NOT NULL,
            surahName TEXT NOT NULL,
            surahEnglishName TEXT NOT NULL,
            ayahPreview TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            syncState INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await d.execute('CREATE INDEX idx_bookmarks_user ON bookmarks(userId)');
        await d.execute(
          'CREATE INDEX idx_bookmarks_surah_ayah '
          'ON bookmarks(userId, surahNumber, ayahNumber)',
        );
      },
    );
    return _db!;
  }

  /// syncState values:
  /// 0 = synced (safe)
  /// 1 = pendingCreate (needs push to cloud)
  /// 2 = pendingDelete (needs removal from cloud)

  Future<void> upsert(Bookmark b, {int syncState = 1}) async {
    final d = await db;
    await d.insert('bookmarks', {
      ...b.toMap(),
      'syncState': syncState,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteById(String id) async {
    final d = await db;
    await d.update(
      'bookmarks',
      {'syncState': 2},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markSynced(String id, {int? createdAt}) async {
    final d = await db;
    await d.update(
      'bookmarks',
      {'syncState': 0},
      where: createdAt == null
          ? 'id = ? AND syncState = 1'
          : 'id = ? AND createdAt = ? AND syncState = 1',
      whereArgs: createdAt == null ? [id] : [id, createdAt],
    );
  }

  Future<void> deleteSynced(String id) async {
    final d = await db;
    await d.delete(
      'bookmarks',
      where: 'id = ? AND syncState = 2',
      whereArgs: [id],
    );
  }

  /// Bulk replace after a cloud pull (only used when local was empty).
  Future<void> replaceAll(String userId, List<Bookmark> items) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.delete('bookmarks', where: 'userId = ?', whereArgs: [userId]);
      final batch = txn.batch();
      for (final b in items) {
        batch.insert('bookmarks', {
          ...b.toMap(),
          'syncState': 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Bookmark>> getForUser(String userId) async {
    final d = await db;
    final rows = await d.query(
      'bookmarks',
      where: 'userId = ?',
      whereArgs: [userId],
      // Pending deletions are retained locally until Firestore confirms them.
      orderBy: 'createdAt DESC',
    );
    return rows
        .where((r) => r['syncState'] != 2)
        .map((r) => Bookmark.fromMap(r))
        .toList();
  }

  Future<Bookmark?> getActiveById(String userId, String id) async {
    final d = await db;
    final rows = await d.query(
      'bookmarks',
      where: 'userId = ? AND id = ? AND syncState != 2',
      whereArgs: [userId, id],
      limit: 1,
    );
    return rows.isEmpty ? null : Bookmark.fromMap(rows.first);
  }

  Future<List<Bookmark>> pendingUploads(String userId) async {
    final d = await db;
    final rows = await d.query(
      'bookmarks',
      where: 'userId = ? AND syncState = 1',
      whereArgs: [userId],
      orderBy: 'createdAt ASC',
    );
    return rows.map((r) => Bookmark.fromMap(r)).toList();
  }

  Future<List<String>> pendingDeletes(String userId) async {
    final d = await db;
    final rows = await d.query(
      'bookmarks',
      columns: ['id'],
      where: 'userId = ? AND syncState = 2',
      whereArgs: [userId],
    );
    return rows.map((r) => r['id'] as String).toList();
  }
}
