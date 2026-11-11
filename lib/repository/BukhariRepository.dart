import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/BukhariModels.dart';

class _ParsedBukhariData {
  final Collection collection;
  final List<Book> books;
  final List<Chapter> chapters;
  final List<Hadith> hadiths;

  _ParsedBukhariData({
    required this.collection,
    required this.books,
    required this.chapters,
    required this.hadiths,
  });
}

_ParsedBukhariData _parseBukhariJson(String rawJson) {
  final Map<String, dynamic> data = jsonDecode(rawJson) as Map<String, dynamic>;

  final collection = Collection.fromJson(
    data['collection'] as Map<String, dynamic>? ?? {},
  );

  final books = (data['books'] as List<dynamic>? ?? [])
      .map((e) => Book.fromJson(e as Map<String, dynamic>))
      .toList();

  final chapters = (data['chapters'] as List<dynamic>? ?? [])
      .map((e) => Chapter.fromJson(e as Map<String, dynamic>))
      .toList();

  final hadiths = (data['hadiths'] as List<dynamic>? ?? [])
      .map((e) => Hadith.fromJson(e as Map<String, dynamic>))
      .toList();

  return _ParsedBukhariData(
    collection: collection,
    books: books,
    chapters: chapters,
    hadiths: hadiths,
  );
}

class BukhariRepository {
  BukhariRepository._internal();
  static final BukhariRepository instance = BukhariRepository._internal();
  factory BukhariRepository() => instance;

  bool _isLoaded = false;
  Future<void>? _loadingFuture;

  Collection? _collection;
  List<Book> _books = [];
  final Map<int, List<Chapter>> _chaptersByBook = {};
  final Map<int, List<Hadith>> _hadithsByChapter = {};
  final Map<int, Hadith> _hadithsById = {};
  final Map<int, int> _hadithCountByChapter = {};
  final Map<int, int> _hadithCountByBook = {};
  final Map<int, String> _normalizedArabicHadiths = {};

  Collection? get collection => _collection;
  bool get isLoaded => _isLoaded;

  Future<void> ensureLoaded() async {
    if (_isLoaded) return;
    _loadingFuture ??= _loadDataset();
    await _loadingFuture;
  }

  Future<void> _loadDataset() async {
    try {
      String? jsonString;
      const paths = [
        'assets/db/sahih-bukhari-complete.json',
        'assets/json/sahih-bukhari-complete.json',
      ];

      for (final path in paths) {
        try {
          jsonString = await rootBundle.loadString(path);
          if (jsonString.isNotEmpty) break;
        } catch (_) {}
      }

      if (jsonString == null || jsonString.isEmpty) {
        throw StateError('Could not load sahih-bukhari-complete.json from assets');
      }

      // Parse large JSON in background isolate to avoid UI freezing
      final parsed = await compute(_parseBukhariJson, jsonString);

      _collection = parsed.collection;
      _books = parsed.books;

      _chaptersByBook.clear();
      for (final chapter in parsed.chapters) {
        _chaptersByBook.putIfAbsent(chapter.bookNumber, () => []).add(chapter);
      }

      _hadithsByChapter.clear();
      _hadithsById.clear();
      _hadithCountByChapter.clear();
      _hadithCountByBook.clear();

      for (final hadith in parsed.hadiths) {
        _hadithsById[hadith.hadithId] = hadith;
        _hadithsByChapter.putIfAbsent(hadith.chapterId, () => []).add(hadith);
        _hadithCountByChapter[hadith.chapterId] =
            (_hadithCountByChapter[hadith.chapterId] ?? 0) + 1;
      }

      for (final chapter in parsed.chapters) {
        final count = _hadithCountByChapter[chapter.chapterId] ?? 0;
        _hadithCountByBook[chapter.bookNumber] =
            (_hadithCountByBook[chapter.bookNumber] ?? 0) + count;
      }

      _isLoaded = true;
      debugPrint('Sahih al-Bukhari loaded successfully: '
          '${_books.length} books, '
          '${parsed.chapters.length} chapters, '
          '${parsed.hadiths.length} hadiths.');
    } catch (e, st) {
      _loadingFuture = null;
      debugPrint('Failed to load Sahih al-Bukhari dataset: $e\n$st');
      rethrow;
    }
  }

