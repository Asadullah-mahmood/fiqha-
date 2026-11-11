import 'package:quranpak/screens/TranslationQuranReaderScreen.dart';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/screens/SearchScreen.dart';
import 'package:quranpak/screens/SurahReaderScreen.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:quranpak/widgets/customIcons.dart';
import 'package:quranpak/widgets/TranslationLanguageTabs.dart';
import 'package:toastification/toastification.dart';

import '../models/FullSurahReciter.dart';
import '../services/FullSurahDownloadProvider.dart';
import '../models/LastReadProgress.dart';
import '../utils/LastReadProvider.dart';
import '../utils/FullSurahPlayer.dart';

class QuranHomeScreen extends StatefulWidget {
  const QuranHomeScreen({super.key});

  @override
  State<QuranHomeScreen> createState() => _QuranHomeScreenState();
}

class _QuranHomeScreenState extends State<QuranHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> juzNames = [
    "Alif Lam Meem",
    "Sayaqool",
    "Tilkal Rusul",
    "Lan Tana Loo",
    "Wal Mohsanat",
    "La Yuhibbullah",
    "Wa Iza Samiu",
    "Wa Lau Annana",
    "Qalal Malao",
    "Wa'lamu",
    "Ya'taziroon",
    "Wa Ma Min Daabbatin",
    "Wa Ma Ubabrioo",
    "Rubama",
    "Subhanallazi",
    "Qala Alam",
    "Iqtaraba Linnasi",
    "Qad Aflaha",
    "Wa Qalallazina",
    "Amman Khalaqa",
    "Utlu Ma Oohiya",
    "Wa Man Yaqnut",
    "Wa Maliya",
    "Faman Azlamu",
    "Ilaihi Yuraddu",
    "Ha Meem",
    "Qala Fama Khatbukum",
    "Qad Sami Allah",
    "Tabarakallazi",
    "Amma Yatasa'aloon",
  ];

  final List<String> juzNamesUrdu = [
    "الف لآم میم",
    "سیقول",
    "تلك الرسل",
    "لن تنالوا",
    "والحصنت",
    "لا یحب اللہ",
    "و اذا سمعوا",
    "و لو اننا",
    "قال الملأ",
    "واعلموا",
    "یعتذرون",
    "و ما من دآبۃ",
    "و ما ابرئ",
    "ربما",
    "سبحن الذی",
    "قال الم",
    "اقترب للناس",
    "قد افلح",
    "و قال الذین",
    "امن خلق",
    "اتل ما اوحی",
    "و من یقنت",
    "و مالی",
    "فمن اظلم",
    "الیہ یرد",
    "حم",
    "قال فما خطبکم",
    "قد سمع اللہ",
    "تبارك الذی",
    "عم یتسآءلون",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _playSurah(
    BuildContext context,
    int surahNumber,
    String surahName,
  ) async {
    final dl = context.read<FullSurahDownloadProvider>();
    final player = context.read<FullSurahPlayer>();

    // ── 1. Ask the user which reciter to use ──
    final reciter = await _showFullSurahReciterPicker(
      context,
      surahNumber: surahNumber,
      surahName: surahName,
    );
    if (reciter == null) return; // user cancelled
    if (!context.mounted) return;

    // ── 2. Remember the choice ──
    await dl.setDefaultReciter(reciter.id);

    // ── 3. Check if downloaded. If not, download first then play. ──
    final downloaded = await dl.isSurahDownloaded(
      surahNumber,
      reciterId: reciter.id,
    );

    if (downloaded) {
      await player.playDownloaded(
        surahNumber: surahNumber,
        reciterId: reciter.id,
        surahName: surahName,
      );
      if (!context.mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.flatColored,
        title: const Text('Playing Tilawat'),
        description: Text('${reciter.name} • $surahName'),
        autoCloseDuration: const Duration(seconds: 2),
        icon: const Icon(Icons.play_circle_fill),
      );
    } else {
      if (!context.mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.info,
        style: ToastificationStyle.flatColored,
        title: const Text('Downloading Tilawat...'),
        description: Text('Downloading $surahName for ${reciter.name}'),
        autoCloseDuration: const Duration(seconds: 3),
        icon: const Icon(Icons.cloud_download),
      );

      try {
        await dl.downloadSurah(surahNumber, reciterId: reciter.id);
        if (!context.mounted) return;
        await player.playDownloaded(
          surahNumber: surahNumber,
          reciterId: reciter.id,
          surahName: surahName,
        );
        if (!context.mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          title: const Text('Download complete'),
          description: Text('Now playing \ (\)'),
          autoCloseDuration: const Duration(seconds: 2),
          icon: const Icon(Icons.offline_pin),
        );
      } catch (e) {
        if (!context.mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: const Text('Download failed'),
          description: Text('Could not download audio: '),
          autoCloseDuration: const Duration(seconds: 3),
          icon: const Icon(Icons.error_outline),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    return ColoredBox(
      color: AppTheme.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [_buildMainList(), const _DownloadProgressOverlay()],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MAIN LIST
  // ─────────────────────────────────────────────────────────────
  Widget _buildMainList() {
    return Consumer<QuranProvider>(
      builder: (context, provider, _) {
        return NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              //    SliverToBoxAdapter(child: _buildTopHeader()),
              SliverToBoxAdapter(child: _buildTitleRow()),
              SliverToBoxAdapter(child: _buildTabPills()),
              SliverToBoxAdapter(child: _buildLastRecitedCard()),
              SliverToBoxAdapter(child: _buildAllSurahsRow(provider)),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildSurahListView(provider),
              _buildJuzListView(provider),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TITLE ROW
  // ─────────────────────────────────────────────────────────────
  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DIVINE RECITATION',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gold,
                ),
                textScaler: TextScaler.linear(1),
              ),
              const Text(
                'Al-Quran al-Kareem',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                  height: 1.2,
                ),
                textScaler: TextScaler.linear(1),
              ),
            ],
          ),
          const Spacer(),
          _translationIcon(),
          const SizedBox(width: 8),
          _circleIcon(customIcons.search),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return InkWell(
      radius: 20,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SearchScreen()),
      ),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 26, color: AppTheme.primary),
      ),
    );
  }

  Widget _translationIcon() {
    return Consumer<QuranProvider>(
      builder: (context, provider, _) {
        if (!provider.translationEnabled) return const SizedBox.shrink();
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _showTranslationPicker,
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.translate,
              size: 23,
              color: AppTheme.primary,
            ),
          ),
        );
      },
    );
  }

  void _showTranslationPicker() {
    final provider = context.read<QuranProvider>();
    var query = '';
    var selectedLanguage = provider.selectedTranslationEdition
        .split('.')
        .first
        .toLowerCase();
    var selectedEditions = List<String>.from(
      provider.selectedTranslationEditions,
    );
    unawaited(provider.loadTranslationEditions());
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Consumer<QuranProvider>(
        builder: (context, translationProvider, _) => StatefulBuilder(
          builder: (context, setSheetState) {
            final languages =
                translationProvider.translationEditions
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
            final filteredEditions = translationProvider.translationEditions
                .where((edition) {
                  final normalizedQuery = query.toLowerCase().trim();
                  final language = edition.language.toLowerCase();
                  final matchesLanguage =
                      selectedLanguage == 'all' || language == selectedLanguage;
                  final matchesQuery =
                      normalizedQuery.isEmpty ||
                      language.contains(normalizedQuery) ||
                      edition.name.toLowerCase().contains(normalizedQuery) ||
                      edition.englishName.toLowerCase().contains(
                        normalizedQuery,
                      ) ||
                      edition.identifier.toLowerCase().contains(
                        normalizedQuery,
                      );
                  return matchesLanguage && matchesQuery;
                })
                .toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.82,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Translations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Refresh available translations',
                            onPressed:
                                translationProvider.loadingTranslationEditions
                                ? null
                                : () => unawaited(
                                    translationProvider.loadTranslationEditions(
                                      refresh: true,
                                    ),
                                  ),
                            icon: const Icon(Icons.refresh),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search language or translator',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppTheme.surfaceContainer,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setSheetState(() {
                            query = value;
                          });
                        },
                      ),
                    ),
                    TranslationLanguageTabs(
                      languages: languages,
                      selectedLanguage: selectedLanguage,
                      onSelected: (language) {
                        setSheetState(() => selectedLanguage = language);
                      },
                    ),
                    if (translationProvider.translationError != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          translationProvider.translationError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (translationProvider.downloadingTranslationEdition !=
                        null)
                      const LinearProgressIndicator(color: AppTheme.primary),
                    if (translationProvider.loadingTranslationEditions &&
                        translationProvider.translationEditions.isEmpty)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primary,
                          ),
                        ),
                      )
                    else if (filteredEditions.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('No matching translation editions.'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredEditions.length,
                          itemBuilder: (context, index) {
                            final edition = filteredEditions[index];
                            final selected = selectedEditions.contains(
                              edition.identifier,
                            );
                            final downloaded = translationProvider
                                .downloadedTranslationEditions
                                .contains(edition.identifier);
                            final downloading =
                                translationProvider
                                    .downloadingTranslationEdition ==
                                edition.identifier;
                            final languageLabel =
                                translationEditionLanguageLabel(
                                  edition.language,
                                  edition.name,
                                );
                            return ListTile(
                              leading: Icon(
                                downloaded
                                    ? Icons.offline_pin
                                    : Icons.translate,
                                color: AppTheme.primary,
                              ),
                              title: Text(
                                edition.englishName.isNotEmpty
                                    ? edition.englishName
                                    : edition.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                languageLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (downloading)
                                    const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    IconButton(
                                      tooltip: downloaded
                                          ? 'Downloaded'
                                          : 'Download $languageLabel translation',
                                      onPressed:
                                          downloaded ||
                                              translationProvider
                                                      .downloadingTranslationEdition !=
                                                  null
                                          ? null
                                          : () => unawaited(
                                              translationProvider
                                                  .downloadTranslationEdition(
                                                    edition.identifier,
                                                  ),
                                            ),
                                      icon: Icon(
                                        downloaded
                                            ? Icons.download_done
                                            : Icons.download_outlined,
                                      ),
                                      color: downloaded
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                    ),
                                  Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: selected
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (selected) {
                                  setSheetState(
                                    () => selectedEditions.remove(
                                      edition.identifier,
                                    ),
                                  );
                                } else if (selectedEditions.length < 2) {
                                  setSheetState(
                                    () => selectedEditions.add(
                                      edition.identifier,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'You can select up to two translations.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
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
                          onPressed:
                              translationProvider
                                      .downloadingTranslationEdition !=
                                  null
                              ? null
                              : () async {
                                  final saved = await translationProvider
                                      .setSelectedTranslationEditions(
                                        selectedEditions,
                                      );
                                  if (saved && sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                },
                          child: Text(
                            translationProvider.downloadingTranslationEdition !=
                                    null
                                ? 'Downloading ${translationProvider.downloadingTranslationEdition}...'
                                : 'Apply ${selectedEditions.length} translation${selectedEditions.length == 1 ? '' : 's'}',
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB PILLS
  // ─────────────────────────────────────────────────────────────
  Widget _buildTabPills() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          // ── Surah vs Juz (Paras) Tabs ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              children: [
                pillTab(label: 'Surah', index: 0),
                pillTab(label: 'Juz (Paras)', index: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget pillTab({required String label, required int index}) {
    final selected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: selected ? AppTheme.gold : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LAST RECITED CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildLastRecitedCard() {
    return Consumer<LastReadProvider>(
      builder: (context, lastReadProvider, _) {
        final progress = lastReadProvider.progress;
        final surahName = progress == null
            ? 'Al-Fatihah'
            : progress.surahEnglishName.isNotEmpty
            ? progress.surahEnglishName
            : 'Surah ${progress.surahNumber}';
        final juzNumber = progress?.juzNumber ?? 1;
        final juzName = juzNames[juzNumber - 1];
        final details = progress == null
            ? 'Start at Ayah 1 • Juz 1 · $juzName'
            : 'Ayah ${progress.ayahNumber} • Juz $juzNumber · $juzName';

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppTheme.gold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            progress == null
                                ? 'START RECITING'
                                : 'LAST RECITED',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.gold,
                            ),
                            textScaler: TextScaler.linear(1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Surah $surahName',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textScaler: TextScaler.linear(1),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        details,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.75),
                        ),
                        textScaler: TextScaler.linear(1),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => openLastRead(progress),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    elevation: 3,
                  ),
                  icon: Text(
                    progress == null ? 'Start Quran' : 'Continue',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    textScaler: TextScaler.linear(1),
                  ),
                  label: const Icon(Icons.play_arrow, size: 18),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void openLastRead(LastReadProgress? progress) {
    if (progress == null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const SurahReaderScreen(surahNumber: 1, scrollToAyah: 1),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => progress.readerType == 'juz'
            ? SurahReaderScreen(
                juzNumber: progress.readerSectionNumber,
                scrollToAyah: progress.ayahNumber,
                scrollToSurah: progress.surahNumber,
              )
            : SurahReaderScreen(
                surahNumber: progress.surahNumber,
                scrollToAyah: progress.ayahNumber,
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // ALL SURAHS ROW
  // ─────────────────────────────────────────────────────────────
  Widget _buildAllSurahsRow(QuranProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          Text(
            'All Surahs (${provider.surahs.length})',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const Spacer(),
          Row(
            children: const [
              Icon(Icons.swap_vert, size: 16, color: AppTheme.gold),
              SizedBox(width: 4),
              Text(
                'Standard Order',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // SURAH LIST
  // ─────────────────────────────────────────────────────────────
  Widget _buildSurahListView(QuranProvider provider) {
    // 1. Still loading
    if (provider.loadingList) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.primary),
            SizedBox(height: 12),
            Text(
              'Loading Quran...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // 2. Error happened (this is the key diagnostic you were missing)
    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.primary,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load surahs',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.bootstrap(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Genuinely empty
    if (provider.surahs.isEmpty) {
      return const Center(
        child: Text(
          'No surahs found. Check the download.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    // 4. Normal list
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: provider.surahs.length,
      itemBuilder: (context, index) {
        final surah = provider.surahs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: surahCard(surah),
        );
      },
    );
  }

  Widget surahCard(dynamic surah) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SurahReaderScreen(surahNumber: surah.number),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Star number badge
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.star,
                    size: 44,
                    color: AppTheme.gold.withOpacity(0.25),
                  ),
                  Text(
                    '${surah.number}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.gold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surah.englishName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                    textScaler: TextScaler.noScaling,
                  ),
                  // ✅ FIXED: nameTranslation (not englishNameTranslation)
                  Text(
                    surah.nameTranslation,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                    textScaler: TextScaler.noScaling,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          surah.revelationType ?? '',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                          ),
                          textScaler: TextScaler.noScaling,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${surah.numberOfAyahs} Ayahs',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        textScaler: TextScaler.noScaling,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  surah.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.primary,
                    fontFamily: 'Amiri',
                  ),
                ),
                const SizedBox(height: 4),
                // Inside _surahCard, replace the play-icon Container with:
                Consumer2<FullSurahPlayer, FullSurahDownloadProvider>(
                  builder: (context, fullPlayer, dlProvider, _) {
                    final surahNumber = surah.number as int;
                    final isThisSurah = fullPlayer.currentSurah == surahNumber;
                    final isPlaying = isThisSurah && fullPlayer.isPlaying;
                    final isPaused =
                        isThisSurah &&
                        !fullPlayer.isPlaying &&
                        fullPlayer.hasSurah;

                    final dlProgress = dlProvider.progress[surahNumber];
                    final isDownloading =
                        dlProgress?.status == SurahDlStatus.downloading ||
                        dlProgress?.status == SurahDlStatus.queued;

                    Widget iconChild;
                    if (isDownloading) {
                      iconChild = SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          value:
                              dlProgress?.status == SurahDlStatus.downloading &&
                                  dlProgress?.progress != null &&
                                  dlProgress!.progress > 0
                              ? dlProgress.progress
                              : null,
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation(
                            AppTheme.primary,
                          ),
                        ),
                      );
                    } else if (isPlaying) {
                      iconChild = const Icon(
                        CupertinoIcons.pause,
                        size: 20,
                        color: AppTheme.primary,
                      );
                    } else if (isPaused) {
                      iconChild = const Icon(
                        customIcons.play,
                        size: 20,
                        color: AppTheme.primary,
                      );
                    } else {
                      iconChild = const Icon(
                        customIcons.play,
                        applyTextScaling: false,
                        size: 18,
                        color: AppTheme.primary,
                      );
                    }

                    return Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isPlaying || isPaused
                            ? AppTheme.gold.withOpacity(0.20)
                            : AppTheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        radius: 20,
                        onTap: () {
                          if (isPlaying) {
                            fullPlayer.pause();
                          } else if (isPaused) {
                            fullPlayer.resume();
                          } else {
                            _playSurah(
                              context,
                              surahNumber,
                              surah.englishName ?? '',
                            );
                          }
                        },
                        child: Center(child: iconChild),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // JUZ LIST
  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  // JUZ LIST — with stars + Material fix
  // ─────────────────────────────────────────────────────────────
  Widget _buildJuzListView(QuranProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          // ✅ Material wrapper fixes "ListTile background/ink splashes may be invisible"
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SurahReaderScreen(juzNumber: juzNumber),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // ✅ Star badge instead of circle

                    starBadge(text: '$juzNumber', size: 46),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            juzNames[index],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            juzNamesUrdu[index],
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 14,
                              fontFamily: 'serif',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.gold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STAR BADGE — reusable 8-point star with centered text
  // ─────────────────────────────────────────────────────────────
  Widget starBadge({required String text, double size = 44}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer star (light gold fill)
          Icon(Icons.star, size: size, color: AppTheme.gold.withOpacity(0.35)),
          // Inner star (primary fill) for layered look
          Icon(
            Icons.star,
            size: size * 0.72,
            color: AppTheme.primary.withOpacity(0.08),
          ),
          // Number / text
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Future<FullSurahReciter?> _showFullSurahReciterPicker(
    BuildContext context, {
    required int surahNumber,
    required String surahName,
  }) async {
    final dl = context.read<FullSurahDownloadProvider>();

    // Precompute which reciters already have this surah cached
    final Map<String, bool> cachedMap = {};
    for (final rec in fullSurahReciters) {
      cachedMap[rec.id] = await dl.isSurahDownloaded(
        surahNumber,
        reciterId: rec.id,
      );
    }
    if (!context.mounted) return null;

    return showModalBottomSheet<FullSurahReciter>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Listen to $surahName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Choose a Qari (reciter)',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),

                // Reciter list
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    itemCount: fullSurahReciters.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 76),
                    itemBuilder: (context, i) {
                      final rec = fullSurahReciters[i];
                      final isCurrent = dl.selectedReciterId == rec.id;
                      final isCached = cachedMap[rec.id] ?? false;

                      return ListTile(
                        leading: ClipOval(
                          child: Image.network(
                            rec.imageAsset,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 46,
                              height: 46,
                              color: AppTheme.surfaceContainer,
                              child: const Icon(
                                Icons.person,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                rec.name,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.gold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'CURRENT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          rec.arabicName,
                          style: GoogleFonts.notoSansArabic(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: isCached
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: AppTheme.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Offline',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const Icon(
                                Icons.cloud_download_outlined,
                                size: 20,
                                color: AppTheme.gold,
                              ),
                        onTap: () => Navigator.pop(sheetCtx, rec),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _DownloadProgressOverlay extends StatelessWidget {
  const _DownloadProgressOverlay();

  @override
  Widget build(BuildContext context) {
    return Consumer<FullSurahDownloadProvider>(
      builder: (context, dl, _) {
        final active = dl.progress.values
            .where((p) => p.status == SurahDlStatus.downloading)
            .toList();
        if (active.isEmpty) return const SizedBox.shrink();

        // Show the first in-flight download
        final p = active.first;
        final recName = dl.selectedReciter.name;

        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            color: AppTheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppTheme.gold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Downloading Surah ${p.surahNumber} • $recName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${(p.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: p.progress,
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
