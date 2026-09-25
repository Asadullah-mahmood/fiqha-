class StaticDua {
  final String id;
  final String title;
  final String arabic;
  final String transliteration;
  final String english;
  final String reference;
  final String? note;

  const StaticDua({
    required this.id,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.english,
    required this.reference,
    this.note,
  });
}