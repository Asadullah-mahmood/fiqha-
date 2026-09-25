import 'package:flutter/material.dart';
import 'package:quranpak/models/models.dart';
import 'package:quranpak/services/quranServices.dart';

class QuranProvider extends ChangeNotifier {
  final QuranService _service = QuranService();

  List<Surah> _surahs = [];
  List<Surah> _filteredSurahs = [];
  SurahDetail? _currentSurah;
  List<Ayah>? _currentJuzAyahs;
  int? _currentJuzNumber;
  
  bool _loadingList = false;
  bool _loadingContent = false;
  String? _error;

  // Translation toggles
  bool _showUrdu = false;
  bool _showEnglish = false;

  // Bookmarks
  Set<String> _bookmarks = {};

  // Last read
  int _lastSurahNumber = 1;
  int _lastAyahNumber = 1;

  // Font size
  double _arabicFontSize = 28.0;
  double _translationFontSize = 18.0;

  List<Surah> get surahs => _filteredSurahs;
  List<Surah> get allSurahs => _surahs;
  SurahDetail? get currentSurah => _currentSurah;
  List<Ayah>? get currentJuzAyahs => _currentJuzAyahs;
  int? get currentJuzNumber => _currentJuzNumber;
  
  bool get loadingList => _loadingList;
  bool get loadingContent => _loadingContent;
  String? get error => _error;
  bool get showUrdu => _showUrdu;
  bool get showEnglish => _showEnglish;
  Set<String> get bookmarks => _bookmarks;
  int get lastSurahNumber => _lastSurahNumber;
  int get lastAyahNumber => _lastAyahNumber;
  double get arabicFontSize => _arabicFontSize;
  double get translationFontSize => _translationFontSize;

  QuranProvider();

  Future<void> loadSurahs() async {
    if (_surahs.isNotEmpty) return;
    _loadingList = true;
    _error = null;
    Future.microtask(() => notifyListeners());
    
    try {
      _surahs = await _service.getAllSurahs();
      _filteredSurahs = List.from(_surahs);
    } catch (e) {
      _error = e.toString();
    }
    _loadingList = false;
    notifyListeners();
  }

  void filterSurahs(String query) {
    if (query.isEmpty) {
      _filteredSurahs = List.from(_surahs);
    } else {
      final q = query.toLowerCase();
      _filteredSurahs = _surahs.where((s) {
        return s.englishName.toLowerCase().contains(q) ||
            s.nameTranslation.toLowerCase().contains(q) ||
            s.number.toString() == q;
      }).toList();
    }
    notifyListeners();
  }

  Future<void> loadSurah(int surahNumber) async {
    _loadingContent = true;
    _currentJuzAyahs = null;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      _currentSurah = await _service.getSurahWithTranslations(
        surahNumber,
        loadUrdu: _showUrdu,
        loadEnglish: _showEnglish,
      );
      _lastSurahNumber = surahNumber;
    } catch (e) {
      _error = e.toString();
    }
    _loadingContent = false;
    notifyListeners();
  }

  Future<void> loadJuz(int juzNumber) async {
    _loadingContent = true;
    _currentSurah = null;
    _currentJuzNumber = juzNumber;
    _error = null;
    Future.microtask(() => notifyListeners());

    try {
      _currentJuzAyahs = await _service.getJuzWithTranslations(
        juzNumber,
        loadUrdu: _showUrdu,
        loadEnglish: _showEnglish,
      );
    } catch (e) {
      _error = e.toString();
    }
    _loadingContent = false;
    notifyListeners();
  }

  Future<void> toggleUrdu() async {
    _showUrdu = !_showUrdu;
    _reloadCurrent();
  }

  Future<void> toggleEnglish() async {
    _showEnglish = !_showEnglish;
    _reloadCurrent();
  }

  void _reloadCurrent() {
    if (_currentSurah != null) {
      loadSurah(_currentSurah!.surah.number);
    } else if (_currentJuzAyahs != null && _currentJuzNumber != null) {
      loadJuz(_currentJuzNumber!);
    } else {
      notifyListeners();
    }
  }

  /// Toggles a bookmark for a Surah or a specific Ayah within a Surah.
  /// Uses optional positional parameter [ayahNum] to support 1 or 2 arguments.
  void toggleBookmark(int surahNum, [int? ayahNum]) {
    final key = ayahNum != null ? '$surahNum:$ayahNum' : '$surahNum';
    if (_bookmarks.contains(key)) {
      _bookmarks.remove(key);
    } else {
      _bookmarks.add(key);
    }
    notifyListeners();
  }

  /// Checks if a Surah or a specific Ayah within a Surah is bookmarked.
  /// Uses optional positional parameter [ayahNum] to support 1 or 2 arguments.
  bool isBookmarked(int surahNum, [int? ayahNum]) {
    final key = ayahNum != null ? '$surahNum:$ayahNum' : '$surahNum';
    return _bookmarks.contains(key);
  }

  void setArabicFontSize(double size) {
    _arabicFontSize = size;
    notifyListeners();
  }

  void setTranslationFontSize(double size) {
    _translationFontSize = size;
    notifyListeners();
  }

  void saveLastRead(int surahNum, int ayahNum) {
    _lastSurahNumber = surahNum;
    _lastAyahNumber = ayahNum;
    notifyListeners();
  }
}
