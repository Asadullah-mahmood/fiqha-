class DailyAyah {
  final String arabic;
  final String english;
  final String urdu;
  final String surahName;
  final int surahNumber;
  final int ayahNumber;
  final String? audioUrl; // optional

  DailyAyah({
    required this.arabic,
    required this.english,
    required this.urdu,
    required this.surahName,
    required this.surahNumber,
    required this.ayahNumber,
    this.audioUrl,
  });

  Map<String, dynamic> toJson() => {
        'arabic': arabic,
        'english': english,
        'urdu': urdu,
        'surahName': surahName,
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
        'audioUrl': audioUrl,
      };

  factory DailyAyah.fromJson(Map<String, dynamic> j) => DailyAyah(
        arabic: j['arabic'] ?? '',
        english: j['english'] ?? '',
        urdu: j['urdu'] ?? '',
        surahName: j['surahName'] ?? '',
        surahNumber: j['surahNumber'] ?? 0,
        ayahNumber: j['ayahNumber'] ?? 0,
        audioUrl: j['audioUrl'],
      );

  String get reference => 'Surah $surahName ($surahNumber:$ayahNumber)';
}