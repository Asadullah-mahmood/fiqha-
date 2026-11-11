// ─────────────────────────────────────────────────────────────
//  SURAH
// ─────────────────────────────────────────────────────────────
class Surah {
  final int number;
  final String name; // Arabic
  final String englishName;
  final String nameTranslation; // ← used by home screen
  final int numberOfAyahs;
  final String? revelationType;

  const Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.nameTranslation,
    required this.numberOfAyahs,
    this.revelationType,
  });

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(
    number: json['number'] as int,
    name: json['name'] as String? ?? '',
    englishName: json['englishName'] as String? ?? '',
    nameTranslation: json['englishNameTranslation'] as String? ?? '',
    numberOfAyahs: json['numberOfAyahs'] as int? ?? 0,
    revelationType: json['revelationType'] as String?,
  );
}

// ─────────────────────────────────────────────────────────────
//  AYAH
//  Every field below is accessed somewhere in your screens.
// ─────────────────────────────────────────────────────────────
class Ayah {
  final int number; // global ayah number (1..6236)
  final int numberInSurah;
  final int surahNumber;
  final String text; // Arabic
  final String? urdu;
  final String? english;
  final String? translation;
  final String? secondTranslation;
  final int juz;
  final int manzil;
  final int page;
  final int? ruku;
  final String? surahName;
  final String? surahEnglishName;

  const Ayah({
    required this.number,
    required this.numberInSurah,
    required this.surahNumber,
    required this.text,
    this.urdu,
    this.english,
    this.translation,
    this.secondTranslation,
    required this.juz,
    required this.manzil,
    required this.page,
    this.ruku,
    this.surahName,
    this.surahEnglishName,
  });

  /// Remote JSON (used by AlQuran Cloud API when needed).
  factory Ayah.fromJson(
    Map<String, dynamic> json, {
    String? urdu,
    String? english,
  }) {
    return Ayah(
      number: json['number'] as int? ?? 0,
      numberInSurah: json['numberInSurah'] as int? ?? 0,
      surahNumber: (json['surah']?['number'] as int?) ?? 0,
      text: json['text'] as String? ?? '',
      urdu: urdu,
      english: english,
      translation: json['translation'] as String?,
      juz: json['juz'] as int? ?? 1,
      manzil: json['manzil'] as int? ?? 1,
      page: json['page'] as int? ?? 1,
      ruku: json['ruku'] as int?,
      surahName: json['surah']?['name'] as String?,
      surahEnglishName: json['surah']?['englishName'] as String?,
    );
  }

  /// Row coming from a JOIN of `ayahs`, `translations`, and `surahs`.
  /// [surahName] and [surahEnglishName] are provided by the repository.
  factory Ayah.fromMap(
    Map<String, dynamic> row, {
    required int surahNumber,
    required String surahName,
    required String surahEnglishName,
  }) {
    final numberInSurah = row['number_in_surah'] as int? ?? 0;
    return Ayah(
      // Global ayah number approximation (safe composite, unique per ayah)
      number: surahNumber * 1000 + numberInSurah,
      numberInSurah: numberInSurah,
      surahNumber: surahNumber,
      text: row['arabic_text'] as String? ?? '',
      urdu: row['urdu_text'] as String?,
      english: row['english_text'] as String?,
      translation: row['translation_text'] as String?,
      secondTranslation: row['second_translation_text'] as String?,
      juz: row['juz'] as int? ?? 1,
      manzil: row['manzil'] as int? ?? 1,
      page: row['page'] as int? ?? 1,
      ruku: row['ruku'] as int?,
      surahName: surahName,
      surahEnglishName: surahEnglishName,
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  SURAH DETAIL
// ─────────────────────────────────────────────────────────────
class SurahDetail {
  final Surah surah;
  final List<Ayah> ayahs;

  const SurahDetail({required this.surah, required this.ayahs});
}
