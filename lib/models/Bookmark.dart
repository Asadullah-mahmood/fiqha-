import 'package:cloud_firestore/cloud_firestore.dart';

class Bookmark {
  /// Stable ID: `uid_surahNumber_ayahNumber`.
  /// Ensures deleting/re-adding doesn't create duplicates.
  final String id;
  final String userId;
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String surahEnglishName;
  final String ayahPreview;   // first ~120 chars of the ayah
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.userId,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.surahEnglishName,
    required this.ayahPreview,
    required this.createdAt,
  });

  static String makeId(String uid, int surah, int ayah) =>
      '${uid}_${surah}_$ayah';

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'surahName': surahName,
    'surahEnglishName': surahEnglishName,
    'ayahPreview': ayahPreview,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Bookmark.fromMap(Map<String, dynamic> m) => Bookmark(
    id: m['id'] as String,
    userId: m['userId'] as String? ?? '',
    surahNumber: m['surahNumber'] as int,
    ayahNumber: m['ayahNumber'] as int,
    surahName: m['surahName'] as String? ?? '',
    surahEnglishName: m['surahEnglishName'] as String? ?? '',
    ayahPreview: m['ayahPreview'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      (m['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
    ),
  );

  /// Store dates in a format compatible with older bookmark documents.
  Map<String, dynamic> toFirestore() => {
    ...toMap(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'syncedAt': DateTime.now().toIso8601String(),
  };

  factory Bookmark.fromFirestore(Map<String, dynamic> m) {
    final rawCreatedAt = m['createdAt'];
    final createdAt = rawCreatedAt is Timestamp
        ? rawCreatedAt.toDate()
        : rawCreatedAt is String
            ? DateTime.tryParse(rawCreatedAt)
            : null;
    if (createdAt == null) {
      throw const FormatException('Bookmark has an invalid creation date.');
    }

    return Bookmark(
      id: m['id'] as String,
      userId: m['userId'] as String? ?? '',
      surahNumber: m['surahNumber'] as int,
      ayahNumber: m['ayahNumber'] as int,
      surahName: m['surahName'] as String? ?? '',
      surahEnglishName: m['surahEnglishName'] as String? ?? '',
      ayahPreview: m['ayahPreview'] as String? ?? '',
      createdAt: createdAt,
    );
  }
}