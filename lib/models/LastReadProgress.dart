class LastReadProgress {
  final int surahNumber;
  final int ayahNumber;
  final int juzNumber;
  final String surahName;
  final String surahEnglishName;
  final String readerType;
  final int readerSectionNumber;
  final DateTime updatedAt;

  const LastReadProgress({
    required this.surahNumber,
    required this.ayahNumber,
    required this.juzNumber,
    required this.surahName,
    required this.surahEnglishName,
    required this.readerType,
    required this.readerSectionNumber,
    required this.updatedAt,
  });

  Map<String, Object?> toMap({
    required String userId,
    required int syncState,
  }) =>
      {
        'userId': userId,
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'juzNumber': juzNumber,
        'surahName': surahName,
        'surahEnglishName': surahEnglishName,
        'readerType': readerType,
        'readerSectionNumber': readerSectionNumber,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'syncState': syncState,
      };

  factory LastReadProgress.fromMap(Map<String, Object?> map) =>
      LastReadProgress(
        surahNumber: map['surahNumber'] as int,
        ayahNumber: map['ayahNumber'] as int,
        juzNumber: map['juzNumber'] as int,
        surahName: map['surahName'] as String? ?? '',
        surahEnglishName: map['surahEnglishName'] as String? ?? '',
        readerType: map['readerType'] as String? ?? 'surah',
        readerSectionNumber: map['readerSectionNumber'] as int? ??
            (map['surahNumber'] as int),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updatedAt'] as int,
        ),
      );

  Map<String, Object?> toFirestore() => {
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'juzNumber': juzNumber,
        'surahName': surahName,
        'surahEnglishName': surahEnglishName,
        'readerType': readerType,
        'readerSectionNumber': readerSectionNumber,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory LastReadProgress.fromFirestore(Map<String, dynamic> map) {
    final rawUpdatedAt = map['updatedAt'];
    final DateTime? updatedAt = rawUpdatedAt is String
        ? DateTime.tryParse(rawUpdatedAt)
        : rawUpdatedAt is int
            ? DateTime.fromMillisecondsSinceEpoch(rawUpdatedAt)
            : null;
    if (updatedAt == null) {
      throw const FormatException('Last-read progress has an invalid date.');
    }

    return LastReadProgress(
      surahNumber: map['surahNumber'] as int,
      ayahNumber: map['ayahNumber'] as int,
      juzNumber: map['juzNumber'] as int,
      surahName: map['surahName'] as String? ?? '',
      surahEnglishName: map['surahEnglishName'] as String? ?? '',
      readerType: map['readerType'] as String? ?? 'surah',
      readerSectionNumber:
          map['readerSectionNumber'] as int? ?? map['surahNumber'] as int,
      updatedAt: updatedAt,
    );
  }

  bool sameLocationAs(LastReadProgress other) =>
      surahNumber == other.surahNumber &&
      ayahNumber == other.ayahNumber &&
      readerType == other.readerType &&
      readerSectionNumber == other.readerSectionNumber;
}
