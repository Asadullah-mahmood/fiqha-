import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const Color primary = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF003300);
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF5E6A3);
  static const Color background = Color(0xFFF5F0E8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5D5D5D);
  static const Color arabicText = Color(0xFF1A1A2E);
  static const Color urduText = Color(0xFF2D1B69);
  static const Color englishText = Color(0xFF1A3A1A);
  static const Color divider = Color(0xFFD4AF3750);
  static const Color cardBg = Color(0xFFFFFBF0);
  static const Color verseNumBg = Color(0xFF1B5E20);

  // ✅ NEW — needed for the new QuranHomeScreen design
  static const Color surfaceContainer = Color(0xFFF1EEE6);
  static const Color surfaceContainerHigh = Color(0xFFEBE8E0);
  static const Color onSurfaceVariant = Color(0xFF404944);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        secondary: gold,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}

class AppStrings {
  static const String appName = 'قرآن پاک';
  static const String appNameEn = 'Quran Pak';
  static const String surahs = 'سورتیں';
  static const String search = 'تلاش کریں';
  static const String bookmarks = 'بک مارکس';
  static const String settings = 'ترتیبات';
  static const String urduTranslation = 'اردو ترجمہ';
  static const String englishTranslation = 'English Translation';
  static const String meccan = 'مکی';
  static const String medinan = 'مدنی';
  static const String verses = 'آیات';
  static const String juz = 'پارہ';
  static const String voiceSearch = 'آواز سے تلاش';
  static const String tapToSpeak = 'بولنے کے لیے تھپتھپائیں';
  static const String listening = 'سن رہا ہوں...';
}