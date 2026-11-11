import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quranpak/models/TranslationEdition.dart';
import 'package:quranpak/models/models.dart';
import 'package:quranpak/repository/QuranRepository.dart';

import 'SurahAyahCounts.dart';

class QuranProvider extends ChangeNotifier {
  static const _showTranslationKey = 'quran_show_translation';
  static const _translationEditionKey = 'quran_translation_edition';
  static const _translationEditionsKey = 'quran_translation_editions';
  static const _arabicFontFamilyKey = 'quran_arabic_font_family';
  static const _defaultTranslationEdition = 'en.sahih';
  static const _defaultArabicFontFamily = 'amiriQuran';

  final QuranRepository _repo = QuranRepository();

  List<Surah> _surahs = [];
  List<Surah> _filteredSurahs = [];
  SurahDetail? _currentSurah;
  List<Ayah>? _currentJuzAyahs;
  int? _currentJuzNumber;

  bool _loadingList = false;
  bool _loadingContent = false;
  bool _bootstrapped = false;
  String? _error;

  bool _translationEnabled = false;
  List<String> _selectedTranslationEditions = [_defaultTranslationEdition];
  String _arabicFontFamily = _defaultArabicFontFamily;
  List<TranslationEdition> _translationEditions = [];
  Set<String> _downloadedTranslationEditions = {};
  bool _loadingTranslationEditions = false;
  String? _downloadingTranslationEdition;
  String? _translationError;
  int _translationRequestRevision = 0;

  final Set<String> _bookmarks = {};
  int _lastSurahNumber = 1;
  int _lastAyahNumber = 1;

  double _arabicFontSize = 28.0;
  double _translationFontSize = 18.0;

  List<Surah> get surahs => _filteredSurahs;
  List<Surah> get allSurahs => _surahs;
  SurahDetail? get currentSurah => _currentSurah;
  List<Ayah>? get currentJuzAyahs => _currentJuzAyahs;
  int? get currentJuzNumber => _currentJuzNumber;
  bool get loadingList => _loadingList;
  bool get loadingContent => _loadingContent;
  bool get isBootstrapped => _bootstrapped;
  String? get error => _error;
  bool get translationEnabled => _translationEnabled;
  String get selectedTranslationEdition =>
      _selectedTranslationEditions.firstOrNull ?? _defaultTranslationEdition;
  List<String> get selectedTranslationEditions =>
      List.unmodifiable(_selectedTranslationEditions);
  String get arabicFontFamily => _arabicFontFamily;
  String get selectedTranslationLanguage =>
      translationLanguageFor(selectedTranslationEdition);
  String translationLanguageFor(String identifier) {
    for (final edition in _translationEditions) {
      if (edition.identifier == identifier) {
        return edition.language.toLowerCase();
      }
    }
    return '';
  }

  TranslationEdition? translationEditionFor(String identifier) {
    for (final edition in _translationEditions) {
      if (edition.identifier == identifier) return edition;
    }
    return null;
  }

  List<TranslationEdition> get translationEditions =>
      List.unmodifiable(_translationEditions);
  Set<String> get downloadedTranslationEditions =>
      Set.unmodifiable(_downloadedTranslationEditions);
  bool get loadingTranslationEditions => _loadingTranslationEditions;
  String? get downloadingTranslationEdition => _downloadingTranslationEdition;
  String? get translationError => _translationError;
  bool get isSelectedTranslationDownloaded => _selectedTranslationEditions
      .every(_downloadedTranslationEditions.contains);
  Set<String> get bookmarks => _bookmarks;
  int get lastSurahNumber => _lastSurahNumber;
  int get lastAyahNumber => _lastAyahNumber;
  double get arabicFontSize => _arabicFontSize;
  double get translationFontSize => _translationFontSize;

  TextStyle arabicFontStyle({double? fontSize, Color? color, double? height}) {
    final size = fontSize ?? _arabicFontSize;
    switch (_arabicFontFamily) {
      case 'indo_pak':
        return TextStyle(
          fontFamily: 'indo_pak',
          fontSize: size,
          color: color,
          height: height,
        );
      case 'amiri':
        return GoogleFonts.amiri(fontSize: size, color: color, height: height);
      case 'notoNaskhArabic':
        return GoogleFonts.notoNaskhArabic(
          fontSize: size,
          color: color,
          height: height,
        );
      case 'scheherazadeNew':
        return GoogleFonts.scheherazadeNew(
          fontSize: size,
          color: color,
          height: height,
        );
      default:
        return GoogleFonts.amiriQuran(
          fontSize: size,
          color: color,
          height: height,
        );
    }
  }

  Future<void> bootstrap() async {
    if (_bootstrapped) return;
    _loadingList = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.ensureOfflineData();
      await _loadTranslationPreferences();
      final raw = await _repo.getAllSurahs();

      // ✅ Patch numberOfAyahs from the canonical static table
      _surahs = raw.map((s) {
        final count = surahAyahCounts[s.number];
        if (count == null || s.numberOfAyahs == count) return s;
        return Surah(
          number: s.number,
          name: s.name,
          englishName: s.englishName,
          nameTranslation: s.nameTranslation,
          numberOfAyahs: count,
          revelationType: s.revelationType,
        );
      }).toList();

      _filteredSurahs = List.from(_surahs);
      _bootstrapped = true;
      unawaited(loadTranslationEditions());
    } catch (e) {
      _error =
          'Failed to load Quran data. '
          'Please check your internet connection and try again.\n\n'
          'Details: $e';
    }

