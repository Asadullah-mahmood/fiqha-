import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/widgets/customIcons.dart';
import 'package:toastification/toastification.dart';

import '../models/FullSurahReciter.dart';
import '../services/FullSurahDownloadProvider.dart';
import '../utils/AppTheme.dart';
import '../utils/FullSurahPlayer.dart';
import '../widgets/FullSurahMiniPlayer.dart';

class AudioDownloadsScreen extends StatefulWidget {
  const AudioDownloadsScreen({super.key});

  @override
  State<AudioDownloadsScreen> createState() => _AudioDownloadsScreenState();
}

class _AudioDownloadsScreenState extends State<AudioDownloadsScreen> {
  bool _loading = true;
  List<_ReciterDownloads> _groups = [];

  // ── Surah number → metadata (name + Arabic) ──
  static const Map<int, _SurahMeta> _surahMeta = {
    1: _SurahMeta('Al-Fatihah', 'الفاتحة', 7),
    2: _SurahMeta('Al-Baqarah', 'البقرة', 286),
    3: _SurahMeta("Ali 'Imran", 'آل عمران', 200),
    4: _SurahMeta('An-Nisa', 'النساء', 176),
    5: _SurahMeta("Al-Ma'idah", 'المائدة', 120),
    6: _SurahMeta("Al-An'am", 'الأنعام', 165),
    7: _SurahMeta("Al-A'raf", 'الأعراف', 206),
    8: _SurahMeta('Al-Anfal', 'الأنفال', 75),
    9: _SurahMeta('At-Tawbah', 'التوبة', 129),
    10: _SurahMeta('Yunus', 'يونس', 109),
    11: _SurahMeta('Hud', 'هود', 123),
    12: _SurahMeta('Yusuf', 'يوسف', 111),
    13: _SurahMeta("Ar-Ra'd", 'الرعد', 43),
    14: _SurahMeta('Ibrahim', 'إبراهيم', 52),
    15: _SurahMeta('Al-Hijr', 'الحجر', 99),
    16: _SurahMeta('An-Nahl', 'النحل', 128),
    17: _SurahMeta('Al-Isra', 'الإسراء', 111),
    18: _SurahMeta('Al-Kahf', 'الكهف', 110),
    19: _SurahMeta('Maryam', 'مريم', 98),
    20: _SurahMeta('Ta-Ha', 'طه', 135),
    21: _SurahMeta('Al-Anbiya', 'الأنبياء', 112),
    22: _SurahMeta('Al-Hajj', 'الحج', 78),
    23: _SurahMeta("Al-Mu'minun", 'المؤمنون', 118),
    24: _SurahMeta('An-Nur', 'النور', 64),
    25: _SurahMeta('Al-Furqan', 'الفرقان', 77),
    26: _SurahMeta("Ash-Shu'ara", 'الشعراء', 227),
    27: _SurahMeta('An-Naml', 'النمل', 93),
    28: _SurahMeta('Al-Qasas', 'القصص', 88),
    29: _SurahMeta("Al-'Ankabut", 'العنكبوت', 69),
    30: _SurahMeta('Ar-Rum', 'الروم', 60),
    31: _SurahMeta('Luqman', 'لقمان', 34),
    32: _SurahMeta('As-Sajdah', 'السجدة', 30),
    33: _SurahMeta('Al-Ahzab', 'الأحزاب', 73),
    34: _SurahMeta('Saba', 'سبأ', 54),
    35: _SurahMeta('Fatir', 'فاطر', 45),
    36: _SurahMeta('Ya-Sin', 'يس', 83),
    37: _SurahMeta('As-Saffat', 'الصافات', 182),
    38: _SurahMeta('Sad', 'ص', 88),
    39: _SurahMeta('Az-Zumar', 'الزمر', 75),
    40: _SurahMeta('Ghafir', 'غافر', 85),
    41: _SurahMeta('Fussilat', 'فصلت', 54),
    42: _SurahMeta('Ash-Shura', 'الشورى', 53),
    43: _SurahMeta('Az-Zukhruf', 'الزخرف', 89),
    44: _SurahMeta('Ad-Dukhan', 'الدخان', 59),
    45: _SurahMeta('Al-Jathiyah', 'الجاثية', 37),
    46: _SurahMeta('Al-Ahqaf', 'الأحقاف', 35),
    47: _SurahMeta('Muhammad', 'محمد', 38),
    48: _SurahMeta('Al-Fath', 'الفتح', 29),
    49: _SurahMeta('Al-Hujurat', 'الحجرات', 18),
    50: _SurahMeta('Qaf', 'ق', 45),
    51: _SurahMeta('Adh-Dhariyat', 'الذاريات', 60),
    52: _SurahMeta('At-Tur', 'الطور', 49),
    53: _SurahMeta('An-Najm', 'النجم', 62),
    54: _SurahMeta('Al-Qamar', 'القمر', 55),
    55: _SurahMeta('Ar-Rahman', 'الرحمن', 78),
    56: _SurahMeta("Al-Waqi'ah", 'الواقعة', 96),
    57: _SurahMeta('Al-Hadid', 'الحديد', 29),
    58: _SurahMeta('Al-Mujadila', 'المجادلة', 22),
    59: _SurahMeta('Al-Hashr', 'الحشر', 24),
    60: _SurahMeta('Al-Mumtahanah', 'الممتحنة', 13),
    61: _SurahMeta('As-Saff', 'الصف', 14),
    62: _SurahMeta("Al-Jumu'ah", 'الجمعة', 11),
    63: _SurahMeta('Al-Munafiqun', 'المنافقون', 11),
    64: _SurahMeta('At-Taghabun', 'التغابن', 18),
    65: _SurahMeta('At-Talaq', 'الطلاق', 12),
    66: _SurahMeta('At-Tahrim', 'التحريم', 12),
    67: _SurahMeta('Al-Mulk', 'الملك', 30),
    68: _SurahMeta('Al-Qalam', 'القلم', 52),
    69: _SurahMeta('Al-Haqqah', 'الحاقة', 52),
    70: _SurahMeta("Al-Ma'arij", 'المعارج', 44),
    71: _SurahMeta('Nuh', 'نوح', 28),
    72: _SurahMeta('Al-Jinn', 'الجن', 28),
    73: _SurahMeta('Al-Muzzammil', 'المزمل', 20),
    74: _SurahMeta('Al-Muddaththir', 'المدثر', 56),
    75: _SurahMeta('Al-Qiyamah', 'القيامة', 40),
    76: _SurahMeta('Al-Insan', 'الإنسان', 31),
    77: _SurahMeta('Al-Mursalat', 'المرسلات', 50),
    78: _SurahMeta('An-Naba', 'النبأ', 40),
    79: _SurahMeta("An-Nazi'at", 'النازعات', 46),
    80: _SurahMeta("'Abasa", 'عبس', 42),
    81: _SurahMeta('At-Takwir', 'التكوير', 29),
    82: _SurahMeta('Al-Infitar', 'الانفطار', 19),
    83: _SurahMeta('Al-Mutaffifin', 'المطففين', 36),
    84: _SurahMeta('Al-Inshiqaq', 'الانشقاق', 25),
    85: _SurahMeta('Al-Buruj', 'البروج', 22),
    86: _SurahMeta('At-Tariq', 'الطارق', 17),
    87: _SurahMeta("Al-A'la", 'الأعلى', 19),
    88: _SurahMeta('Al-Ghashiyah', 'الغاشية', 26),
    89: _SurahMeta('Al-Fajr', 'الفجر', 30),
    90: _SurahMeta('Al-Balad', 'البلد', 20),
    91: _SurahMeta('Ash-Shams', 'الشمس', 15),
    92: _SurahMeta('Al-Lail', 'الليل', 21),
    93: _SurahMeta('Ad-Duha', 'الضحى', 11),
    94: _SurahMeta('Ash-Sharh', 'الشرح', 8),
    95: _SurahMeta('At-Tin', 'التين', 8),
    96: _SurahMeta("Al-'Alaq", 'العلق', 19),
    97: _SurahMeta('Al-Qadr', 'القدر', 5),
    98: _SurahMeta('Al-Bayyinah', 'البينة', 8),
    99: _SurahMeta('Az-Zalzalah', 'الزلزلة', 8),
    100: _SurahMeta("Al-'Adiyat", 'العاديات', 11),
    101: _SurahMeta("Al-Qari'ah", 'القارعة', 11),
    102: _SurahMeta('At-Takathur', 'التكاثر', 8),
    103: _SurahMeta("Al-'Asr", 'العصر', 3),
    104: _SurahMeta('Al-Humazah', 'الهمزة', 9),
    105: _SurahMeta('Al-Fil', 'الفيل', 5),
    106: _SurahMeta('Quraish', 'قريش', 4),
    107: _SurahMeta("Al-Ma'un", 'الماعون', 7),
    108: _SurahMeta('Al-Kauthar', 'الكوثر', 3),
    109: _SurahMeta('Al-Kafirun', 'الكافرون', 6),
    110: _SurahMeta('An-Nasr', 'النصر', 3),
    111: _SurahMeta('Al-Masad', 'المسد', 5),
    112: _SurahMeta('Al-Ikhlas', 'الإخلاص', 4),
    113: _SurahMeta('Al-Falaq', 'الفلق', 5),
    114: _SurahMeta('An-Nas', 'الناس', 6),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scanDownloads());
  }

  // ═════════════════════════════════════════════════════════════
  // SCAN — read the on-disk full-surah cache via the provider
  // ═════════════════════════════════════════════════════════════
  Future<void> _scanDownloads() async {
    setState(() => _loading = true);
    final dl = context.read<FullSurahDownloadProvider>();

    final groups = <_ReciterDownloads>[];
    for (final reciter in fullSurahReciters) {
      final surahs = await dl.listDownloaded(reciterId: reciter.id);
      if (surahs.isEmpty) continue;

      final sizeBytes = await dl.cacheSizeBytes(reciter.id);
      groups.add(
        _ReciterDownloads(
          reciter: reciter,
          surahs: surahs,
          sizeBytes: sizeBytes,
        ),
      );
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
      // ✅ Full-surah mini player (this replaces the old per-ayah one)
      //  bottomNavigationBar: const FullSurahMiniPlayer(),
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
  // LIST OF RECITERS — tap a card to open that reciter's surahs
  // ═════════════════════════════════════════════════════════════
  Widget _buildGroupsList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _reciterCard(_groups[i]),
    );
  }

  Widget _reciterCard(_ReciterDownloads group) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openReciterSurahs(group),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Avatar (imageAsset from the reciter) ──
              ClipOval(
                child: Image.network(
                  group.reciter.imageAsset,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: AppTheme.primary.withOpacity(0.10),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.primary,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.reciter.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      group.reciter.arabicName,
                      style: GoogleFonts.notoSansArabic(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${group.surahs.length} / 114 surahs',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                            textScaler: TextScaler.linear(1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '· ${_formatBytes(group.sizeBytes)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          textScaler: TextScaler.linear(1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Delete reciter downloads
              IconButton(
                tooltip: 'Delete all downloads for this Qari',
                icon: Icon(
                  customIcons.delete,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () => _confirmDelete(group),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.gold, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // OPEN RECITER → new screen with all surahs + search
  // ═════════════════════════════════════════════════════════════
  void _openReciterSurahs(_ReciterDownloads group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReciterDownloadsDetailScreen(
          reciter: group.reciter,
          surahNumbers: group.surahs,
        ),
      ),
    ).then((_) => _scanDownloads());
  }

  // ═════════════════════════════════════════════════════════════
  // DELETE ALL FOR A RECITER
  // ═════════════════════════════════════════════════════════════
  Future<void> _confirmDelete(_ReciterDownloads group) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete downloads?'),
        content: Text(
          'This will remove all ${group.surahs.length} surah(s) '
          'from ${group.reciter.name} (${_formatBytes(group.sizeBytes)}).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final dl = context.read<FullSurahDownloadProvider>();
    final player = context.read<FullSurahPlayer>();
    try {
      if (player.currentReciterId == group.reciter.id) {
        await player.stop();
      }
      await dl.deleteReciter(group.reciter.id);
      await _scanDownloads();
    } catch (error, stackTrace) {
      debugPrint('Could not delete downloads for ${group.reciter.id}: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete reciter downloads: $error')),
        );
      }
    }
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

// ── Model ──
class _ReciterDownloads {
  final FullSurahReciter reciter;
  final List<int> surahs;
  final int sizeBytes;

  _ReciterDownloads({
    required this.reciter,
    required this.surahs,
    required this.sizeBytes,
  });
}

class _SurahMeta {
  final String english;
  final String arabic;
  final int ayahCount;
  const _SurahMeta(this.english, this.arabic, this.ayahCount);
}

// ═════════════════════════════════════════════════════════════════
// RECITER DETAIL SCREEN — search + numbered surah list + instant play
// ═════════════════════════════════════════════════════════════════
class ReciterDownloadsDetailScreen extends StatefulWidget {
  final FullSurahReciter reciter;
  final List<int> surahNumbers;

  const ReciterDownloadsDetailScreen({
    super.key,
    required this.reciter,
    required this.surahNumbers,
  });

  @override
  State<ReciterDownloadsDetailScreen> createState() =>
      _ReciterDownloadsDetailScreenState();
}

class _ReciterDownloadsDetailScreenState
    extends State<ReciterDownloadsDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  late List<int> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = List.of(widget.surahNumbers)..sort();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = List.of(widget.surahNumbers)..sort();
        return;
      }

      // Match by number OR by name
      final numberMatch = int.tryParse(q);
      _filtered = widget.surahNumbers.where((n) {
        final meta = _AudioDownloadsScreenState._surahMeta[n];
        if (meta == null) return false;
        if (numberMatch != null && n == numberMatch) return true;
        return meta.english.toLowerCase().contains(q) ||
            meta.arabic.contains(q) ||
            'surah $n'.contains(q) ||
            '$n'.contains(q);
      }).toList()..sort();
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
        title: Row(
          children: [
            ClipOval(
              child: Image.network(
                widget.reciter.imageAsset,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 34,
                  height: 34,
                  color: Colors.white24,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.reciter.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${_filtered.length} downloaded',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14, color: AppTheme.primary),
              decoration: InputDecoration(
                hintText: 'Search by surah name or number…',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.primary,
                  size: 22,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppTheme.primary.withOpacity(0.10),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.gold,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),

          // ── Results ──
          Expanded(
            child: _filtered.isEmpty ? _buildNoResults() : _buildSurahList(),
          ),
        ],
      ),
      bottomNavigationBar: const FullSurahMiniPlayer(),
    );
  }

  Widget _buildNoResults() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No surah matched your search.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildSurahList() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _surahTile(_filtered[i]),
    );
  }

  Widget _surahTile(int surahNumber) {
    final meta = _AudioDownloadsScreenState._surahMeta[surahNumber];

    return Consumer<FullSurahPlayer>(
      builder: (context, player, _) {
        final isThisSurah =
            player.currentSurah == surahNumber &&
            player.currentReciterId == widget.reciter.id;
        final isPlaying = isThisSurah && player.isPlaying;
        final isPaused = isThisSurah && !player.isPlaying && player.hasSurah;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _playSurah(surahNumber, meta),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  // ── Star badge with number ──
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          size: 42,
                          color: AppTheme.gold.withOpacity(0.30),
                        ),
                        Text(
                          '$surahNumber',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                          textScaler: TextScaler.linear(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Name ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta?.english ?? 'Surah $surahNumber',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textScaler: TextScaler.linear(1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPlaying
                              ? 'Playing…'
                              : isPaused
                              ? 'Paused'
                              : '${meta?.ayahCount ?? "-"} ayahs · '
                                    'downloaded',
                          style: TextStyle(
                            fontSize: 11,
                            color: isThisSurah
                                ? AppTheme.gold
                                : AppTheme.textSecondary,
                            fontWeight: isThisSurah
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          textScaler: TextScaler.linear(1),
                        ),
                      ],
                    ),
                  ),

                  // ── Arabic name ──
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      meta?.arabic ?? '',
                      style: GoogleFonts.notoSansArabic(
                        fontSize: 16,
                        color: AppTheme.primary,
                      ),
                      textScaler: TextScaler.linear(1),
                    ),
                  ),

                  // ── Play / Pause button ──
                  Material(
                    color: isThisSurah
                        ? AppTheme.primary
                        : AppTheme.surfaceContainer,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _playSurah(surahNumber, meta),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: isThisSurah ? AppTheme.gold : AppTheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // ── Delete single surah button ──
                  IconButton(
                    tooltip: 'Delete downloaded surah',
                    icon: const Icon(
                      customIcons.delete,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => _confirmDeleteSurah(surahNumber, meta),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════
  // PLAY / PAUSE
  // ═════════════════════════════════════════════════════════════
  Future<void> _playSurah(int surahNumber, _SurahMeta? meta) async {
    final player = context.read<FullSurahPlayer>();

    final isThisSurah =
        player.currentSurah == surahNumber &&
        player.currentReciterId == widget.reciter.id;

    if (isThisSurah) {
      if (player.isPlaying) {
        await player.pause();
      } else {
        await player.resume();
      }
      return;
    }

    await player.playDownloaded(
      surahNumber: surahNumber,
      reciterId: widget.reciter.id,
      surahName: meta?.english ?? 'Surah $surahNumber',
    );

    if (!mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: Text(meta?.english ?? 'Surah $surahNumber'),
      description: Text(widget.reciter.name),
      autoCloseDuration: const Duration(seconds: 2),
      icon: const Icon(Icons.offline_pin),
    );
  }

  Future<void> _confirmDeleteSurah(int surahNumber, _SurahMeta? meta) async {
    final surahTitle = meta?.english ?? 'Surah ';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Surah?'),
        content: Text('Delete \ for \ from downloads?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final player = context.read<FullSurahPlayer>();
    if (player.currentSurah == surahNumber &&
        player.currentReciterId == widget.reciter.id) {
      await player.stop();
    }

    final dl = context.read<FullSurahDownloadProvider>();
    await dl.deleteSurahForReciter(surahNumber, reciterId: widget.reciter.id);

    setState(() {
      widget.surahNumbers.remove(surahNumber);
      _filtered.remove(surahNumber);
    });

    if (!mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      title: const Text('Deleted'),
      description: Text('\ deleted successfully'),
      autoCloseDuration: const Duration(seconds: 2),
      icon: const Icon(Icons.delete_outline),
    );
  }
}
