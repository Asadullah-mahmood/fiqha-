import 'package:flutter/material.dart';
import 'package:quranpak/utils/AppTheme.dart';

String translationLanguageLabel(String languageCode) {
  return switch (languageCode.toLowerCase()) {
    'af' => 'Afrikaans',
    'sq' => 'Albanian',
    'am' => 'Amharic',
    'ar' => 'Arabic',
    'az' => 'Azerbaijani',
    'bn' => 'Bengali',
    'bs' => 'Bosnian',
    'bg' => 'Bulgarian',
    'zh' => 'Chinese',
    'cs' => 'Czech',
    'dv' => 'Divehi',
    'nl' => 'Dutch',
    'en' => 'English',
    'fi' => 'Finnish',
    'fr' => 'French',
    'de' => 'German',
    'el' => 'Greek',
    'gu' => 'Gujarati',
    'ha' => 'Hausa',
    'he' => 'Hebrew',
    'hi' => 'Hindi',
    'id' => 'Indonesian',
    'it' => 'Italian',
    'ja' => 'Japanese',
    'ko' => 'Korean',
    'ku' => 'Kurdish',
    'ky' => 'Kyrgyz',
    'mk' => 'Macedonian',
    'ms' => 'Malay',
    'ml' => 'Malayalam',
    'mr' => 'Marathi',
    'ne' => 'Nepali',
    'no' => 'Norwegian',
    'or' => 'Odia',
    'ps' => 'Pashto',
    'fa' => 'Persian',
    'pl' => 'Polish',
    'pt' => 'Portuguese',
    'ro' => 'Romanian',
    'ru' => 'Russian',
    'sd' => 'Sindhi',
    'so' => 'Somali',
    'es' => 'Spanish',
    'sw' => 'Swahili',
    'sv' => 'Swedish',
    'ta' => 'Tamil',
    'tg' => 'Tajik',
    'th' => 'Thai',
    'tl' => 'Tagalog',
    'tr' => 'Turkish',
    'tt' => 'Tatar',
    'uk' => 'Ukrainian',
    'ur' => 'Urdu',
    'ug' => 'Uyghur',
    'uz' => 'Uzbek',
    'vi' => 'Vietnamese',
    'yo' => 'Yoruba',
    '' => 'Unknown',
    _ => 'Other language',
  };
}

String translationEditionLanguageLabel(String languageCode, String name) {
  final languageName = translationLanguageLabel(languageCode);
  final editionName = name.trim();
  if (editionName.isEmpty ||
      editionName.toLowerCase() == languageName.toLowerCase()) {
    return languageName;
  }
  return '$languageName · $editionName';
}

class TranslationLanguageTabs extends StatelessWidget {
  final List<String> languages;
  final String selectedLanguage;
  final ValueChanged<String> onSelected;

  const TranslationLanguageTabs({
    required this.languages,
    required this.selectedLanguage,
    required this.onSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = ['all', ...languages];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final language in tabs)
            InkWell(
              onTap: () => onSelected(language),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: language == selectedLanguage
                          ? AppTheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  language == 'all'
                      ? 'All languages'
                      : translationLanguageLabel(language),
                  style: TextStyle(
                    color: language == selectedLanguage
                        ? AppTheme.primary
                        : AppTheme.textSecondary,
                    fontWeight: language == selectedLanguage
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