    _loadingList = false;
    notifyListeners();
  }

  /// Kept for backwards compatibility with the home screen.
  Future<void> loadSurahs() async {
    if (_surahs.isNotEmpty) return;
    await bootstrap();
  }

  /// Resets the bootstrapped flag and retries the full download.
  /// Called by the "Try Again" button when the DB is empty.
  Future<void> retryBootstrap() async {
    _bootstrapped = false;
    _error = null;
    await bootstrap();
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
    notifyListeners();

    try {
      _currentSurah = await _repo.getSurahWithTranslations(
        surahNumber,
        translationEditions: _translationEnabled
            ? _selectedTranslationEditions
            : const [],
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
    notifyListeners();

    try {
      _currentJuzAyahs = await _repo.getJuzWithTranslations(
        juzNumber,
        translationEditions: _translationEnabled
            ? _selectedTranslationEditions
            : const [],
      );
    } catch (e) {
      _error = e.toString();
    }
    _loadingContent = false;
    notifyListeners();
  }

  Future<void> setTranslationEnabled(bool enabled) async {
    _translationEnabled = enabled;
    _translationError = null;
    notifyListeners();
    await _saveTranslationPreferences();

    if (enabled) {
      await _ensureSelectedTranslations();
    }
    await _reloadCurrent();
  }

  Future<bool> selectTranslationEdition(String identifier) async {
    return setSelectedTranslationEditions([identifier]);
  }

  Future<bool> setSelectedTranslationEditions(List<String> identifiers) async {
    final uniqueIdentifiers = identifiers.toSet().toList();
    if (uniqueIdentifiers.length > 2) {
      _translationError = 'Select no more than two translations.';
      notifyListeners();
      return false;
    }
    final revision = ++_translationRequestRevision;
    _selectedTranslationEditions = uniqueIdentifiers;
    _translationError = null;
    notifyListeners();
    await _saveTranslationPreferences();

    final loaded = _translationEnabled
        ? await _ensureSelectedTranslations()
        : true;
    if (revision != _translationRequestRevision) return false;
    await _reloadCurrent();
    return loaded;
  }

  Future<void> loadTranslationEditions({bool refresh = false}) async {
    if (_loadingTranslationEditions) return;
    _loadingTranslationEditions = true;
    _translationError = null;
    notifyListeners();

    try {
      final editions = await _repo.getTranslationEditions(refresh: refresh);
      _translationEditions = editions;
      _downloadedTranslationEditions = await _repo
          .getDownloadedTranslationEditions();
    } catch (error) {
      _translationError = error.toString();
    } finally {
      _loadingTranslationEditions = false;
      notifyListeners();
    }
  }

  Future<bool> downloadTranslationEdition(String identifier) async {
    if (_downloadedTranslationEditions.contains(identifier)) return true;
    if (_downloadingTranslationEdition != null) return false;

    _translationError = null;
    _downloadingTranslationEdition = identifier;
    notifyListeners();
    try {
      await _repo.ensureTranslationDownloaded(identifier);
      _downloadedTranslationEditions = {
        ..._downloadedTranslationEditions,
        identifier,
      };
      return true;
    } catch (error) {
      _translationError = error.toString();
      return false;
    } finally {
      _downloadingTranslationEdition = null;
      notifyListeners();
    }
  }

  Future<bool> _ensureSelectedTranslations() async {
    _translationError = null;
    var allDownloaded = true;
    for (final edition in _selectedTranslationEditions) {
      if (_downloadedTranslationEditions.contains(edition)) continue;
      final downloaded = await downloadTranslationEdition(edition);
      if (!downloaded) {
        allDownloaded = false;
        break;
      }
    }
    return allDownloaded;
  }

  Future<void> _loadTranslationPreferences() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _translationEnabled = preferences.getBool(_showTranslationKey) ?? false;
      final savedEditions = preferences.getStringList(_translationEditionsKey);
      _selectedTranslationEditions =
          savedEditions ??
          [
            preferences.getString(_translationEditionKey) ??
                _defaultTranslationEdition,
          ];
      if (_selectedTranslationEditions.length > 2) {
        _selectedTranslationEditions = [_defaultTranslationEdition];
      }
      _arabicFontFamily =
          preferences.getString(_arabicFontFamilyKey) ??
          _defaultArabicFontFamily;
    } catch (error) {
      debugPrint('Failed to load translation preferences: $error');
    }
  }

  Future<void> _saveTranslationPreferences() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_showTranslationKey, _translationEnabled);
      await preferences.setString(
        _translationEditionKey,
        selectedTranslationEdition,
      );
      await preferences.setStringList(
        _translationEditionsKey,
        _selectedTranslationEditions,
      );
      await preferences.setString(_arabicFontFamilyKey, _arabicFontFamily);
    } catch (error) {
      _translationError = 'Could not save translation settings: $error';
      debugPrint(_translationError);
      notifyListeners();
    }
  }

  Future<void> _reloadCurrent() async {
    if (_currentSurah != null) {
      await loadSurah(_currentSurah!.surah.number);
    } else if (_currentJuzAyahs != null && _currentJuzNumber != null) {
      await loadJuz(_currentJuzNumber!);
    } else {
      notifyListeners();
    }
  }

  void toggleBookmark(int surahNum, [int? ayahNum]) {
    final key = ayahNum != null ? '$surahNum:$ayahNum' : '$surahNum';
    if (_bookmarks.contains(key)) {
      _bookmarks.remove(key);
    } else {
      _bookmarks.add(key);
    }
    notifyListeners();
  }

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

  Future<void> setArabicFontFamily(String family) async {
    _arabicFontFamily = family;
    notifyListeners();
    await _saveTranslationPreferences();
  }

  void saveLastRead(int surahNum, int ayahNum) {
    _lastSurahNumber = surahNum;
    _lastAyahNumber = ayahNum;
    notifyListeners();
  }
}
