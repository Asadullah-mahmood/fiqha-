class TranslationEdition {
  final String identifier;
  final String language;
  final String name;
  final String englishName;

  const TranslationEdition({
    required this.identifier,
    required this.language,
    required this.name,
    required this.englishName,
  });

  factory TranslationEdition.fromJson(Map<String, dynamic> json) =>
      TranslationEdition(
        identifier: json['identifier'] as String,
        language: json['language'] as String? ?? '',
        name: json['name'] as String? ?? '',
        englishName: json['englishName'] as String? ?? '',
      );

  factory TranslationEdition.fromMap(Map<String, Object?> map) =>
      TranslationEdition(
        identifier: map['identifier'] as String,
        language: map['language'] as String? ?? '',
        name: map['name'] as String? ?? '',
        englishName: map['englishName'] as String? ?? '',
      );

  Map<String, Object?> toMap() => {
    'identifier': identifier,
    'language': language,
    'name': name,
    'englishName': englishName,
  };
}
