import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/models/models.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Arabic-Indic numerals helper (used everywhere numbers are shown) ──
String toArabicNumerals(int n) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => digits[int.parse(c)]).join();
}

// ── Translation accessors ──
// ⚠️ If your Ayah model uses different field names, change ONLY these two lines.
String? _urduTranslationOf(Ayah a) => a.textUrdu;
String? _englishTranslationOf(Ayah a) => a.textEnglish;

// ── Para (Juz) names in Arabic — index 0 = Juz 1 ──
const List<String> juzNamesArabic = [
  "الٓمٓ",
  "سَيَقُولُ",
  "تِلْكَ الرُّسُلُ",
  "لَن تَنَالُوا",
  "وَالْمُحْصَنَاتُ",
  "لَا يُحِبُّ اللَّهُ",
  "وَإِذَا سَمِعُوا",
  "وَلَوْ أَنَّنَا",
  "قَالَ الْمَلَأُ",
  "وَاعْلَمُوا",
  "يَعْتَذِرُونَ",
  "وَمَا مِن دَابَّةٍ",
  "وَمَا أُبَرِّئُ",
  "رُبَمَا",
  "سُبْحَانَ الَّذِي",
  "قَالَ أَلَمْ",
  "اقْتَرَبَ لِلنَّاسِ",
  "قَدْ أَفْلَحَ",
  "وَقَالَ الَّذِينَ",
  "أَمَّنْ خَلَقَ",
  "اتْلُ مَا أُوحِيَ",
  "وَمَن يَقْنُتْ",
  "وَمَا لِيَ",
  "فَمَنْ أَظْلَمُ",
  "إِلَيْهِ يُرَدُّ",
  "حم",
  "قَالَ فَمَا خَطْبُكُمْ",
  "قَدْ سَمِعَ اللَّهُ",
  "تَبَارَكَ الَّذِي",
  "عَمَّ يَتَسَاءَلُونَ",
];

class SurahReaderScreen extends StatefulWidget {
  final int? surahNumber;
  final int? juzNumber;
  final int? scrollToAyah;

  const SurahReaderScreen({
    super.key,
    this.surahNumber,
    this.juzNumber,
    this.scrollToAyah,
  });

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  static const int _ayahsPerPage = 16;

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(viewportFraction: 1.0);

  // Scroll mode: vertical (scroll) or horizontal (swipe pages)
  bool _isHorizontal = false;

  // ── Auto-scroll (vertical mode only) ──
  Timer? _autoScrollTimer;
  bool _isAutoScrolling = false;
  double _autoScrollSpeed = 40; // pixels per second
  int _stuckTicks = 0;

  // Track dynamically changed Surah names inside a Juz
  String _dynamicSurahName = '';

