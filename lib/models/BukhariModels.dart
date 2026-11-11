class Collection {
  final String id;
  final String nameAr;
  final String nameUr;
  final String nameEn;

  const Collection({
    required this.id,
    required this.nameAr,
    required this.nameUr,
    required this.nameEn,
  });

  factory Collection.fromJson(Map<String, dynamic> json) {
    return Collection(
      id: json['id'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      nameUr: json['name_ur'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name_ar': nameAr,
        'name_ur': nameUr,
        'name_en': nameEn,
      };
}

class Book {
  final int bookNumber;
  final String nameEn;
  final String nameAr;
  final String nameUr;

  const Book({
    required this.bookNumber,
    required this.nameEn,
    required this.nameAr,
    required this.nameUr,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      bookNumber: (json['book_number'] as num?)?.toInt() ?? 0,
      nameEn: json['name_en'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      nameUr: json['name_ur'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'book_number': bookNumber,
        'name_en': nameEn,
        'name_ar': nameAr,
        'name_ur': nameUr,
      };
}

class Chapter {
  final int chapterId;
  final int bookNumber;
  final int chapterNumber;
  final String nameAr;
  final String nameUr;
  final String nameEn;

  const Chapter({
    required this.chapterId,
    required this.bookNumber,
    required this.chapterNumber,
    required this.nameAr,
    required this.nameUr,
    required this.nameEn,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      chapterId: (json['chapter_id'] as num?)?.toInt() ?? 0,
      bookNumber: (json['book_number'] as num?)?.toInt() ?? 0,
      chapterNumber: (json['chapter_number'] as num?)?.toInt() ?? 0,
      nameAr: json['name_ar'] as String? ?? '',
      nameUr: json['name_ur'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'chapter_id': chapterId,
        'book_number': bookNumber,
        'chapter_number': chapterNumber,
        'name_ar': nameAr,
        'name_ur': nameUr,
        'name_en': nameEn,
      };
}

class Hadith {
  final int hadithId;
  final num hadithNumber;
  final int chapterId;
  final String reference;
  final String hadithArabic;
  final String hadithUrdu;
  final String hadithEng;
  final String category;
  final List<String> keywordsEng;
  final List<String> keywordsUrdu;
  final List<String> topics;
  final String headingAr;
  final String headingUr;
  final String headingEn;

  const Hadith({
    required this.hadithId,
    required this.hadithNumber,
    required this.chapterId,
    required this.reference,
    required this.hadithArabic,
    required this.hadithUrdu,
    required this.hadithEng,
    required this.category,
    required this.keywordsEng,
    required this.keywordsUrdu,
    required this.topics,
    required this.headingAr,
    required this.headingUr,
    required this.headingEn,
  });

  factory Hadith.fromJson(Map<String, dynamic> json) {
    return Hadith(
      hadithId: (json['hadith_id'] as num?)?.toInt() ?? 0,
      hadithNumber: json['hadith_number'] as num? ?? 0,
      chapterId: (json['chapter_id'] as num?)?.toInt() ?? 0,
      reference: json['reference'] as String? ?? '',
      hadithArabic: json['hadith_arabic'] as String? ?? '',
      hadithUrdu: json['hadith_urdu'] as String? ?? '',
      hadithEng: json['hadith_eng'] as String? ?? '',
      category: json['category'] as String? ?? '',
      keywordsEng: (json['keywords_eng'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      keywordsUrdu: (json['keywords_urdu'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      headingAr: json['heading_ar'] as String? ?? '',
      headingUr: json['heading_ur'] as String? ?? '',
      headingEn: json['heading_en'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'hadith_id': hadithId,
        'hadith_number': hadithNumber,
        'chapter_id': chapterId,
        'reference': reference,
        'hadith_arabic': hadithArabic,
        'hadith_urdu': hadithUrdu,
        'hadith_eng': hadithEng,
        'category': category,
        'keywords_eng': keywordsEng,
        'keywords_urdu': keywordsUrdu,
        'topics': topics,
        'heading_ar': headingAr,
        'heading_ur': headingUr,
        'heading_en': headingEn,
      };
}

