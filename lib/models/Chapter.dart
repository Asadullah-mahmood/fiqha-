// models/Chapter.dart
class Chapter {
  final int number;
  final String? englishName;
  final String? urduName;
  final String? arabicName;
  final int? hadithsCount;
  final String? bookCode;
  final String? bookName;
  final String? maslak;

  Chapter({
    required this.number,
    this.englishName,
    this.urduName,
    this.arabicName,
    this.hadithsCount,
    this.bookCode,
    this.bookName,
    this.maslak,
  });

  String get displayName {
    if (englishName != null && englishName!.trim().isNotEmpty) {
      return englishName!.trim();
    }
    if (urduName != null && urduName!.trim().isNotEmpty) {
      return urduName!.trim();
    }
    if (arabicName != null && arabicName!.trim().isNotEmpty) {
      return arabicName!.trim();
    }
    return 'Chapter $number';
  }

  String get displayUrdu => (urduName != null && urduName!.trim().isNotEmpty)
      ? urduName!.trim()
      : (arabicName ?? displayName);

  String get displayArabic => (arabicName != null && arabicName!.trim().isNotEmpty)
      ? arabicName!.trim()
      : (urduName ?? displayName);

  factory Chapter.fromSectionEntry(int number, String rawTitle, {String? bookCode, String? bookName, String? maslak}) {
    String? english;
    String? arabic;

    if (rawTitle.contains('|')) {
      final parts = rawTitle.split('|');
      english = parts[0].trim().isEmpty ? null : parts[0].trim();
      arabic = parts.length > 1 && parts[1].trim().isNotEmpty
          ? parts[1].trim()
          : null;
    } else {
      if (RegExp(r'[\u0600-\u06FF]').hasMatch(rawTitle)) {
        arabic = rawTitle.trim();
      } else {
        english = rawTitle.trim();
      }
    }

    return Chapter(
      number: number,
      englishName: english,
      arabicName: arabic,
      bookCode: bookCode,
      bookName: bookName,
      maslak: maslak,
    );
  }

  Chapter copyWith({
    String? englishName,
    String? urduName,
    String? arabicName,
    int? hadithsCount,
    String? bookCode,
    String? bookName,
    String? maslak,
  }) {
    return Chapter(
      number: number,
      englishName: englishName ?? this.englishName,
      urduName: urduName ?? this.urduName,
      arabicName: arabicName ?? this.arabicName,
      hadithsCount: hadithsCount ?? this.hadithsCount,
      bookCode: bookCode ?? this.bookCode,
      bookName: bookName ?? this.bookName,
      maslak: maslak ?? this.maslak,
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'englishName': englishName,
        'urduName': urduName,
        'arabicName': arabicName,
        'hadithsCount': hadithsCount,
        'bookCode': bookCode,
        'bookName': bookName,
        'maslak': maslak,
      };

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        number: (json['number'] ?? 0) as int,
        englishName: json['englishName'] as String?,
        urduName: json['urduName'] as String?,
        arabicName: json['arabicName'] as String?,
        hadithsCount: json['hadithsCount'] as int?,
        bookCode: json['bookCode'] as String?,
        bookName: json['bookName'] as String?,
        maslak: json['maslak'] as String?,
      );
}