  // Keys used to detect which page is at the top of the screen
  final Map<int, GlobalKey> _ayahKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadContent();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════
  // AUTO SCROLL
  // ═════════════════════════════════════════════════════════════
  void _startAutoScroll() {
    if (_isHorizontal) return;
    _autoScrollTimer?.cancel();
    _stuckTicks = 0;
    setState(() => _isAutoScrolling = true);

    const tick = Duration(milliseconds: 16);
    _autoScrollTimer = Timer.periodic(tick, (_) {
      if (!mounted || !_scrollController.hasClients) return;

      final pos = _scrollController.position;
      final next =
          pos.pixels + _autoScrollSpeed * tick.inMilliseconds / 1000.0;

      if (next >= pos.maxScrollExtent) {
        _scrollController.jumpTo(pos.maxScrollExtent);
        // ListView.builder estimates its extent, so wait briefly to be sure
        // we really reached the end before stopping.
        _stuckTicks++;
        if (_stuckTicks > 30) _stopAutoScroll();
      } else {
        _stuckTicks = 0;
        _scrollController.jumpTo(next);
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (mounted && _isAutoScrolling) {
      setState(() => _isAutoScrolling = false);
    }
  }

  void _toggleAutoScroll() {
    _isAutoScrolling ? _stopAutoScroll() : _startAutoScroll();
  }

  // ═════════════════════════════════════════════════════════════
  // LOADING
  // ═════════════════════════════════════════════════════════════
  Future<void> _loadContent() async {
    final provider = context.read<QuranProvider>();
    if (widget.surahNumber != null) {
      await provider.loadSurah(widget.surahNumber!);
      if (!mounted) return;
      if (provider.currentSurah?.surah != null) {
        setState(() {
          _dynamicSurahName = provider.currentSurah!.surah.nameArabic;
        });
      }
    } else if (widget.juzNumber != null) {
      await provider.loadJuz(widget.juzNumber!);
      if (!mounted) return;
      if (provider.currentJuzAyahs != null &&
          provider.currentJuzAyahs!.isNotEmpty) {
        setState(() {
          _dynamicSurahName =
              provider.currentJuzAyahs!.first.surahName ?? 'القرآن الكريم';
        });
      }
    }
  }

  void _onScroll() {
    if (!mounted || _isHorizontal) return;
    final provider = context.read<QuranProvider>();
    final List<Ayah>? ayahs =
        provider.currentSurah?.ayahs ?? provider.currentJuzAyahs;
    if (ayahs == null || ayahs.isEmpty) return;

    // The line just below the AppBar: whichever page crosses it is "current".
    final double threshold =
        MediaQuery.of(context).padding.top + kToolbarHeight + 1;

    int? activeAyahNumber;
    for (final entry in _ayahKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      if (top <= threshold && bottom > threshold) {
        activeAyahNumber = entry.key;
        break;
      }
    }

    if (activeAyahNumber == null) return;
    final idx = ayahs.indexWhere((a) => a.number == activeAyahNumber);
    if (idx == -1) return;

    final targetName = ayahs[idx].surahName ?? 'القرآن الكريم';
    if (_dynamicSurahName != targetName) {
      setState(() => _dynamicSurahName = targetName);
    }
  }

  String _cleanArabicText(Ayah ayah) {
    String cleanText = ayah.text.trim();
    if (ayah.numberInSurah == 1 &&
        ayah.surahNumber != 1 &&
        ayah.surahNumber != 9) {
      const String bismillah1 = "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ";
      const String bismillah2 = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ";
      const String bismillah3 = "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ";

      if (cleanText.startsWith(bismillah1)) {
        cleanText = cleanText.substring(bismillah1.length).trim();
      } else if (cleanText.startsWith(bismillah2)) {
        cleanText = cleanText.substring(bismillah2.length).trim();
      } else if (cleanText.startsWith(bismillah3)) {
        cleanText = cleanText.substring(bismillah3.length).trim();
      }
    }
    return cleanText;
  }

  // "الجزء ٣ - تِلْكَ الرُّسُلُ"
  String _juzTitle(int juz) {
    final idx = juz - 1;
    final name =
    (idx >= 0 && idx < juzNamesArabic.length) ? juzNamesArabic[idx] : '';
    final label = 'الجزء ${toArabicNumerals(juz)}';
    return name.isEmpty ? label : '$label - $name';
  }

  bool _isBookmarked(QuranProvider provider, int surahId, {int? ayahId}) {
    try {
      if (ayahId != null) return provider.isBookmarked(surahId, ayahId);
      return provider.isBookmarked(surahId);
    } catch (_) {
      try {
        final key = ayahId != null ? '$surahId:$ayahId' : '$surahId';
        return provider.bookmarks.contains(key);
      } catch (_) {
        return false;
      }
    }
  }

  void _toggleBookmark(QuranProvider provider, int surahId, {int? ayahId}) {
    try {
      if (ayahId != null) {
        provider.toggleBookmark(surahId, ayahId);
      } else {
        provider.toggleBookmark(surahId);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isBookmarked(provider, surahId, ayahId: ayahId)
                ? 'Bookmark saved'
                : 'Bookmark removed',
            style: const TextStyle(),
          ),
          duration: const Duration(seconds: 1),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranProvider>(
      builder: (context, provider, _) {
        final List<Ayah>? ayahs =
            provider.currentSurah?.ayahs ?? provider.currentJuzAyahs;

        final bool hasError = provider.error != null;
        final bool isEmpty =
            (ayahs == null || ayahs.isEmpty) && !provider.loadingContent;

        return Scaffold(
          backgroundColor: const Color(0xFFFDFBF5), // warm white
          appBar: AppBar(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              _dynamicSurahName.isNotEmpty
                  ? _dynamicSurahName
                  : (widget.juzNumber != null
                  ? 'الجزء ${toArabicNumerals(widget.juzNumber!)}'
                  : 'القرآن الكريم'),
              style: GoogleFonts.notoSansArabic(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
            actions: [
              // Auto-scroll play / pause (vertical mode only)
              if (!_isHorizontal)
                IconButton(
                  tooltip:
                  _isAutoScrolling ? 'Stop auto scroll' : 'Start auto scroll',
                  icon: Icon(
                    _isAutoScrolling
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: AppTheme.gold,
                  ),
                  onPressed: _toggleAutoScroll,
                ),
              // Scroll direction toggle
              IconButton(
                tooltip: _isHorizontal
                    ? 'Switch to vertical scroll'
                    : 'Switch to horizontal swipe',
                icon: Icon(
                  _isHorizontal ? Icons.swap_vert : Icons.swap_horiz,
                  color: AppTheme.gold,
                ),
                onPressed: () {
                  _stopAutoScroll();
                  setState(() => _isHorizontal = !_isHorizontal);
                },
              ),
              // Translation quick-toggle
              IconButton(
                tooltip: 'Translation',
                icon: Badge(
                  isLabelVisible: provider.showUrdu || provider.showEnglish,
                  smallSize: 8,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.translate, color: AppTheme.gold),
                ),
                onPressed: _showTranslationSheet,
              ),
              if (widget.surahNumber != null)
                IconButton(
                  icon: Icon(
                    _isBookmarked(provider, widget.surahNumber!)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: AppTheme.gold,
                  ),
                  onPressed: () =>
                      _toggleBookmark(provider, widget.surahNumber!),
                ),
            ],
          ),
          body: provider.loadingContent
              ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
              : (hasError || isEmpty)
              ? _buildErrorWidget(provider, isEmpty)
              : Stack(
            children: [
              _isHorizontal
                  ? _buildHorizontalPages(ayahs!, provider)
                  : _buildMushafPageList(ayahs!, provider),
              if (_isAutoScrolling && !_isHorizontal)
                _buildAutoScrollPanel(),
            ],
          ),
        );
      },
    );
  }

  // ── Floating speed control shown while auto-scroll is running ──
  Widget _buildAutoScrollPanel() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(28),
        color: AppTheme.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.pause, color: Colors.white),
                onPressed: _stopAutoScroll,
              ),
              const Icon(Icons.speed, color: Colors.white70, size: 20),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.gold,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.gold,
                    overlayColor: AppTheme.gold.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 10,
                    max: 150,
                    divisions: 14,
                    value: _autoScrollSpeed,
                    // The timer reads _autoScrollSpeed each tick, so changes
                    // apply instantly.
                    onChanged: (v) => setState(() => _autoScrollSpeed = v),
                  ),
                ),
              ),
              Text(
                '${(_autoScrollSpeed / 10).round()}x',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(QuranProvider provider, bool isEmpty) {
    String message = provider.error ?? 'Failed to load content';
    if (isEmpty && widget.juzNumber != null) {
      message = 'Juz ${widget.juzNumber} content is not available';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.primary, size: 80),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadContent,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // GROUP AYAHS INTO PAGES — always 16 per page
  // ═════════════════════════════════════════════════════════════
  Map<int, List<Ayah>> _groupAyahsIntoPages(List<Ayah> ayahs) {
    final Map<int, List<Ayah>> pageGroups = {};
    for (int i = 0; i < ayahs.length; i++) {
      final int pageNum = (i ~/ _ayahsPerPage) + 1;
      pageGroups.putIfAbsent(pageNum, () => []).add(ayahs[i]);
    }
    return pageGroups;
  }

  // ═════════════════════════════════════════════════════════════
  // VERTICAL SCROLL LIST (Mushaf-style flowing page)
  // ═════════════════════════════════════════════════════════════
  Widget _buildMushafPageList(List<Ayah> ayahs, QuranProvider provider) {
    final pageGroups = _groupAyahsIntoPages(ayahs);
    final pageKeys = pageGroups.keys.toList();

    return Listener(
      // Touching the list stops auto-scroll so the user can take over.
      onPointerDown: (_) {
        if (_isAutoScrolling) _stopAutoScroll();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        itemCount: pageKeys.length,
        itemBuilder: (context, pageIndex) {
          final pageKey = pageKeys[pageIndex];
          final List<Ayah> pageAyahs = pageGroups[pageKey]!;
          final representativeAyah = pageAyahs.first;

          return _buildFlowingMushafPage(
            pageAyahs,
            provider,
            representativeAyah,
            _juzTitle(representativeAyah.juz),
            pageKey, // page number = 1, 2, 3 ...
          );
        },
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // HORIZONTAL SWIPE (PageView) — page-by-page Mushaf
  // Swipe finger LEFT → RIGHT to go to the next page.
  // ═════════════════════════════════════════════════════════════
  Widget _buildHorizontalPages(List<Ayah> ayahs, QuranProvider provider) {
    final pageGroups = _groupAyahsIntoPages(ayahs);
    final pageKeys = pageGroups.keys.toList();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: PageView.builder(
        controller: _pageController,
        reverse: true, // ✅ next page comes with a left → right swipe
        itemCount: pageKeys.length,
        itemBuilder: (context, pageIndex) {
          final pageKey = pageKeys[pageIndex];
          final List<Ayah> pageAyahs = pageGroups[pageKey]!;
          final representativeAyah = pageAyahs.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _buildFlowingMushafPage(
              pageAyahs,
              provider,
              representativeAyah,
              _juzTitle(representativeAyah.juz),
              pageKey,
            ),
          );
        },
      ),
    );
  }

  // ── White-themed Mushaf page: all ayahs flow as one RTL paragraph ──
  Widget _buildFlowingMushafPage(
      List<Ayah> pageAyahs,
      QuranProvider provider,
      Ayah representativeAyah,
      String juzTitle,
      int displayPageNum,
      ) {
    // Keep the same key across rebuilds (only the first ayah of each page).
    final pageKey = _ayahKeys.putIfAbsent(
        representativeAyah.number, () => GlobalKey());

    final bool hasBismillah = pageAyahs.any(
          (a) => a.numberInSurah == 1 && a.surahNumber != 9,
    );

    final bool showTranslation = provider.showUrdu || provider.showEnglish;

    return Container(
      key: pageKey,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.gold.withOpacity(0.55), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border:
          Border.all(color: AppTheme.gold.withOpacity(0.35), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMushafHeader(representativeAyah, juzTitle, displayPageNum),
            if (hasBismillah) _buildMushafBismillah(),
            if (pageAyahs.first.numberInSurah == 1)
              _buildMushafSurahBanner(pageAyahs.first),
            if (showTranslation)
              _buildTranslatedAyahs(pageAyahs, provider)
            else
              _buildArabicParagraph(pageAyahs, provider),
            _buildMushafFooter(representativeAyah),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // TRANSLATION QUICK SETTINGS (bottom sheet)
  // ═════════════════════════════════════════════════════════════
  void _showTranslationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Consumer<QuranProvider>(
        builder: (context, p, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'ترجمہ کی ترتیبات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: const Text('اردو ترجمہ دکھائیں'),
                  value: p.showUrdu,
                  onChanged: (_) => p.toggleUrdu(),
                  activeColor: AppTheme.primary,
                ),
                SwitchListTile(
                  title: const Text('انگریزی ترجمہ دکھائیں'),
                  value: p.showEnglish,
                  onChanged: (_) => p.toggleEnglish(),
                  activeColor: AppTheme.primary,
                ),
                if (p.showUrdu || p.showEnglish) ...[
                  const ListTile(
                    dense: true,
                    leading:
                    Icon(Icons.text_fields, color: AppTheme.primary),
                    title: Text('ترجمہ فونٹ سائز'),
                  ),
                  Slider(
                    value: p.translationFontSize,
                    min: 12,
                    max: 24,
                    divisions: 6,
                    label: p.translationFontSize.round().toString(),
                    activeColor: AppTheme.primary,
                    onChanged: (v) => p.setTranslationFontSize(v),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Arabic only: all ayahs flow as one RTL paragraph ──
  Widget _buildArabicParagraph(List<Ayah> pageAyahs, QuranProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: RichText(
          textAlign: TextAlign.justify,
          text: TextSpan(
            style: GoogleFonts.amiriQuran(
              fontSize: provider.arabicFontSize,
              color: Colors.black,
              height: 2.4,
            ),
            children: pageAyahs.expand<InlineSpan>((ayah) {
              final text = _cleanArabicText(ayah);
              return [
                TextSpan(text: '$text '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _MushafVerseMarker(number: ayah.numberInSurah),
                ),
                const TextSpan(text: ' '),
              ];
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── With translation: every ayah is followed by its Urdu / English text ──
  Widget _buildTranslatedAyahs(List<Ayah> pageAyahs, QuranProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < pageAyahs.length; i++) ...[
            _buildAyahWithTranslation(pageAyahs[i], provider),
            if (i < pageAyahs.length - 1)
              Divider(height: 1, color: AppTheme.gold.withOpacity(0.3)),
          ],
        ],
      ),
    );
  }

  Widget _buildAyahWithTranslation(Ayah ayah, QuranProvider provider) {
    final String? urdu =
    provider.showUrdu ? _urduTranslationOf(ayah)?.trim() : null;
    final String? english =
    provider.showEnglish ? _englishTranslationOf(ayah)?.trim() : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arabic
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text.rich(
              TextSpan(
                style: GoogleFonts.amiriQuran(
                  fontSize: provider.arabicFontSize,
                  color: Colors.black,
                  height: 2.2,
                ),
                children: [
                  TextSpan(text: '${_cleanArabicText(ayah)} '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: _MushafVerseMarker(number: ayah.numberInSurah),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // Urdu
          if (urdu != null && urdu.isNotEmpty) ...[
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                urdu,
                textAlign: TextAlign.right,
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: provider.translationFontSize,
                  height: 2.0,
                  color: Colors.black87,
                ),
              ),
            ),
          ],

          // English
          if (english != null && english.isNotEmpty) ...[
            const SizedBox(height: 8),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                english,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: provider.translationFontSize,
                  height: 1.5,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Header: Surah (right) | Page (center) | Juz + para name (left) ──
  Widget _buildMushafHeader(Ayah ayah, String juzTitle, int pageNum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.04),
        border: Border(
          bottom:
          BorderSide(color: AppTheme.gold.withOpacity(0.5), width: 0.8),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Expanded(
              child: Text(
                ayah.surahName ?? _dynamicSurahName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansArabic(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.gold.withOpacity(0.6)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                toArabicNumerals(pageNum),
                style: GoogleFonts.notoSansArabic(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(
                juzTitle,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansArabic(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMushafBismillah() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.03),
        border: Border(
          bottom:
          BorderSide(color: AppTheme.gold.withOpacity(0.3), width: 0.6),
        ),
      ),
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: GoogleFonts.amiriQuran(
          fontSize: 20,
          color: AppTheme.primary,
          height: 2.0,
        ),
      ),
    );
  }

  Widget _buildMushafSurahBanner(Ayah ayah) {
    if (_dynamicSurahName == (ayah.surahName ?? '')) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal:
          BorderSide(color: AppTheme.gold.withOpacity(0.4), width: 0.8),
        ),
      ),
      child: Center(
        child: Text(
          ayah.surahName ?? '',
          style: GoogleFonts.notoSansArabic(
            fontSize: 18,
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  // ── Footer: ع | المنزل ٣ | الجزء ٥ ──
  Widget _buildMushafFooter(Ayah ayah) {
    final manzilNum = ayah.manzil != 0 ? ayah.manzil : 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.04),
        border: Border(
          top: BorderSide(color: AppTheme.gold.withOpacity(0.5), width: 0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ع',
            style: GoogleFonts.notoSansArabic(
              color: AppTheme.primary.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'المنزل ${toArabicNumerals(manzilNum)}',
            textDirection: TextDirection.rtl,
            style: GoogleFonts.notoSansArabic(
              fontSize: 12,
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'الجزء ${toArabicNumerals(ayah.juz)}',
              textDirection: TextDirection.rtl,
              style: GoogleFonts.notoSansArabic(
                fontSize: 11,
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Surah start banner (used when translation mode is on) ──
}

// ── Verse-number marker (gold ring with Arabic-Indic numerals) ──
class _MushafVerseMarker extends StatelessWidget {
  final int number;
  const _MushafVerseMarker({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: AppTheme.gold, width: 1.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.gold.withOpacity(0.35), width: 0.5),
            ),
          ),
          Text(
            toArabicNumerals(number),
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}