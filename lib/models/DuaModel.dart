class DuaApiModel {
  final int id;
  final String category;
  final String title;
  final String arabic;
  final String transliteration;
  final String translation;
  final String source;
  final int repeat;
  final String categoryName;

  DuaApiModel({
    required this.id,
    required this.category,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.source,
    required this.repeat,
    required this.categoryName,
  });

  factory DuaApiModel.fromJson(Map<String, dynamic> j) {
    final d = j['data'] ?? {};
    final ci = d['category_info'] ?? {};
    return DuaApiModel(
      id: d['id'] ?? 0,
      category: d['category'] ?? '',
      title: d['title'] ?? '',
      arabic: d['arabic'] ?? '',
      transliteration: d['transliteration'] ?? '',
      translation: d['translation'] ?? '',
      source: d['source'] ?? '',
      repeat: d['repeat'] ?? 1,
      categoryName: ci['name'] ?? d['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'arabic': arabic,
    'transliteration': transliteration,
    'translation': translation,
    'source': source,
    'repeat': repeat,
    'categoryName': categoryName,
  };
}