import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quranpak/models/Bookmark.dart';

void main() {
  final createdAt = DateTime.parse('2026-10-08T00:00:00.000Z');
  final bookmark = Bookmark(
    id: Bookmark.makeId('user-1', 2, 13),
    userId: 'user-1',
    surahNumber: 2,
    ayahNumber: 13,
    surahName: 'البقرة',
    surahEnglishName: 'Al-Baqarah',
    ayahPreview: 'Ayah text',
    createdAt: createdAt,
  );

  test('uses a stable per-user ayah document id', () {
    expect(bookmark.id, 'user-1_2_13');
    expect(Bookmark.makeId('user-1', 2, 13), bookmark.id);
  });

  test('round-trips bookmarks through the Firestore document shape', () {
    final restored = Bookmark.fromFirestore(bookmark.toFirestore());

    expect(restored.id, bookmark.id);
    expect(restored.userId, bookmark.userId);
    expect(restored.surahNumber, bookmark.surahNumber);
    expect(restored.ayahNumber, bookmark.ayahNumber);
    expect(restored.ayahPreview, bookmark.ayahPreview);
    expect(restored.createdAt.toUtc(), createdAt);
  });

  test('reads Firestore Timestamp values from older documents', () {
    final data = bookmark.toFirestore()
      ..['createdAt'] = Timestamp.fromDate(createdAt);

    final restored = Bookmark.fromFirestore(data);

    expect(restored.createdAt.toUtc(), createdAt);
  });
}
