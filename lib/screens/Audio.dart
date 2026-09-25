import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranAudioPlayer.dart';
import 'package:quranpak/services/AudioServices.dart';

class AudioDownloadsScreen extends StatefulWidget {
  const AudioDownloadsScreen({super.key});

  @override
  State<AudioDownloadsScreen> createState() => _AudioDownloadsScreenState();
}

class _AudioDownloadsScreenState extends State<AudioDownloadsScreen> {
  final AudioDownloadService _downloader = AudioDownloadService();

  bool _loading = true;
  List<_ReciterGroup> _groups = [];

  @override
  void initState() {
    super.initState();
    _scanDownloads();
  }


  // Surah number → English name. Same list your QuranProvider uses.
  static const Map<int, String> _surahNames = {
    1: 'Al-Fatihah', 2: 'Al-Baqarah', 3: 'Ali \'Imran', 4: 'An-Nisa',
    5: 'Al-Ma\'idah', 6: 'Al-An\'am', 7: 'Al-A\'raf', 8: 'Al-Anfal',
    9: 'At-Tawbah', 10: 'Yunus', 11: 'Hud', 12: 'Yusuf',
    13: 'Ar-Ra\'d', 14: 'Ibrahim', 15: 'Al-Hijr', 16: 'An-Nahl',
    17: 'Al-Isra', 18: 'Al-Kahf', 19: 'Maryam', 20: 'Ta-Ha',
    21: 'Al-Anbiya', 22: 'Al-Hajj', 23: 'Al-Mu\'minun', 24: 'An-Nur',
    25: 'Al-Furqan', 26: 'Ash-Shu\'ara', 27: 'An-Naml', 28: 'Al-Qasas',
    29: 'Al-\'Ankabut', 30: 'Ar-Rum', 31: 'Luqman', 32: 'As-Sajdah',
    33: 'Al-Ahzab', 34: 'Saba', 35: 'Fatir', 36: 'Ya-Sin',
    37: 'As-Saffat', 38: 'Sad', 39: 'Az-Zumar', 40: 'Ghafir',
    41: 'Fussilat', 42: 'Ash-Shura', 43: 'Az-Zukhruf', 44: 'Ad-Dukhan',
    45: 'Al-Jathiyah', 46: 'Al-Ahqaf', 47: 'Muhammad', 48: 'Al-Fath',
    49: 'Al-Hujurat', 50: 'Qaf', 51: 'Adh-Dhariyat', 52: 'At-Tur',
    53: 'An-Najm', 54: 'Al-Qamar', 55: 'Ar-Rahman', 56: 'Al-Waqi\'ah',
    57: 'Al-Hadid', 58: 'Al-Mujadila', 59: 'Al-Hashr', 60: 'Al-Mumtahanah',
    61: 'As-Saff', 62: 'Al-Jumu\'ah', 63: 'Al-Munafiqun', 64: 'At-Taghabun',
    65: 'At-Talaq', 66: 'At-Tahrim', 67: 'Al-Mulk', 68: 'Al-Qalam',
    69: 'Al-Haqqah', 70: 'Al-Ma\'arij', 71: 'Nuh', 72: 'Al-Jinn',
    73: 'Al-Muzzammil', 74: 'Al-Muddaththir', 75: 'Al-Qiyamah', 76: 'Al-Insan',
    77: 'Al-Mursalat', 78: 'An-Naba', 79: 'An-Nazi\'at', 80: '\'Abasa',
    81: 'At-Takwir', 82: 'Al-Infitar', 83: 'Al-Mutaffifin', 84: 'Al-Inshiqaq',
    85: 'Al-Buruj', 86: 'At-Tariq', 87: 'Al-A\'la', 88: 'Al-Ghashiyah',
    89: 'Al-Fajr', 90: 'Al-Balad', 91: 'Ash-Shams', 92: 'Al-Lail',
    93: 'Ad-Duha', 94: 'Ash-Sharh', 95: 'At-Tin', 96: 'Al-\'Alaq',
    97: 'Al-Qadr', 98: 'Al-Bayyinah', 99: 'Az-Zalzalah', 100: 'Al-\'Adiyat',
    101: 'Al-Qari\'ah', 102: 'At-Takathur', 103: 'Al-\'Asr', 104: 'Al-Humazah',
    105: 'Al-Fil', 106: 'Quraish', 107: 'Al-Ma\'un', 108: 'Al-Kauthar',
    109: 'Al-Kafirun', 110: 'An-Nasr', 111: 'Al-Masad', 112: 'Al-Ikhlas',
    113: 'Al-Falaq', 114: 'An-Nas',
  };

