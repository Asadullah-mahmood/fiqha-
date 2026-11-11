import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/models/models.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:quranpak/utils/QuranAudioPlayer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:toastification/toastification.dart';
import 'package:quranpak/widgets/TranslationLanguageTabs.dart';

import '../utils/BookmarkProvider.dart';
import '../utils/LastReadProvider.dart';

// ── Arabic-Indic numerals helper (used everywhere numbers are shown) ──
String toArabicNumerals(int n) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) => digits[int.parse(c)]).join();
}

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
  final int? scrollToSurah;

  const SurahReaderScreen({
    super.key,
    this.surahNumber,
    this.juzNumber,
    this.scrollToAyah,
    this.scrollToSurah,
  });

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  final ScrollController _scrollController = ScrollController();

  // ── Auto-scroll (vertical mode only) ──
  Timer? _autoScrollTimer;
  bool _isAutoScrolling = false;
  double _autoScrollSpeed = 40; // pixels per second
  int _stuckTicks = 0;
  bool _showAutoScrollPanel = false;

  // ── Bookmarks: the ayah currently at the top of the screen ──
  final ValueNotifier<Ayah?> _currentAyah = ValueNotifier<Ayah?>(null);
  final Map<int, LongPressGestureRecognizer> _ayahRecognizers = {};

  // Track dynamically changed Surah names inside a Juz
  String _dynamicSurahName = '';

  // Keys used to detect which ayah is at the top of the screen
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
    _currentAyah.dispose();
    for (final r in _ayahRecognizers.values) {
      r.dispose();
    }
    super.dispose();
  }

  // ═════════════════════════════════════════════════════════════
  // AUTO SCROLL
  // ═════════════════════════════════════════════════════════════
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _stuckTicks = 0;
    setState(() {
      _isAutoScrolling = true;
      _showAutoScrollPanel = true;
    });

    const tick = Duration(milliseconds: 16);
    _autoScrollTimer = Timer.periodic(tick, (_) {
      if (!mounted || !_scrollController.hasClients) return;

      final pos = _scrollController.position;
      final next = pos.pixels + _autoScrollSpeed * tick.inMilliseconds / 1000.0;

      if (next >= pos.maxScrollExtent) {
        _scrollController.jumpTo(pos.maxScrollExtent);
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

  void _closeAutoScrollPanel() {
    _stopAutoScroll();
    if (mounted) setState(() => _showAutoScrollPanel = false);
  }

  // ═════════════════════════════════════════════════════════════
  // LOADING
  // ═════════════════════════════════════════════════════════════
  Future<void> _loadContent() async {
    final provider = context.read<QuranProvider>();

    if (!provider.isBootstrapped) {
      await provider.retryBootstrap();
      if (!mounted) return;
    }

    if (widget.surahNumber != null) {
      await provider.loadSurah(widget.surahNumber!);
      if (!mounted) return;
      if (provider.currentSurah?.surah != null) {
        setState(() {
          _dynamicSurahName = provider.currentSurah!.surah.name;
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

    final loadedAyahs =
        provider.currentSurah?.ayahs ?? provider.currentJuzAyahs;
    if (loadedAyahs == null || loadedAyahs.isEmpty) return;
    final ayahs = _uniqueAyahs(loadedAyahs);
    final startAyah = widget.scrollToAyah == null
        ? ayahs.first
        : ayahs.firstWhere(
            (ayah) =>
                ayah.numberInSurah == widget.scrollToAyah &&
                (widget.scrollToSurah == null ||
                    ayah.surahNumber == widget.scrollToSurah),
            orElse: () => ayahs.first,
          );
    _recordAyah(startAyah);
    if (widget.scrollToAyah != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToAyah(ayahs, startAyah);
        }
      });
    }
  }

  void _onScroll() {
    if (!mounted) return;
    final provider = context.read<QuranProvider>();
    final loadedAyahs =
        provider.currentSurah?.ayahs ?? provider.currentJuzAyahs;
    if (loadedAyahs == null || loadedAyahs.isEmpty) return;
    final ayahs = _uniqueAyahs(loadedAyahs);

    final double threshold =
        MediaQuery.of(context).padding.top + kToolbarHeight + 1;

    Ayah? activeAyah;
    for (final ayah in ayahs) {
      final ctx = _ayahKeys[ayah.number]?.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      final bottom = box.localToGlobal(Offset.zero).dy + box.size.height;
      if (bottom > threshold) {
        activeAyah = ayah;
        break;
      }
    }

    if (activeAyah == null) return;
    final targetName = activeAyah.surahName ?? 'القرآن الكريم';
    if (_dynamicSurahName != targetName) {
      setState(() => _dynamicSurahName = targetName);
    }
    _recordAyah(activeAyah);
  }

  void _recordAyah(Ayah ayah) {
    _currentAyah.value = ayah;
    context.read<LastReadProvider>().recordAyah(
      ayah,
      readerType: widget.juzNumber != null ? 'juz' : 'surah',
      readerSectionNumber:
          widget.juzNumber ?? widget.surahNumber ?? ayah.surahNumber,
    );
  }

  Future<void> _scrollToAyah(List<Ayah> ayahs, Ayah targetAyah) async {
    final targetIndex = ayahs.indexWhere(
      (ayah) => ayah.number == targetAyah.number,
    );
    if (targetIndex < 0 || !_scrollController.hasClients) return;

    try {
      final targetContext = _ayahKeys[targetAyah.number]?.currentContext;
      if (targetContext != null && targetContext.mounted) {
        await Scrollable.ensureVisible(
          targetContext,
          alignment: 0.15,
          duration: const Duration(milliseconds: 250),
        );
      }
    } finally {
      if (mounted) _recordAyah(targetAyah);
    }
  }

  List<Ayah> _uniqueAyahs(Iterable<Ayah> ayahs) {
    final seen = <String>{};
    return ayahs.where((ayah) {
      final key = '${ayah.surahNumber}:${ayah.numberInSurah}';
      return seen.add(key);
    }).toList();
  }

  String _normalizeArabic(String text) {
    return text
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll('ٱ', 'ا')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _cleanArabicText(Ayah ayah) {
    final cleanText = ayah.text.trim();
    if (ayah.numberInSurah != 1 ||
        ayah.surahNumber == 1 ||
        ayah.surahNumber == 9) {
      return cleanText;
    }

    const bismillah = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
    final normalizedBismillah = _normalizeArabic(bismillah);
    final sourceRunes = cleanText.runes.toList();
    final normalizedPrefix = StringBuffer();

    for (var i = 0; i < sourceRunes.length; i++) {
      var character = String.fromCharCode(sourceRunes[i]);
      if (RegExp(r'[\u064B-\u065F\u0670\u0640]').hasMatch(character)) {
        continue;
      }
      if (character == 'ٱ') character = 'ا';
      if (RegExp(r'\s').hasMatch(character)) {
        if (normalizedPrefix.isNotEmpty &&
            !normalizedPrefix.toString().endsWith(' ')) {
          normalizedPrefix.write(' ');
        }
      } else {
        normalizedPrefix.write(character);
      }

      final normalized = normalizedPrefix.toString();
      if (!normalizedBismillah.startsWith(normalized)) return cleanText;
      if (normalized == normalizedBismillah) {
        var end = i + 1;
        while (end < sourceRunes.length &&
            RegExp(
              r'[\u064B-\u065F\u0670\u0640]',
            ).hasMatch(String.fromCharCode(sourceRunes[end]))) {
          end++;
        }
        return String.fromCharCodes(sourceRunes.skip(end)).trimLeft();
      }
    }
    return cleanText;
  }

  Future<void> _toggleBookmark(Ayah ayah) async {
    final bp = context.read<BookmarkProvider>();
    if (bp.isBookmarked(ayah.surahNumber, ayah.numberInSurah)) {
      await bp.removeByAyah(ayah.surahNumber, ayah.numberInSurah);
      if (mounted) {
        _showSnack(
          '${ayah.surahName ?? ""} · ${ayah.numberInSurah}',
          'Bookmark removed',
          ToastificationType.success,
        );
      }
    } else {
      final saved = await bp.add(
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.numberInSurah,
        surahName: ayah.surahName ?? '',
        surahEnglishName: ayah.surahEnglishName ?? '',
        ayahPreview: ayah.text,
      );
      if (mounted && saved) {
        _showSnack(
          '${ayah.surahName ?? ""} · ${ayah.numberInSurah}',
          'Bookmark saved locally; syncing to your account',
          ToastificationType.success,
        );
      } else if (mounted) {
        _showSnack(
          bp.error ?? 'Sign in to save bookmarks.',
          'Bookmark not saved',
          ToastificationType.error,
        );
      }
    }
  }

  void _showSnack(String msg, String title, ToastificationType type) {
    toastification.show(
      context: context,
      title: Text(title),
      description: Text(msg),
      type: type,
    );
  }

  // ═════════════════════════════════════════════════════════════
  // TRANSLATION SETTINGS (Single Translation)
  // ═════════════════════════════════════════════════════════════
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
        var currentSelected = provider.selectedTranslationEdition;
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) => Consumer<QuranProvider>(
            builder: (context, p, _) {
              final languages =
                  p.translationEditions
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
                final matchesQuery =
                    normalized.isEmpty ||
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
                        'Choose Translation',
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
                      if (p.translationError != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            p.translationError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (p.loadingTranslationEditions &&
                          p.translationEditions.isEmpty)
                        const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final edition = filtered[index];
                              return RadioListTile<String>(
                                value: edition.identifier,
                                groupValue: currentSelected,
                                title: Text(
                                  edition.englishName.isNotEmpty
                                      ? edition.englishName
                                      : edition.name,
                                ),
                                subtitle: Text(
                                  '${translationEditionLanguageLabel(edition.language, edition.name)} · '
                                  '${p.downloadedTranslationEditions.contains(edition.identifier) ? 'Offline' : 'Not downloaded'}',
                                ),
                                secondary:
                                    p.downloadingTranslationEdition ==
                                        edition.identifier
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : IconButton(
                                        tooltip:
                                            p.downloadedTranslationEditions
                                                .contains(edition.identifier)
                                            ? 'Downloaded'
                                            : 'Download translation',
                                        onPressed:
                                            p.downloadedTranslationEditions
                                                    .contains(
                                                      edition.identifier,
                                                    ) ||
                                                p.downloadingTranslationEdition !=
                                                    null
                                            ? null
                                            : () => unawaited(
                                                p.downloadTranslationEdition(
                                                  edition.identifier,
                                                ),
                                              ),
                                        icon: Icon(
                                          p.downloadedTranslationEditions
                                                  .contains(edition.identifier)
                                              ? Icons.download_done
                                              : Icons.download_outlined,
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                activeColor: AppTheme.primary,
                                onChanged: (value) {
                                  if (value != null) {
                                    setSheetState(
                                      () => currentSelected = value,
                                    );
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
                            onPressed: p.downloadingTranslationEdition != null
                                ? null
                                : () async {
                                    final saved = await p
                                        .setSelectedTranslationEditions([
                                          currentSelected,
                                        ]);
                                    if (saved && sheetContext.mounted) {
                                      Navigator.pop(sheetContext);
                                    }
                                  },
                            child: const Text('Apply Translation'),
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

  Widget _buildTranslationLine(
    String translation,
    String editionIdentifier,
    QuranProvider provider,
  ) {
    final language = provider.translationLanguageFor(editionIdentifier);
    final isRightToLeft = language == 'ur' || language == 'ar';
    final edition = provider.translationEditionFor(editionIdentifier);
    final label = edition?.englishName.isNotEmpty == true
        ? edition!.englishName
        : editionIdentifier;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: isRightToLeft
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Directionality(
            textDirection: isRightToLeft
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: Text(
              translation,
              textAlign: isRightToLeft ? TextAlign.right : TextAlign.left,
              style: isRightToLeft
                  ? GoogleFonts.notoNastaliqUrdu(
                      fontSize: provider.translationFontSize,
                      height: 2.0,
                      color: Colors.black87,
                    )
                  : TextStyle(
                      fontSize: provider.translationFontSize,
                      height: 1.5,
                      color: const Color(0xFF4A4A4A),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<QuranProvider, BookmarkProvider, QuranAudioPlayer>(
      builder: (context, provider, bookmarks, audioPlayer, _) {
        final loadedAyahs =
            provider.currentSurah?.ayahs ?? provider.currentJuzAyahs;
        final List<Ayah>? ayahs = loadedAyahs == null
            ? null
            : _uniqueAyahs(loadedAyahs);

        final bool hasError = provider.error != null;
        final bool isEmpty =
            (ayahs == null || ayahs.isEmpty) && !provider.loadingContent;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F6F0),
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
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              // Change Translation
              IconButton(
                tooltip: 'Change Translation',
                icon: const Icon(Icons.translate, color: AppTheme.gold),
                onPressed: _showTranslationSheet,
              ),
              // Auto-scroll play / pause
              IconButton(
                tooltip: _isAutoScrolling
                    ? 'Pause auto scroll'
                    : 'Start auto scroll',
                icon: Icon(
                  _isAutoScrolling
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                  color: AppTheme.gold,
                ),
                onPressed: _toggleAutoScroll,
              ),
            ],
          ),
          body: provider.loadingContent
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                )
              : (hasError || isEmpty)
              ? _buildErrorWidget(provider, isEmpty)
              : Stack(
                  children: [
                    _buildAyahCardList(
                      ayahs!,
                      provider,
                      bookmarks,
                      audioPlayer,
                    ),
                    if (_showAutoScrollPanel) _buildAutoScrollPanel(),
                  ],
                ),
        );
      },
    );
  }

  // ── Floating play/pause + speed control ──
  Widget _buildAutoScrollPanel() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SafeArea(
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(28),
          color: AppTheme.primary,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                IconButton(
                  tooltip: _isAutoScrolling ? 'Pause' : 'Resume',
                  icon: Icon(
                    _isAutoScrolling ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: _toggleAutoScroll,
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
                      onChanged: (v) => setState(() => _autoScrollSpeed = v),
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '${(_autoScrollSpeed / 40).toStringAsFixed(1)}x',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textScaler: TextScaler.linear(1),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20,
                  ),
                  onPressed: _closeAutoScrollPanel,
                ),
              ],
            ),
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
                fontWeight: FontWeight.bold,
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // VERTICAL LIST OF SINGLE AYAH CARDS
  // ═════════════════════════════════════════════════════════════
  Widget _buildAyahCardList(
    List<Ayah> ayahs,
    QuranProvider provider,
    BookmarkProvider bookmarks,
    QuranAudioPlayer audioPlayer,
  ) {
    return Listener(
      onPointerDown: (_) {
        if (_isAutoScrolling) _stopAutoScroll();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: ayahs.length,
        itemBuilder: (context, index) {
          final ayah = ayahs[index];
          return _buildSingleAyahCard(
            ayah,
            index,
            ayahs,
            provider,
            bookmarks,
            audioPlayer,
          );
        },
      ),
    );
  }

  Widget _buildSingleAyahCard(
    Ayah ayah,
    int index,
    List<Ayah> allAyahs,
    QuranProvider provider,
    BookmarkProvider bookmarks,
    QuranAudioPlayer audioPlayer,
  ) {
    final isBookmarked = bookmarks.isBookmarked(
      ayah.surahNumber,
      ayah.numberInSurah,
    );
    final isPlaying = audioPlayer.isAyahPlaying(
      ayah.surahNumber,
      ayah.numberInSurah,
    );

    final bool isRukuEnd =
        ayah.ruku != null &&
        (index == allAyahs.length - 1 || allAyahs[index + 1].ruku != ayah.ruku);

    final cleanedArabic = _cleanArabicText(ayah);
    final words = cleanedArabic.split(' ');
    final translationText = ayah.translation;
    final editionId = provider.selectedTranslationEdition;

    return Container(
      key: _ayahKeys.putIfAbsent(ayah.number, GlobalKey.new),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPlaying
              ? AppTheme.gold
              : AppTheme.gold.withValues(alpha: 0.4),
          width: isPlaying ? 2.0 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isPlaying
                ? AppTheme.gold.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isPlaying ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card Header: Surah/Ayah + Audio (Play/Pause) + Bookmark ──
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${ayah.surahName ?? "Surah"} · ${ayah.numberInSurah}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                if (isRukuEnd) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.gold),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ع',
                          style: TextStyle(
                            fontFamily: 'notoSansArabic',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF8B6B10),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ruku',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B6B10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // Audio button (turns into pause icon when playing)
                IconButton(
                  tooltip: isPlaying ? 'Pause recitation' : 'Play verse',
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.volume_up_rounded,
                    color: AppTheme.primary,
                    size: 26,
                  ),
                  onPressed: () async {
                    try {
                      await audioPlayer.playSingleAyah(
                        surahNumber: ayah.surahNumber,
                        ayahNumber: ayah.numberInSurah,
                      );
                    } catch (e) {
                      if (mounted) {
                        _showSnack(
                          'Offline playback note: Audio file will download if connected to internet, or play if cached.',
                          'Audio Playback',
                          ToastificationType.warning,
                        );
                      }
                    }
                  },
                ),
                // Bookmark button
                IconButton(
                  tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark ayah',
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isBookmarked ? AppTheme.gold : Colors.grey,
                    size: 22,
                  ),
                  onPressed: () => _toggleBookmark(ayah),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Arabic text: smooth colour-FILL synced with the audio ──
            _VerseFillText(
              words: words,
              isPlaying: isPlaying,
              positionStream: () => audioPlayer.positionStream,
              duration: () => audioPlayer.duration,
              playbackRate: () => audioPlayer.playbackRate,
              baseStyle: provider.arabicFontStyle(
                fontSize: provider.arabicFontSize,
                color: Colors.black87,
                height: 2.3,
              ),
              idleColor: Colors.black87,
              fillColor: AppTheme.gold,
              trailing: [
                // Round Ayah Number Container
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      border: Border.all(color: AppTheme.gold, width: 1.2),
                    ),
                    child: Text(
                      toArabicNumerals(ayah.numberInSurah),
                      style: TextStyle(
                        fontStyle: FontStyle.normal,
                        fontFamily: 'notoSansArabic',
                        fontSize: provider.arabicFontSize * 0.7,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                // Ruku Symbol "ع"
                if (isRukuEnd)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.gold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.gold, width: 1.5),
                      ),
                      child: Text(
                        'ع ${ayah.ruku ?? ""}',
                        style: const TextStyle(
                          fontFamily: 'notoSansArabic',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A5C00),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // ── Single Translation (Always Shown) ──
            if (translationText != null &&
                translationText.trim().isNotEmpty) ...[
              const Divider(height: 24, thickness: 1),
              _buildTranslationLine(
                translationText.trim(),
                editionId,
                provider,
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 4),

            // ── Card Footer Actions: Copy, Share ──
            Row(
              children: [
                const Spacer(),
                IconButton(
                  tooltip: 'Copy Ayah',
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () async {
                    final text =
                        '${ayah.text}\n\n— ${ayah.surahEnglishName ?? "Surah"} (${ayah.surahNumber}:${ayah.numberInSurah})';
                    await Clipboard.setData(ClipboardData(text: text));
                  },
                ),
                IconButton(
                  tooltip: 'Share Ayah',
                  icon: const Icon(
                    Icons.share_rounded,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    final text =
                        '${ayah.text}\n\n— ${ayah.surahEnglishName ?? "Surah"} (${ayah.surahNumber}:${ayah.numberInSurah})';
                    Share.share(text);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// VERSE TEXT WITH AUDIO-SYNCED COLOUR FILL
// ═════════════════════════════════════════════════════════════
/// Draws the verse in [idleColor], then paints a second copy in [fillColor]
/// on top, clipped so that the colour "fills" each word from its starting
/// edge (right edge for Arabic) in step with the audio position.
class _VerseFillText extends StatefulWidget {
  const _VerseFillText({
    required this.words,
    required this.isPlaying,
    required this.positionStream,
    required this.duration,
    required this.playbackRate,
    required this.baseStyle,
    required this.idleColor,
    required this.fillColor,
    this.trailing = const [],
  });

  final List<String> words;
  final bool isPlaying;

  /// Passed as callbacks because just_audio creates a new stream per access.
  final Stream<Duration> Function() positionStream;
  final Duration? Function() duration;

  /// Audio speed (1.0 = normal). Position is media time, so wall-clock
  /// extrapolation between position events must be scaled by this.
  final double Function() playbackRate;

  final TextStyle baseStyle;
  final Color idleColor;
  final Color fillColor;

  /// Spans appended after the words (ayah number circle, ruku marker).
  final List<InlineSpan> trailing;

  @override
  State<_VerseFillText> createState() => _VerseFillTextState();
}

class _VerseFillTextState extends State<_VerseFillText>
    with SingleTickerProviderStateMixin {
  final GlobalKey _paraKey = GlobalKey();
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);

  late final Ticker _ticker;
  StreamSubscription<Duration>? _sub;

  Duration _lastPos = Duration.zero;
  final Stopwatch _sinceEvent = Stopwatch();
  final Stopwatch _sinceStart = Stopwatch();

  // Per-word character ranges and cumulative timing weights.
  List<int> _starts = const [];
  List<int> _ends = const [];
  List<double> _cumWeights = const [];

  static final RegExp _marks = RegExp(
    r'[\u064B-\u065F\u0670\u0640\u06D6-\u06ED]',
  );

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _buildLayoutData();
    if (widget.isPlaying) _start();
  }

  @override
  void didUpdateWidget(covariant _VerseFillText old) {
    super.didUpdateWidget(old);
    if (!_sameWords(old.words, widget.words)) _buildLayoutData();
    if (widget.isPlaying != old.isPlaying) {
      widget.isPlaying ? _start() : _stop();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker.dispose();
    _progress.dispose();
    super.dispose();
  }

  bool _sameWords(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _buildLayoutData() {
    final starts = <int>[];
    final ends = <int>[];
    final cum = <double>[];
    var offset = 0;
    var total = 0.0;
    for (final w in widget.words) {
      starts.add(offset);
      offset += w.length + 1; // word + trailing space
      ends.add(offset);
      // Longer words take longer to recite: weight by letter count.
      final letters = w.replaceAll(_marks, '').runes.length;
      total += math.max(1, letters).toDouble();
      cum.add(total);
    }
    _starts = starts;
    _ends = ends;
    _cumWeights = cum;
  }

  // ── playback sync ──
  void _start() {
    _sub?.cancel();
    _lastPos = Duration.zero;
    _sinceEvent
      ..reset()
      ..start();
    _sinceStart
      ..reset()
      ..start();
    _progress.value = 0;
    _sub = widget.positionStream().listen(_onPosition);
    if (!_ticker.isActive) _ticker.start();
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    _ticker.stop();
    _sinceEvent.stop();
    _sinceStart.stop();
    _progress.value = 0;
  }

  void _onPosition(Duration p) {
    // Ignore a stale position (end of the previous play) right after a replay.
    if (_sinceStart.elapsedMilliseconds < 400 && p.inMilliseconds > 600) return;
    _lastPos = p;
    _sinceEvent
      ..reset()
      ..start();
  }

  void _onTick(Duration _) {
    final dur = widget.duration();
    if (dur == null || dur.inMilliseconds <= 0) return;
    // positionStream only fires ~5x/sec; extrapolate between events for a
    // smooth fill, but never more than 250 ms so a pause freezes the fill.
    final extra =
        math.min(_sinceEvent.elapsedMilliseconds, 250) * widget.playbackRate();
    final ms = _lastPos.inMilliseconds + extra;
    _progress.value = (ms / dur.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);

    InlineSpan span(Color color) => TextSpan(
      style: widget.baseStyle.copyWith(color: color),
      children: [
        for (final w in widget.words) TextSpan(text: '$w '),
        ...widget.trailing,
      ],
    );

    RichText paragraph(Key? key, Color color) => RichText(
      key: key,
      text: span(color),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      textScaler: scaler,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          // Base layer (idle colour) — also used to measure word positions.
          paragraph(_paraKey, widget.idleColor),
          // Fill layer: identical text in the fill colour, clipped by progress.
          if (widget.isPlaying)
            Positioned.fill(
              child: IgnorePointer(
                child: ClipPath(
                  clipper: _FillClipper(
                    paragraph: () =>
                        _paraKey.currentContext?.findRenderObject()
                            as RenderParagraph?,
                    starts: _starts,
                    ends: _ends,
                    cumWeights: _cumWeights,
                    progress: _progress,
                  ),
                  child: paragraph(null, widget.fillColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Clips to: every fully-recited word + the recited fraction of the current
/// word (growing from the word's start edge). Repaints whenever [progress]
/// changes, with no widget rebuild.
///
/// Uses only RenderParagraph.getBoxesForSelection, so it works on any
/// Flutter version. Lines are detected from the word boxes themselves.
class _FillClipper extends CustomClipper<Path> {
  _FillClipper({
    required this.paragraph,
    required this.starts,
    required this.ends,
    required this.cumWeights,
    required this.progress,
  }) : super(reclip: progress);

  final RenderParagraph? Function() paragraph;
  final List<int> starts;
  final List<int> ends;
  final List<double> cumWeights;
  final ValueListenable<double> progress;

  @override
  Path getClip(Size size) {
    final path = Path();
    final rp = paragraph();
    if (rp == null || !rp.hasSize || cumWeights.isEmpty) return path;
    final n = cumWeights.length;

    // ── Pass 1: boxes for every word + which visual line it is on ──
    final wordBoxes = <List<TextBox>>[];
    final lineOf = <int>[];
    final lineCenters = <double>[]; // average vertical centre of each line
    final lineCounts = <int>[];
    var line = -1;
    double lastCenter = 0;

    for (var i = 0; i < n; i++) {
      final boxes = rp.getBoxesForSelection(
        TextSelection(baseOffset: starts[i], extentOffset: ends[i]),
      );
      wordBoxes.add(boxes);
      if (boxes.isEmpty) {
        lineOf.add(line < 0 ? 0 : line);
        continue;
      }
      final first = boxes.first;
      final center = (first.top + first.bottom) / 2;
      final h = first.bottom - first.top;
      // Words come in reading order, so a clear vertical jump = a new line.
      if (line < 0 || (center - lastCenter).abs() > h * 0.5) {
        line++;
        lineCenters.add(0);
        lineCounts.add(0);
      }
      lastCenter = center;
      lineCenters[line] += center;
      lineCounts[line] += 1;
      lineOf.add(line);
    }
    if (line < 0) return path;

    for (var j = 0; j < lineCenters.length; j++) {
      lineCenters[j] = lineCounts[j] == 0 ? 0 : lineCenters[j] / lineCounts[j];
    }

    // ── Non-overlapping vertical band per line (split halfway between
    // line centres), so a word can never bleed into the neighbouring line. ──
    final tops = List<double>.filled(lineCenters.length, 0);
    final bottoms = List<double>.filled(lineCenters.length, size.height);
    for (var j = 0; j < lineCenters.length - 1; j++) {
      final mid = (lineCenters[j] + lineCenters[j + 1]) / 2;
      bottoms[j] = mid;
      tops[j + 1] = mid;
    }

    // ── Pass 2: fill words in order; later words/lines stay untouched ──
    final pos = progress.value.clamp(0.0, 1.0) * cumWeights.last;

    for (var i = 0; i < n; i++) {
      final wStart = i == 0 ? 0.0 : cumWeights[i - 1];
      final wEnd = cumWeights[i];
      if (pos <= wStart) break;
      final frac = ((pos - wStart) / (wEnd - wStart)).clamp(0.0, 1.0);

      final boxes = wordBoxes[i];
      var remaining =
          frac * boxes.fold<double>(0, (sum, b) => sum + (b.right - b.left));
      final top = tops[lineOf[i]];
      final bottom = bottoms[lineOf[i]];

      for (final b in boxes) {
        if (remaining <= 0) break;
        final w = b.right - b.left;
        final f = math.min(remaining, w);
        remaining -= f;
        final isRtl = b.direction == TextDirection.rtl;
        final full = f >= w;
        // Fill starts from the reading-start edge: right edge for Arabic.
        final left = isRtl ? b.right - f : b.left;
        final right = isRtl ? b.right : b.left + f;
        path.addRect(
          Rect.fromLTRB(
            full ? left - 1 : left,
            top,
            full ? right + 1 : right,
            bottom,
          ),
        );
      }
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _FillClipper old) => true;
}
