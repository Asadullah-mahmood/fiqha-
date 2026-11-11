import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  // Current count for the active dhikr
  int _count = 0;

  // Selected dhikr index (0 = Darood-e-Pak)
  int _selectedDhikrIndex = 0;

  // Total lifetime count for this session (all dhikr combined)
  int _sessionTotal = 0;

  // Preset dhikr list
  static const List<Map<String, dynamic>> _dhikrList = [
    {
      'arabic': 'صَلَّى اللّٰهُ عَلَيْهِ وَسَلَّمَ',
      'transliteration': 'Darood-e-Pak',
      'meaning': 'Peace and blessings upon the Prophet ﷺ',
      'target': 0, // 0 = unlimited / infinite
    },
    {
      'arabic': 'سُبْحَانَ اللّٰه',
      'transliteration': 'SubhanAllah',
      'meaning': 'Glory be to Allah',
      'target': 33,
    },
    {
      'arabic': 'اَلْحَمْدُ لِلّٰه',
      'transliteration': 'Alhamdulillah',
      'meaning': 'All praise is for Allah',
      'target': 33,
    },
    {
      'arabic': 'اَللّٰهُ أَكْبَر',
      'transliteration': 'Allahu Akbar',
      'meaning': 'Allah is the Greatest',
      'target': 34,
    },
    {
      'arabic': 'لَا إِلٰهَ إِلَّا اللّٰه',
      'transliteration': 'La ilaha illallah',
      'meaning': 'There is no god but Allah',
      'target': 100,
    },
    {
      'arabic': 'أَسْتَغْفِرُ اللّٰه',
      'transliteration': 'Astaghfirullah',
      'meaning': 'I seek forgiveness from Allah',
      'target': 100,
    },
    {
      'arabic': 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰه',
      'transliteration': 'La hawla wa la quwwata illa billah',
      'meaning': 'There is no power except with Allah',
      'target': 100,
    },
  ];

  /// Currently selected dhikr map.
  Map<String, dynamic> get _currentDhikr => _dhikrList[_selectedDhikrIndex];

  /// Target is ALWAYS derived from the selected dhikr — never stored separately,
  /// so it can never desync. 0 means infinite.
  int get _target => _currentDhikr['target'] as int;

  /// True when the current dhikr has no cap (Darood-e-Pak, etc.).
  bool get _isInfinite => _target == 0;

  // ─────────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────────

  void _increment() {
    // Block only when a finite target has been reached.
    if (!_isInfinite && _count >= _target) return;

    HapticFeedback.lightImpact();

    setState(() {
      _count++;
      _sessionTotal++;
    });

    // Fire completion feedback only for finite targets.
    if (!_isInfinite && _count == _target) {
      HapticFeedback.mediumImpact();
      _showTargetReachedSnack();
    }
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() => _count = 0);
  }

  void _selectDhikr(int index) {
    if (index == _selectedDhikrIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDhikrIndex = index;
      _count = 0;
    });
  }

  void _showTargetReachedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Target reached: ${_currentDhikr['transliteration']} × $_target',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F3D26),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isComplete = !_isInfinite && _count >= _target;
    final progress = _isInfinite
        ? 0.0
        : (_count / _target).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Tasbih Counter',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Session total ───────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history,
                        size: 16, color: Color(0xFF8D6E63)),
                    const SizedBox(width: 6),
                    Text(
                      'Session total: $_sessionTotal',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Dhikr display card ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3D26),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text(
                      _currentDhikr['arabic'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 32,
                        color: Colors.white,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentDhikr['transliteration'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE2B76C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentDhikr['meaning'] as String,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Counter circle ──────────────────────────────────────────────
              GestureDetector(
                onTap: _increment,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: isComplete
                          ? const Color(0xFFE2B76C)
                          : const Color(0xFF1B5E20),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isComplete
                                ? const Color(0xFFE2B76C)
                                : const Color(0xFF1B5E20))
                            .withOpacity(0.15),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$_count',
                        style: GoogleFonts.inter(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F3D26),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isInfinite ? '∞ unlimited' : 'of $_target',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Progress bar (hidden when infinite) ─────────────────────────
              if (!_isInfinite) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete
                          ? const Color(0xFFE2B76C)
                          : const Color(0xFF1B5E20),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                _isInfinite
                    ? 'Tap freely — this dhikr has no limit'
                    : isComplete
                        ? 'Target completed — may Allah accept it'
                        : 'Tap the circle to count',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // ── Reset button ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Reset Counter',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B5E20),
                    side: const BorderSide(
                        color: Color(0xFF1B5E20), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Dhikr picker ────────────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose Dhikr',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _dhikrList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final dhikr = _dhikrList[index];
                  final isSelected = index == _selectedDhikrIndex;
                  final target = dhikr['target'] as int;
                  final isInfinite = target == 0;

                  return GestureDetector(
                    onTap: () => _selectDhikr(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1B5E20).withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1B5E20)
                              : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dhikr['arabic'] as String,
                                  style: GoogleFonts.amiri(
                                    fontSize: 20,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dhikr['transliteration'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dhikr['meaning'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1B5E20)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isInfinite ? '∞' : '× $target',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}