  Future<List<Book>> getBooks() async {
    await ensureLoaded();
    return List.unmodifiable(_books);
  }

  Future<List<Chapter>> getChapters(int bookNumber) async {
    await ensureLoaded();
    return List.unmodifiable(_chaptersByBook[bookNumber] ?? []);
  }

  Future<List<Hadith>> getHadiths(int chapterId) async {
    await ensureLoaded();
    return List.unmodifiable(_hadithsByChapter[chapterId] ?? []);
  }

  Future<Hadith?> getHadith(int hadithId) async {
    await ensureLoaded();
    return _hadithsById[hadithId];
  }

  int getHadithCountForChapter(int chapterId) {
    return _hadithCountByChapter[chapterId] ?? 0;
  }

  int getHadithCountForBook(int bookNumber) {
    return _hadithCountByBook[bookNumber] ?? 0;
  }

  int getChapterCountForBook(int bookNumber) {
    return _chaptersByBook[bookNumber]?.length ?? 0;
  }

  static String normalizeArabic(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '') // strip diacritics / tashkeel
        .replaceAll('\u0640', '') // strip tatweel
        .replaceAll(RegExp(r'[\u0622\u0623\u0625\u0671]'), '\u0627') // map أ إ آ ٱ -> ا
        .replaceAll('\u0649', '\u064A') // map ى -> ي
        .replaceAll('\u0629', '\u0647'); // map ة -> ه
  }

  Future<List<Hadith>> search(String query, {int limit = 100}) async {
    await ensureLoaded();
    final rawQ = query.trim();
    if (rawQ.isEmpty) return [];

    final cleanQ = rawQ.toLowerCase();
    final normalizedArabicQ = normalizeArabic(rawQ);
    final isArabicQuery = RegExp(r'[\u0600-\u06FF]').hasMatch(rawQ);

    final results = <Hadith>[];

    for (final hadith in _hadithsById.values) {
      bool matches = false;

      // 1. Reference match (e.g. "402.2" or "Sahih al-Bukhari 1")
      if (hadith.reference.toLowerCase().contains(cleanQ) ||
          hadith.hadithNumber.toString() == cleanQ) {
        matches = true;
      }

      // 2. English text match
      if (!matches && hadith.hadithEng.toLowerCase().contains(cleanQ)) {
        matches = true;
      }

      // 3. English keywords & Topics match
      if (!matches) {
        for (final kw in hadith.keywordsEng) {
          if (kw.toLowerCase().contains(cleanQ)) {
            matches = true;
            break;
          }
        }
      }
      if (!matches) {
        for (final topic in hadith.topics) {
          if (topic.toLowerCase().contains(cleanQ)) {
            matches = true;
            break;
          }
        }
      }

      // 4. Urdu keywords and text match
      if (!matches && hadith.hadithUrdu.isNotEmpty) {
        if (hadith.hadithUrdu.contains(rawQ)) {
          matches = true;
        } else {
          for (final kw in hadith.keywordsUrdu) {
            if (kw.contains(rawQ)) {
              matches = true;
              break;
            }
          }
        }
      }

      // 5. Arabic text search with normalization
      if (!matches && isArabicQuery && hadith.hadithArabic.isNotEmpty) {
        var normArabic = _normalizedArabicHadiths[hadith.hadithId];
        if (normArabic == null) {
          normArabic = normalizeArabic(hadith.hadithArabic);
          _normalizedArabicHadiths[hadith.hadithId] = normArabic;
        }
        if (normArabic.contains(normalizedArabicQ)) {
          matches = true;
        }
      }

      if (matches) {
        results.add(hadith);
        if (results.length >= limit) break;
      }
    }

    return results;
  }
}

