class HadithBookModel {
  final int bookNumber;
  final String nameAr;
  final String nameUr;
  final String nameEn;

  HadithBookModel({
    required this.bookNumber,
    required this.nameAr,
    required this.nameUr,
    required this.nameEn,
  });

  factory HadithBookModel.fromMap(Map<String, Object?> map) {
    return HadithBookModel(
      bookNumber: (map['book_number'] as num?)?.toInt() ?? 0,
      nameAr: (map['name_ar'] as String?) ?? '',
      nameUr: (map['name_ur'] as String?) ?? '',
      nameEn: (map['name_en'] as String?) ?? '',
    );
  }
}
