import 'BukhariModels.dart';

class HadithItemModel {
  final int hadithId;
  final int hadithNumber;
  final int chapterId;
  final String reference;
  final String arabic;
  final String urdu;
  final String english;
  final String category;
  final String grade;
  final String headingAr;
  final String headingUr;
  final String headingEn;
  final String keywordsUrdu;
  final String keywordsEng;
  final String topics;

  HadithItemModel({
    required this.hadithId,
    required this.hadithNumber,
    required this.chapterId,
    required this.reference,
    required this.arabic,
    required this.urdu,
    required this.english,
    required this.category,
    required this.grade,
    required this.headingAr,
    required this.headingUr,
    required this.headingEn,
    required this.keywordsUrdu,
    required this.keywordsEng,
    required this.topics,
  });

  factory HadithItemModel.fromMap(Map<String, Object?> map) {
    final cat = (map['category'] as String?) ?? '';
    final grd = (map['grade'] as String?) ?? (cat.isNotEmpty ? cat : 'Sahih');
    return HadithItemModel(
      hadithId: (map['hadith_id'] as num?)?.toInt() ?? 0,
      hadithNumber: (map['hadith_number'] as num?)?.toInt() ?? 0,
      chapterId: (map['chapter_id'] as num?)?.toInt() ?? 0,
      reference: (map['reference'] as String?) ?? '',
      arabic: (map['hadith_arabic'] as String?) ?? '',
      urdu: (map['hadith_urdu'] as String?) ?? '',
      english: (map['hadith_eng'] as String?) ?? '',
      category: cat.isNotEmpty ? cat : 'Sahih',
      grade: grd.isNotEmpty ? grd : 'Sahih',
      headingAr: (map['heading_ar'] as String?) ?? '',
      headingUr: (map['heading_ur'] as String?) ?? '',
      headingEn: (map['heading_en'] as String?) ?? '',
      keywordsUrdu: (map['keywords_urdu'] as String?) ?? '',
      keywordsEng: (map['keywords_eng'] as String?) ?? '',
      topics: (map['topics'] as String?) ?? '',
    );
  }

  Hadith toHadith() => Hadith(
        hadithId: hadithId,
        hadithNumber: hadithNumber,
        chapterId: chapterId,
        reference: reference,
        hadithArabic: arabic,
        hadithUrdu: urdu,
        hadithEng: english,
        category: grade.isNotEmpty ? grade : 'Sahih',
        keywordsEng: const [],
        keywordsUrdu: const [],
        topics: const [],
        headingAr: headingAr,
        headingUr: headingUr,
        headingEn: headingEn,
      );
}
