import 'package:flutter_test/flutter_test.dart';
import 'package:quranpak/models/TranslationEdition.dart';
import 'package:quranpak/models/models.dart';
import 'package:quranpak/widgets/TranslationLanguageTabs.dart';

void main() {
  test('labels English and Urdu translation categories by language', () {
    expect(translationLanguageLabel('en'), 'English');
    expect(translationLanguageLabel('ur'), 'Urdu');
    expect(translationEditionLanguageLabel('en', 'Sahih International'),
        'English · Sahih International');
    expect(translationLanguageLabel('unmapped'), 'Other language');
  });

  group('TranslationEdition', () {
    const edition = TranslationEdition(
      identifier: 'ur.ahmedali',
      language: 'ur',
      name: 'احمد علی',
      englishName: 'Ahmed Ali',
    );

    test('serializes edition metadata for local caching', () {
      final restored = TranslationEdition.fromMap(edition.toMap());

      expect(restored.identifier, edition.identifier);
      expect(restored.language, edition.language);
      expect(restored.name, edition.name);
      expect(restored.englishName, edition.englishName);
    });

    test('parses edition metadata from the API catalog', () {
      final restored = TranslationEdition.fromJson({
        'identifier': 'ur.ahmedali',
        'language': 'ur',
        'name': 'احمد علی',
        'englishName': 'Ahmed Ali',
      });

      expect(restored.identifier, edition.identifier);
      expect(restored.language, edition.language);
      expect(restored.name, edition.name);
      expect(restored.englishName, edition.englishName);
    });
  });

  test('maps selected translation text onto its ayah', () {
    final ayah = Ayah.fromMap(
      {
        'number_in_surah': 1,
        'arabic_text': 'بِسْمِ اللَّهِ',
        'translation_text': 'In the name of Allah',
        'second_translation_text': "Au nom d'Allah",
        'juz': 1,
        'manzil': 1,
        'page': 1,
      },
      surahNumber: 1,
      surahName: 'الفاتحة',
      surahEnglishName: 'Al-Fatihah',
    );

    expect(ayah.translation, 'In the name of Allah');
    expect(ayah.secondTranslation, "Au nom d'Allah");
  });
}
