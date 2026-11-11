class Localchapter {
  final int id;
  final String nameAr, nameEn, nameUr;
  final int firstNumber, count;

  Localchapter({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.nameUr,
    required this.firstNumber,
    required this.count,
  });

  factory Localchapter.fromMap(Map<String, Object?> m) => Localchapter(
    id: m['id'] as int,
    nameAr: (m['name_ar'] as String?) ?? '',
    nameEn: (m['name_en'] as String?) ?? '',
    nameUr: (m['name_ur'] as String?) ?? '',
    firstNumber: (m['first_number'] as int?) ?? 0,
    count: (m['hadith_count'] as int?) ?? 0,
  );
}

class LocalHidth {
  final int number, chapterId;
  final String ar, en, ur, grade;

  LocalHidth({
    required this.number,
    required this.chapterId,
    required this.ar,
    required this.en,
    required this.ur,
    required this.grade,
  });

  factory LocalHidth.fromMap(Map<String, Object?> m) => LocalHidth(
    number: m['hadith_number'] as int,
    chapterId: m['chapter_id'] as int,
    ar: (m['ar'] as String?) ?? '',
    en: (m['en'] as String?) ?? '',
    ur: (m['ur'] as String?) ?? '',
    grade: (m['grade'] as String?) ?? 'sahih',
  );
}