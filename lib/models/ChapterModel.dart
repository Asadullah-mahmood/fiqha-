class ChapterModel {
  final int chapterId;
  final int bookNumber;
  final int chapterNumber;
  final String nameAr;
  final String nameUr;
  final String nameEn;
  final int hadithsCount;

  ChapterModel({
    required this.chapterId,
    required this.bookNumber,
    required this.chapterNumber,
    required this.nameAr,
    required this.nameUr,
    required this.nameEn,
    this.hadithsCount = 0,
  });

  factory ChapterModel.fromMap(Map<String, Object?> map) {
    return ChapterModel(
      chapterId: (map['chapter_id'] as num?)?.toInt() ?? 0,
      bookNumber: (map['book_number'] as num?)?.toInt() ?? 0,
      chapterNumber: (map['chapter_number'] as num?)?.toInt() ?? 0,
      nameAr: (map['name_ar'] as String?) ?? '',
      nameUr: (map['name_ur'] as String?) ?? '',
      nameEn: (map['name_en'] as String?) ?? '',
      hadithsCount: (map['hadiths_count'] as num?)?.toInt() ?? 0,
    );
  }
}
