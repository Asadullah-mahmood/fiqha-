import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/models/models.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:quranpak/widgets/AyahCard.dart';
import 'package:quranpak/widgets/TranslationLanguageTabs.dart';

class TranslationQuranReaderScreen extends StatefulWidget {
  final int? surahNumber;
  final int? juzNumber;

  const TranslationQuranReaderScreen({
    super.key,
    this.surahNumber,
    this.juzNumber,
  });

  @override
  State<TranslationQuranReaderScreen> createState() =>
      _TranslationQuranReaderScreenState();
}

class _TranslationQuranReaderScreenState
    extends State<TranslationQuranReaderScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadContent();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadContent() async {
    final provider = context.read<QuranProvider>();
    if (!provider.translationEnabled) {
      provider.setTranslationEnabled(true);
    }
    if (widget.surahNumber != null) {
      await provider.loadSurah(widget.surahNumber!);
    } else if (widget.juzNumber != null) {
      await provider.loadJuz(widget.juzNumber!);
    }
  }

  void _showTranslationSheet() {
    final provider = context.read<QuranProvider>();
    var selectedLanguage = provider.selectedTranslationEdition
        .split('.')
        .first
        .toLowerCase();
    unawaited(provider.loadTranslationEditions());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        var selected = List<String>.from(provider.selectedTranslationEditions);
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) => Consumer<QuranProvider>(
            builder: (context, p, _) {
              final languages = p.translationEditions
                  .map((edition) => edition.language.toLowerCase())
                  .where((language) => language.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort(
                  (a, b) => translationLanguageLabel(
                    a,
                  ).compareTo(translationLanguageLabel(b)),
                );
              if (!languages.contains(selectedLanguage)) {
                selectedLanguage = 'all';
              }
              final filtered = p.translationEditions.where((edition) {
                final normalized = query.toLowerCase().trim();
                final language = edition.language.toLowerCase();
                final matchesLanguage =
                    selectedLanguage == 'all' || language == selectedLanguage;
                final matchesQuery = normalized.isEmpty ||
                    language.contains(normalized) ||
                    edition.name.toLowerCase().contains(normalized) ||
                    edition.englishName.toLowerCase().contains(normalized) ||
                    edition.identifier.toLowerCase().contains(normalized);
                return matchesLanguage && matchesQuery;
              }).toList();

              return SafeArea(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        'Choose Translations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search language or translator',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) =>
                              setSheetState(() => query = value),
                        ),
                      ),
                      TranslationLanguageTabs(
                        languages: languages,
                        selectedLanguage: selectedLanguage,
                        onSelected: (language) {
                          setSheetState(() => selectedLanguage = language);
                        },
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final edition = filtered[index];
                            final isSelected =
                                selected.contains(edition.identifier);
                            return CheckboxListTile(
                              title: Text(edition.englishName),
                              subtitle: Text(
                                '${edition.name} • ${translationLanguageLabel(edition.language)}',
                              ),
                              value: isSelected,
                              onChanged: (checked) {
                                setSheetState(() {
                                  if (checked == true) {
                                    if (selected.length >= 2) selected.removeAt(0);
                                    selected.add(edition.identifier);
                                  } else {
                                    selected.remove(edition.identifier);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                            ),
                            onPressed: () async {
                              await p.setSelectedTranslationEditions(selected);
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                            child: Text(
                              'Apply ${selected.length} translation(s)',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, provider, _) {
        final loadedAyahs =
            provider.currentSurah?.ayahs ?? provider.currentJuzAyahs;
        final surahTitle = provider.currentSurah?.surah.englishName ??
            (widget.juzNumber != null ? 'Juz ${widget.juzNumber}' : 'Quran Study');
        final arabicTitle = provider.currentSurah?.surah.name ?? '';

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  surahTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (arabicTitle.isNotEmpty)
                  Text(
                    arabicTitle,
                    style: GoogleFonts.notoSansArabic(
                      fontSize: 13,
                      color: AppTheme.gold,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Select Translations',
                icon: const Icon(Icons.translate_rounded, color: AppTheme.gold),
                onPressed: _showTranslationSheet,
              ),
            ],
          ),
          body: provider.loadingContent
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : (loadedAyahs == null || loadedAyahs.isEmpty)
                  ? Center(
                      child: Text(
                        provider.error ?? 'Content not available',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      itemCount: loadedAyahs.length,
                      itemBuilder: (context, index) {
                        final ayah = loadedAyahs[index];
                        final surahNum = widget.surahNumber ?? ayah.surahNumber;
                        return AyahCard(
                          ayah: ayah,
                          surahNumber: surahNum,
                          onChangeTranslation: _showTranslationSheet,
                        );
                      },
                    ),
        );
      },
    );
  }
}

