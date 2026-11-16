import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────────────
  int _count = 0;
  int _selectedDhikrIndex = 0;
  int _sessionTotal = 0;

  // Animation controllers
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final AnimationController _switchController;

  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;
  late final Animation<double> _circleScale;
  late final Animation<double> _cardFade;
  late final Animation<double> _switchScale;

  static const List<Map<String, dynamic>> _dhikrList = [
    {
      'arabic': 'صَلَّى اللّٰهُ عَلَيْهِ وَسَلَّمَ',
      'transliteration': 'Darood-e-Pak',
      'meaning': 'Peace and blessings upon the Prophet ﷺ',
      'target': 0,
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

  Map<String, dynamic> get _currentDhikr => _dhikrList[_selectedDhikrIndex];
  int get _target => _currentDhikr['target'] as int;
  bool get _isInfinite => _target == 0;

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    _switchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: 1.0,
    );

    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));
    _circleScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.9, curve: Curves.easeOutBack),
      ),
    );
    _cardFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOut),
    );
    _switchScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 60,
      ),
    ]).animate(CurvedAnimation(
      parent: _switchController,
      curve: Curves.easeInOut,
    ));

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _switchController.dispose();
    super.dispose();
  }

  // ── Actions ──────────────────────────────────────────────────────────────
  Future<void> _increment() async {
    if (!_isInfinite && _count >= _target) return;

    HapticFeedback.lightImpact();
    _pulseController.forward(from: 0.0);

    setState(() {
      _count++;
      _sessionTotal++;
    });

    if (!_isInfinite && _count == _target) {
      HapticFeedback.mediumImpact();
      _showTargetReachedSnack();

      // Let the user see the completed count for a beat, then auto-advance
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      await _advanceToNextDhikr();
    }
  }

  Future<void> _advanceToNextDhikr() async {
    // Wraps around to the first dhikr after the last one
    final nextIndex = (_selectedDhikrIndex + 1) % _dhikrList.length;

    // Animate: fade/scale current card out
    await _switchController.reverse();

    if (!mounted) return;
    setState(() {
      _selectedDhikrIndex = nextIndex;
      _count = 0;
    });

    // Animate: new card in
    await _switchController.forward(from: 0.0);

    HapticFeedback.selectionClick();
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
    _switchController.forward(from: 0.0);
  }

  void _showTargetReachedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_currentDhikr['transliteration']} complete — moving to next…',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F3D26),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isComplete = !_isInfinite && _count >= _target;
    final progress = _isInfinite ? 0.0 : (_count / _target).clamp(0.0, 1.0);

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

              // ── Session total (fade in) ──────────────────────────────────
              FadeTransition(
                opacity: _entryFade,
                child: SlideTransition(
                  position: _entrySlide,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
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
                ),
              ),
              const SizedBox(height: 24),

              // ── Dhikr display card (fades + scales between dhikr) ───────
              FadeTransition(
                opacity: _cardFade,
                child: ScaleTransition(
                  scale: _switchScale,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F3D26),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F3D26)
                              .withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
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
                ),
              ),
              const SizedBox(height: 32),

              // ── Counter circle with progress ring + pulse ────────────────
              ScaleTransition(
                scale: _circleScale,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final t = _pulseController.value; // 0..0.06
                    return Transform.scale(
                      scale: 1.0 + t,
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: _increment,
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress ring
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              tween: Tween(begin: 0, end: progress),
                              builder: (context, value, _) {
                                return CircularProgressIndicator(
                                  value: _isInfinite ? null : value,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                    isComplete
                                        ? const Color(0xFFE2B76C)
                                        : const Color(0xFF1B5E20),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Inner circle
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: (isComplete
                                      ? const Color(0xFFE2B76C)
                                      : const Color(0xFF1B5E20))
                                      .withOpacity(0.20),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                        scale: anim,
                                        child: FadeTransition(
                                          opacity: anim,
                                          child: child,
                                        ),
                                      ),
                                  child: Text(
                                    '$_count',
                                    key: ValueKey<int>(_count),
                                    style: GoogleFonts.inter(
                                      fontSize: 72,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F3D26),
                                      height: 1,
                                    ),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Tap the circle to count',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // ── Reset button ────────────────────────────────────────────
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

              // ── Dhikr picker ────────────────────────────────────────────
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

                  // Staggered entrance animation per list item
                  final start = 0.4 + (index * 0.06);
                  final end = (start + 0.3).clamp(0.0, 1.0);
                  final fade = CurvedAnimation(
                    parent: _entryController,
                    curve: Interval(start, end, curve: Curves.easeOut),
                  );
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.20),
                    end: Offset.zero,
                  ).animate(fade);

                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(
                      position: slide,
                      child: GestureDetector(
                        onTap: () => _selectDhikr(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1B5E20)
                                .withOpacity(0.08)
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