  String _surahLabel(int num) {
    final name = _surahNames[num];
    return name != null ? '$num. $name' : 'Surah $num';
  }

  Future<void> _scanDownloads() async {
    setState(() => _loading = true);
    final reciterIds = await _downloader.listRecitersWithDownloads();

    final groups = <_ReciterGroup>[];
    for (final id in reciterIds) {
      final rec = QuranAudioPlayer.reciters.firstWhere(
            (r) => r.id == id,
        orElse: () => Reciter(
          id: id,
          name: id,
          arabicName: '',
          baseUrl: '',
          imageAsset: '',
        ),
      );
      final surahs = await _downloader.listDownloadedSurahs(id);
      final sizeBytes = await _downloader.getReciterSizeBytes(id);
      groups.add(_ReciterGroup(
        reciter: rec,
        surahs: surahs,
        sizeBytes: sizeBytes,
      ));
    }

    if (!mounted) return;
    setState(() {
      _groups = groups;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Downloaded Tilawat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Rescan',
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: _scanDownloads,
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      )
          : _groups.isEmpty
          ? _buildEmptyState()
          : _buildGroupsList(),
      // ✅ Mini-player wired into bottomNavigationBar so it never overlaps content
      bottomNavigationBar: const _AudioMiniPlayer(),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═════════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.headphones_outlined,
                size: 44,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Downloaded Tilawat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open the Quran screen, tap the play icon on a surah, '
                  'and choose a Qari to download it here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // LIST OF RECITERS
  // ═════════════════════════════════════════════════════════════
  Widget _buildGroupsList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, i) => _reciterSection(_groups[i]),
    );
  }

  Widget _reciterSection(_ReciterGroup group) {
    final player = context.watch<QuranAudioPlayer>();
    final isCurrent = player.selectedReciter.id == group.reciter.id;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent
              ? AppTheme.gold.withOpacity(0.6)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Reciter header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                ClipOval(
                  child: _reciterAvatar(group.reciter, size: 48),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              group.reciter.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Now',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.gold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (group.reciter.arabicName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          group.reciter.arabicName,
                          style: GoogleFonts.notoSansArabic(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${group.surahs.length} surah'
                            '${group.surahs.length == 1 ? "" : "s"} · '
                            '${_formatBytes(group.sizeBytes)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete all downloads for this Qari',
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppTheme.textSecondary),
                  onPressed: () => _confirmDelete(group),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Surah rows ──
          ...group.surahs.map((num) => _surahRow(group, num)),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ONE SURAH ROW — with play/pause button
  // ═════════════════════════════════════════════════════════════
  Widget _surahRow(_ReciterGroup group, int surahNumber) {
    final player = context.watch<QuranAudioPlayer>();

    final isThisSurah =
        player.currentSurah == surahNumber &&
            player.selectedReciter.id == group.reciter.id;
    final isPlaying = isThisSurah && player.isPlaying;
    final isPaused = isThisSurah && !player.isPlaying;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _togglePlayPause(group, surahNumber),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Surah number badge (star)
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      size: 38,
                      color: AppTheme.gold.withOpacity(0.35),
                    ),
                    Text(
                      '${_surahLabel(surahNumber)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Title / subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Surah $surahNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPlaying
                          ? 'Playing · Ayah ${player.currentAyah ?? 1}'
                          : isPaused
                          ? 'Paused · Ayah ${player.currentAyah ?? 1}'
                          : 'Downloaded · ready to play',
                      style: TextStyle(
                        fontSize: 11,
                        color: isThisSurah
                            ? AppTheme.gold
                            : AppTheme.textSecondary,
                        fontWeight: isThisSurah
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              // ✅ Play / Pause button — large and clear
              _playPauseButton(
                isPlaying: isPlaying,
                isActive: isThisSurah,
                onTap: () => _togglePlayPause(group, surahNumber),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playPauseButton({
    required bool isPlaying,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isActive ? AppTheme.primary : AppTheme.surfaceContainer,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            color: isActive ? AppTheme.gold : AppTheme.primary,
            size: 26,
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // PLAY / PAUSE LOGIC
  // ═════════════════════════════════════════════════════════════
  Future<void> _togglePlayPause(_ReciterGroup group, int surahNumber) async {
    final player = context.read<QuranAudioPlayer>();

    final isThisSurah =
        player.currentSurah == surahNumber &&
            player.selectedReciter.id == group.reciter.id;

    if (isThisSurah) {
      // Same surah → toggle pause/resume
      if (player.isPlaying) {
        await player.pause();
      } else {
        await player.resume();
      }
      return;
    }

    // Different surah → start fresh
    final totalAyahs = await AudioDownloadService()
        .countAyahs(group.reciter.id, surahNumber);
    if (!mounted) return;

    await player.playDownloadedSurah(
      surahNumber: surahNumber,
      totalAyahs: totalAyahs,
      surahName: _surahLabel(surahNumber),
      reciterId: group.reciter.id,
    );
  }

  // ═════════════════════════════════════════════════════════════
  // HELPERS
  // ═════════════════════════════════════════════════════════════
  Widget _reciterAvatar(Reciter reciter, {double size = 48}) {
    if (reciter.imageAsset.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: AppTheme.primary.withOpacity(0.10),
        child: const Icon(Icons.person, color: AppTheme.primary),
      );
    }
    if (reciter.imageAsset.startsWith('http')) {
      return Image.network(
        reciter.imageAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: AppTheme.primary.withOpacity(0.10),
          child: const Icon(Icons.person, color: AppTheme.primary),
        ),
      );
    }
    return Image.asset(
      reciter.imageAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: AppTheme.primary.withOpacity(0.10),
        child: const Icon(Icons.person, color: AppTheme.primary),
      ),
    );
  }

  Future<void> _confirmDelete(_ReciterGroup group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete downloads?'),
        content: Text(
          'This will remove all ${group.surahs.length} surah(s) '
              'from ${group.reciter.name} (${_formatBytes(group.sizeBytes)}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;
    await AudioDownloadService().deleteReciter(group.reciter.id);
    await _scanDownloads();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _ReciterGroup {
  final Reciter reciter;
  final List<int> surahs;
  final int sizeBytes;

  _ReciterGroup({
    required this.reciter,
    required this.surahs,
    required this.sizeBytes,
  });
}

// ═════════════════════════════════════════════════════════════════
// MINI PLAYER — sits at bottomNavigationBar, always visible when playing
// ═════════════════════════════════════════════════════════════════
class _AudioMiniPlayer extends StatelessWidget {
  const _AudioMiniPlayer();

  @override
  Widget build(BuildContext context) {
    return Consumer<QuranAudioPlayer>(
      builder: (context, player, _) {
        // Hide when nothing is loaded
        if (player.currentSurah == null) return const SizedBox.shrink();

        return Material(
          elevation: 8,
          color: AppTheme.primary,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Row 1: info + close ──
                  InkWell(
                    onTap: () => _openFullPlayer(context),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.graphic_eq,
                            color: AppTheme.gold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                player.currentSurahName ??
                                    'Surah ${player.currentSurah}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${player.selectedReciter.name} · '
                                    'Ayah ${player.currentAyah ?? 1}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          iconSize: 22,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => player.stop(),
                        ),
                      ],
                    ),
                  ),

                  // ── Row 2: seek bar ──
                  StreamBuilder<Duration>(
                    stream: player.positionStream,
                    builder: (context, snapshot) {
                      final pos = snapshot.data ?? Duration.zero;
                      final dur = player.duration ?? Duration.zero;
                      final maxMs =
                      dur.inMilliseconds.clamp(1, 1 << 31).toDouble();
                      final val = pos.inMilliseconds
                          .clamp(0, dur.inMilliseconds)
                          .toDouble();
                      return Row(
                        children: [
                          Text(
                            _fmt(pos),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 2,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 12),
                              ),
                              child: Slider(
                                value: val,
                                max: maxMs,
                                activeColor: AppTheme.gold,
                                inactiveColor: Colors.white24,
                                onChanged: (v) => player
                                    .seek(Duration(milliseconds: v.toInt())),
                              ),
                            ),
                          ),
                          Text(
                            _fmt(dur),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ── Row 3: transport controls ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 34,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.skip_previous_rounded,
                            color: Colors.white),
                        onPressed: player.previous,
                      ),
                      const SizedBox(width: 24),
                      // Big play/pause button
                      Material(
                        color: AppTheme.gold,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            player.isPlaying
                                ? player.pause()
                                : player.resume();
                          },
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Icon(
                              player.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: AppTheme.primary,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        iconSize: 34,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.skip_next_rounded,
                            color: Colors.white),
                        onPressed: player.next,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openFullPlayer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FullPlayerSheet(),
    );
  }
}

class _FullPlayerSheet extends StatelessWidget {
  const _FullPlayerSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Consumer<QuranAudioPlayer>(
            builder: (context, player, _) {
              return SafeArea(
                top: false,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Header row: close
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_down,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          'NOW PLAYING',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Big artwork
                    Center(
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.gold.withOpacity(0.9),
                              AppTheme.gold.withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.gold.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.menu_book,
                          size: 84,
                          color: AppTheme.primary.withOpacity(0.85),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Surah name
                    Center(
                      child: Text(
                        player.currentSurahName ??
                            'Surah ${player.currentSurah ?? ""}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        '${player.selectedReciter.name} · '
                            'Ayah ${player.currentAyah ?? 1}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Seek bar
                    StreamBuilder<Duration>(
                      stream: player.positionStream,
                      builder: (context, snapshot) {
                        final pos = snapshot.data ?? Duration.zero;
                        final dur = player.duration ?? Duration.zero;
                        final maxMs = dur.inMilliseconds
                            .clamp(1, 1 << 31)
                            .toDouble();
                        final val = pos.inMilliseconds
                            .clamp(0, dur.inMilliseconds)
                            .toDouble();
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 7),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14),
                                activeTrackColor: AppTheme.gold,
                                inactiveTrackColor: Colors.white24,
                                thumbColor: AppTheme.gold,
                                overlayColor:
                                AppTheme.gold.withOpacity(0.25),
                              ),
                              child: Slider(
                                value: val,
                                max: maxMs,
                                onChanged: (v) => player.seek(
                                    Duration(milliseconds: v.toInt())),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fmtDur(pos),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    _fmtDur(dur),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Big transport controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 42,
                          icon: const Icon(Icons.skip_previous_rounded,
                              color: Colors.white),
                          onPressed: player.previous,
                        ),
                        const SizedBox(width: 20),
                        Material(
                          color: AppTheme.gold,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              player.isPlaying
                                  ? player.pause()
                                  : player.resume();
                            },
                            child: SizedBox(
                              width: 78,
                              height: 78,
                              child: Icon(
                                player.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppTheme.primary,
                                size: 42,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          iconSize: 42,
                          icon: const Icon(Icons.skip_next_rounded,
                              color: Colors.white),
                          onPressed: player.next,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Reciter switcher preview
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.record_voice_over,
                              color: AppTheme.gold, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Reciter',
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  player.selectedReciter.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white70, size: 22),
                            onPressed: () {
                              player.stop();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  static String _fmtDur(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}