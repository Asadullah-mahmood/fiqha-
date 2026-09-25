class Surah {
  final int number;
  final String name;
  final String nameArabic;
  final String nameTranslation;
  final String revelationType;
  final int numberOfAyahs;
  final String englishName;

  Surah({
    required this.number,
    required this.name,
    required this.nameArabic,
    required this.nameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
    required this.englishName,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      number: json['number'] ?? 0,
      name: json['name'] ?? '',
      nameArabic: json['name'] ?? '',
      nameTranslation: json['englishNameTranslation'] ?? '',
      revelationType: json['revelationType'] ?? '',
      numberOfAyahs: json['numberOfAyahs'] ?? 0,
      englishName: json['englishName'] ?? '',
    );
  }

  String get revelationTypeUrdu =>
      revelationType == 'Meccan' ? 'مکی' : 'مدنی';
}

class Ayah {
  final int number;
  final int numberInSurah;
  final String text;
  final String? textUrdu;
  final String? textEnglish;
  final int surahNumber;
  final String? surahName;
  final String? surahEnglishName;
  final int page;
  final int juz;
  final int ruku;
  final int manzil;

  Ayah({
    required this.number,
    required this.numberInSurah,
    required this.text,
    this.textUrdu,
    this.textEnglish,
    required this.surahNumber,
    this.surahName,
    this.surahEnglishName,
    required this.page,
    required this.juz,
    this.ruku = 0,
    this.manzil = 0,
  });

  factory Ayah.fromJson(Map<String, dynamic> json, {String? urdu, String? english}) {
    final surahData = json['surah'];
    return Ayah(
      number: json['number'] ?? 0,
      numberInSurah: json['numberInSurah'] ?? 0,
      text: json['text'] ?? '',
      textUrdu: urdu,
      textEnglish: english,
      surahNumber: surahData is Map ? (surahData['number'] ?? 0) : (json['surahNumber'] ?? 0),
      surahName: surahData is Map ? surahData['name'] : null,
      surahEnglishName: surahData is Map ? surahData['englishName'] : null,
      page: json['page'] ?? 0,
      juz: json['juz'] ?? 0,
      ruku: json['ruku'] ?? 0,
      manzil: json['manzil'] ?? 0,
    );
  }
}

class SurahDetail {
  final Surah surah;
  final List<Ayah> ayahs;

  SurahDetail({required this.surah, required this.ayahs});
}
