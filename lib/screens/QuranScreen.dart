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
import 'package:toastification/toastification.dart';

import '../utils/QuranAudioPlayer.dart';

class QuranHomeScreen extends StatefulWidget {
  const QuranHomeScreen({super.key});


  @override
  State<QuranHomeScreen> createState() => _QuranHomeScreenState();

}

class _QuranHomeScreenState extends State<QuranHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> juzNames = [
    "Alif Lam Meem", "Sayaqool", "Tilkal Rusul", "Lan Tana Loo",
    "Wal Mohsanat", "La Yuhibbullah", "Wa Iza Samiu", "Wa Lau Annana",
    "Qalal Malao", "Wa'lamu", "Ya'taziroon", "Wa Ma Min Daabbatin",
    "Wa Ma Ubabrioo", "Rubama", "Subhanallazi", "Qala Alam",
    "Iqtaraba Linnasi", "Qad Aflaha", "Wa Qalallazina", "Amman Khalaqa",
    "Utlu Ma Oohiya", "Wa Man Yaqnut", "Wa Maliya", "Faman Azlamu",
    "Ilaihi Yuraddu", "Ha Meem", "Qala Fama Khatbukum", "Qad Sami Allah",
    "Tabarakallazi", "Amma Yatasa'aloon",
  ];

  final List<String> juzNamesUrdu = [
    "الف لآم میم", "سیقول", "تلك الرسل", "لن تنالوا", "والحصنت",
    "لا یحب اللہ", "و اذا سمعوا", "و لو اننا", "قال الملأ", "واعلموا",
    "یعتذرون", "و ما من دآبۃ", "و ما ابرئ", "ربما", "سبحن الذی",
    "قال الم", "اقترب للناس", "قد افلح", "و قال الذین", "امن خلق",
    "اتل ما اوحی", "و من یقنت", "و مالی", "فمن اظلم", "الیہ یرد",
    "حم", "قال فما خطبکم", "قد سمع اللہ", "تبارك الذی", "عم یتسآءلون",
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

  Future<void> _onPlaySurahTap(BuildContext context, dynamic surah) async {
    final player = context.read<QuranAudioPlayer>();
    final surahNumber = surah.number as int;
    final totalAyahs = surah.numberOfAyahs as int;
    final surahName = surah.englishName as String? ?? 'Surah';

    // ── CASE 1: this surah is currently playing → pause ──
    if (player.isPlayingSurah(surahNumber)) {
      await player.pause();
      return;
    }

    // ── CASE 2: this surah is paused → resume ──
    if (player.isPausedSurah(surahNumber)) {
      await player.resume();
      return;
    }

    // ── CASE 3: this surah is currently downloading → ignore taps ──
    if (player.isDownloadingSurah(surahNumber)) {
      return;
    }

    // ── CASE 4: fully cached for the selected reciter → play instantly ──
    final fullyCached = await player.isSurahFullyCached(
      surahNumber: surahNumber,
      totalAyahs: totalAyahs,
    );

    if (fullyCached) {
      await player.playCachedSurah(
        surahNumber: surahNumber,
        totalAyahs: totalAyahs,
        surahName: surahName,
      );
      return;
    }

    // ── CASE 5: not cached → show reciter picker ──
    if (!context.mounted) return;
    final pickedReciter = await _showReciterPickerSheet(context, surah);

    if (pickedReciter == null) return; // user dismissed
    if (!context.mounted) return;

    // Check cache for the PICKED reciter
    final cachedForPicked = await player.isSurahFullyCached(
      surahNumber: surahNumber,
      totalAyahs: totalAyahs,
      reciterId: pickedReciter.id,
    );

    if (!context.mounted) return;

    if (cachedForPicked) {
      // Already cached for this reciter → instant play
      await player.playCachedSurah(
        surahNumber: surahNumber,
        totalAyahs: totalAyahs,
        surahName: surahName,
      );
      return;
    }

    // ── CASE 6: download + play ──
    try {
      await player.downloadAndPlaySurah(
        surahNumber: surahNumber,
        totalAyahs: totalAyahs,
        surahName: surahName,
      );
    } catch (e) {
      if (!context.mounted) return;
      toastification.show(
        type: ToastificationType.error,
        title: Text('Download failed: $e'),
        context: context,
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark, statusBarBrightness: Brightness.light));
    return ColoredBox(
        color: AppTheme.background,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              _buildMainList(),
              const _DownloadProgressOverlay(),
            ],
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
              children: const [
                Text(
                  'DIVINE RECITATION',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.gold,
                  ),
                ),
                Text(
                  'Holy Quran',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _circleIcon(customIcons.search),
          ],
        ),
    );
  }

  Widget _circleIcon(IconData icon) {
    return InkWell(
      radius: 20,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen(),)),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 26, color: AppTheme.primary),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB PILLS
  // ─────────────────────────────────────────────────────────────
  Widget _buildTabPills() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            _pillTab(label: 'Surah', index: 0),
            _pillTab(label: 'Juz (Paras)', index: 1),
          ],
        ),
      ),
    );
  }

  Widget _pillTab({required String label, required int index}) {
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
                      const Text(
                        'LAST RECITED',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Surah Al-Kahf',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ayah 10 • Juz 15',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                elevation: 3,
              ),
              icon: const Text(
                'Continue',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              label: const Icon(Icons.play_arrow, size: 18),
            ),
          ],
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
    if (provider.loadingList) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: provider.surahs.length,
      itemBuilder: (context, index) {
        final surah = provider.surahs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _surahCard(surah),
        );
      },
    );
  }

  Widget _surahCard(dynamic surah) {
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  // ✅ FIXED: nameTranslation (not englishNameTranslation)
                  Text(
                    surah.nameTranslation,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
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
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${surah.numberOfAyahs} Ayahs',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
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
                Consumer<QuranAudioPlayer>(
                  builder: (context, player, _) {
                    final surahNumber = surah.number as int;
                    final isPlaying = player.isPlayingSurah(surahNumber);
                    final isPaused = player.isPausedSurah(surahNumber);
                    final isDownloading = player.isDownloadingSurah(surahNumber);

                    // Icon + progress
                    Widget iconChild;
                    if (isDownloading) {
                      iconChild = SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          value: player.downloadingSurahNumber == surahNumber
                              ? player.overallProgress
                              : null,
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                        ),
                      );
                    } else if (isPlaying) {
                      iconChild =  Icon(CupertinoIcons.pause,
                          size: 20, color: AppTheme.primary);
                    } else if (isPaused) {
                      iconChild = const Icon(customIcons.play,
                          size: 20, color: AppTheme.primary);
                    } else {
                      iconChild = Icon(customIcons.play,
                          applyTextScaling: false,
                          size: 18, color: AppTheme.primary);
                    }

                    return Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: isPlaying || isPaused
                            ? AppTheme.gold.withOpacity(0.20)
                            : AppTheme.surfaceContainer,
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        radius: 20,
                        onTap: () => _onPlaySurahTap(context, surah),
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
                    _starBadge(text: '$juzNumber', size: 46),
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
  Widget _starBadge({required String text, double size = 44}) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer star (light gold fill)
          Icon(
            Icons.star,
            size: size,
            color: AppTheme.gold.withOpacity(0.35),
          ),
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

  Future<Reciter?> _showReciterPickerSheet(
      BuildContext context,
      dynamic surah,
      ) async {
    final player = context.read<QuranAudioPlayer>();
    final surahNumber = surah.number as int;
    final totalAyahs = surah.numberOfAyahs as int;

    // Precompute cache status for each reciter
    final Map<String, bool> cachedMap = {};
    for (final rec in QuranAudioPlayer.reciters) {
      cachedMap[rec.id] = await player.isSurahFullyCached(
        surahNumber: surahNumber,
        totalAyahs: totalAyahs,
        reciterId: rec.id,
      );
    }

    if (!context.mounted) return null;

    return showModalBottomSheet<Reciter>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                // Handle
                Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Play ${surah.englishName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Select a Qari (Reciter)',
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
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    itemCount: QuranAudioPlayer.reciters.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 76),
                    itemBuilder: (context, i) {
                      final rec = QuranAudioPlayer.reciters[i];
                      final isSelected = player.selectedReciter.id == rec.id;
                      final isCached = cachedMap[rec.id] ?? false;

                      return ListTile(
                        leading: ClipOval(
                          child: Image.network(
                            rec.imageAsset,
                            width: 46,
                            height: 46,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 46, height: 46,
                              color: AppTheme.surfaceContainer,
                              child: const Icon(Icons.person,
                                  color: AppTheme.primary),
                            ),
                          ),
                        ),
                        title: Text(
                          rec.name,
                          style: TextStyle(
                            fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                            color: AppTheme.primary,
                          ),
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
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle,
                                  size: 14, color: AppTheme.primary),
                              SizedBox(width: 4),
                              Text(
                                'Downloaded ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                            : const Icon(Icons.download_rounded,
                            size: 20, color: AppTheme.gold),
                        onTap: () {
                          player.setReciter(rec);
                          Navigator.pop(sheetCtx, rec);
                        },
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
    return Consumer<QuranAudioPlayer>(
      builder: (context, player, _) {
        if (player.downloadState != SurahDownloadState.downloading) {
          return const SizedBox.shrink();
        }
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
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppTheme.gold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Downloading Surah ${player.downloadingSurahNumber}… '
                              '${player.downloadedCount}/${player.totalAyahsToDownload}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${(player.overallProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => player.cancelDownload(),
                        child: const Icon(Icons.close,
                            color: Colors.white70, size: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: player.overallProgress,
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      valueColor:
                      const AlwaysStoppedAnimation(AppTheme.gold),
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