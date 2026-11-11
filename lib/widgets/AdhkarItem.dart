// ─────────────────────────────────────────────────────────────
// After-Salah Duas — scrollable tabs that fit their content
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdhkarItem {
  final String title;
  final IconData icon;
  final String arabic;
  final String urdu;
  final String repetition;
  final String reference;

  const AdhkarItem({
    required this.title,
    required this.icon,
    required this.arabic,
    required this.urdu,
    required this.repetition,
    required this.reference,
  });
}

const List<AdhkarItem> kAfterSalahDuas = [
  AdhkarItem(
    title: 'Istighfar',
    icon: Icons.favorite_border_rounded,
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    urdu: 'میں اللہ سے بخشش مانگتا ہوں۔',
    repetition: '3 مرتبہ',
    reference: 'صحیح مسلم 591',
  ),
  AdhkarItem(
    title: 'Durood',
    icon: Icons.mosque_outlined,
    arabic:
        'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَىٰ إِبْرَاهِيمَ وَعَلَىٰ آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
    urdu:
        'اے اللہ! درود نازل فرما محمد ﷺ پر اور آل محمد پر، جیسے تو نے درود نازل فرمایا ابراہیم علیہ السلام اور آل ابراہیم پر، بے شک تو تعریف والا بزرگی والا ہے۔',
    repetition: '10 مرتبہ',
    reference: 'صحیح بخاری 3370',
  ),
  AdhkarItem(
    title: 'Ayatul Kursi',
    icon: Icons.menu_book_rounded,
    arabic:
        'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ...',
    urdu:
        'اللہ، اس کے سوا کوئی معبود نہیں، وہ زندہ اور قائم رہنے والا ہے، نہ اسے اونگھ آتی ہے نہ نیند...',
    repetition: '1 مرتبہ',
    reference: 'سورۃ البقرہ 2:255',
  ),
  AdhkarItem(
    title: 'Tasbih Fatimah',
    icon: Icons.circle_outlined,
    arabic:
        'سُبْحَانَ اللَّهِ (33) • الْحَمْدُ لِلَّهِ (33) • اللَّهُ أَكْبَرُ (34)',
    urdu:
        'اللہ پاک ہے (33 بار) • سب تعریف اللہ کے لیے (33 بار) • اللہ سب سے بڑا ہے (34 بار)',
    repetition: '33 · 33 · 34',
    reference: 'صحیح مسلم 597',
  ),
];

// ─────────────────────────────────────────────────────────────
// Section
// ─────────────────────────────────────────────────────────────
class AfterSalahDuasSection extends StatefulWidget {
  const AfterSalahDuasSection({super.key});

  @override
  State<AfterSalahDuasSection> createState() => _AfterSalahDuasSectionState();
}

class _AfterSalahDuasSectionState extends State<AfterSalahDuasSection> {
  static const _primary = Color(0xFF0F3D26);
  static const _gold = Color(0xFFC9A227);
  static const _ink = Color(0xFF14201A);

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final item = kAfterSalahDuas[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: _gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'After Salah Duas',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // ── Tab strip: each tab shrinks to fit its content ──
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: kAfterSalahDuas.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final isSelected = index == _selectedIndex;
              final tab = kAfterSalahDuas[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _selectedIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    // No fixed width — grows to fit content
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? _primary : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? _primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 16,
                          color: isSelected ? _gold : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tab.title,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),

        // ── Dua card ──
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _DuaCard(
            key: ValueKey(_selectedIndex),
            item: item,
            primary: _primary,
            gold: _gold,
            ink: _ink,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Minimal dua card
// ─────────────────────────────────────────────────────────────
class _DuaCard extends StatelessWidget {
  final AdhkarItem item;
  final Color primary;
  final Color gold;
  final Color ink;

  const _DuaCard({
    super.key,
    required this.item,
    required this.primary,
    required this.gold,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arabic
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              item.arabic,
              textAlign: TextAlign.right,
              style: GoogleFonts.amiriQuran(
                fontSize: 18,
                height: 1.9,
                color: primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Divider
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: Colors.grey.shade200),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Transform.rotate(
                  angle: 0.785,
                  child: Container(
                    width: 3,
                    height: 3,
                    color: gold.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 1, color: Colors.grey.shade200),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Urdu
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(
              item.urdu,
              textAlign: TextAlign.right,
              style: GoogleFonts.notoNastaliqUrdu(
                fontSize: 12,
                height: 2.1,
                color: ink.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Footer
          Row(
            children: [
              Icon(Icons.repeat_rounded, size: 12, color: primary),
              const SizedBox(width: 4),
              Text(
                item.repetition,
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 10,
                  height: 1.9,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
              const Spacer(),
              Text(
                item.reference,
                style: GoogleFonts.notoNastaliqUrdu(
                  fontSize: 9.5,
                  height: 1.9,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
