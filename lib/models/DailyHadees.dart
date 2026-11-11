class DailyHadees {
  final String english;
  final String urdu;
  final String reference; // e.g. "Sahih Bukhari 6114"

  DailyHadees({
    required this.english,
    required this.urdu,
    required this.reference,
  });

  Map<String, dynamic> toJson() =>
      {'english': english, 'urdu': urdu, 'reference': reference};

  factory DailyHadees.fromJson(Map<String, dynamic> j) => DailyHadees(
        english: j['english'] ?? '',
        urdu: j['urdu'] ?? '',
        reference: j['reference'] ?? '',
      );
}