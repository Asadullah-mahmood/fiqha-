import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../helper/hadith_db.dart';
import '../models/HadithItemModel.dart';
import 'HadithDetailScreen.dart';

class HadithCollectionListScreen extends StatefulWidget {
  final String dbFileName;
  final int chapterId;
  final String chapterTitle;

  const HadithCollectionListScreen({
    super.key,
    required this.dbFileName,
    required this.chapterId,
    required this.chapterTitle,
  });

  @override
  State<HadithCollectionListScreen> createState() =>
      _HadithCollectionListScreenState();
}

class _HadithCollectionListScreenState
    extends State<HadithCollectionListScreen> {
  late final Future<List<HadithItemModel>> _futureHadiths =
      HadithDb.getHadiths(widget.dbFileName, widget.chapterId);

  String _selectedGradeFilter = 'all'; // 'all', 'sahih', 'hasan', 'daif'

  String _getGradeUrdu(String grade) {
    final g = grade.toLowerCase();
    if (g.contains('hasan') || g.contains('حسن')) return 'حسن (Hasan)';
    if (g.contains('daif') || g.contains('ضعیف') || g.contains('da\'if') || g.contains('daeef')) {
      return 'ضعیف (Da\'if)';
    }
    return 'صحیح (Sahih)';
  }

  Color _getGradeColor(String grade) {
    final g = grade.toLowerCase();
    if (g.contains('hasan') || g.contains('حسن')) return Colors.orange[800]!;
    if (g.contains('daif') || g.contains('ضعیف') || g.contains('da\'if') || g.contains('daeef')) {
      return Colors.red[700]!;
    }
    return Colors.green[700]!;
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0F3D26);
    const gold = Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: Text(
          widget.chapterTitle,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<HadithItemModel>>(
        future: _futureHadiths,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading hadiths:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.red),
                ),
              ),
            );
          }

          final hadiths = snapshot.data ?? [];
          if (hadiths.isEmpty) {
            return Center(
              child: Text(
                'No hadiths found in this chapter',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          // Filter by grade
          final filtered = hadiths.where((h) {
            if (_selectedGradeFilter == 'all') return true;
            final g = h.grade.toLowerCase();
            if (_selectedGradeFilter == 'sahih') {
              return g.contains('sahih') || g.contains('صحیح') || g.isEmpty;
            }
            if (_selectedGradeFilter == 'hasan') {
              return g.contains('hasan') || g.contains('حسن');
            }
            if (_selectedGradeFilter == 'daif') {
              return g.contains('daif') || g.contains('ضعیف') || g.contains('da\'if') || g.contains('daeef');
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Grading Filter Chips / Tabs (All, Sahih, Hasan, Da'if)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                color: Colors.white,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'سب (All)', Icons.all_inclusive),
                      const SizedBox(width: 8),
                      _buildFilterChip('sahih', 'صحیح (Sahih)', Icons.verified),
                      const SizedBox(width: 8),
                      _buildFilterChip('hasan', 'حسن (Hasan)', Icons.star_border),
                      const SizedBox(width: 8),
                      _buildFilterChip('daif', 'ضعیف (Da\'if)', Icons.info_outline),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No hadiths found for this filter',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final h = filtered[index];
                          final gradeLabel = _getGradeUrdu(h.grade.isNotEmpty ? h.grade : h.category);
                          final gradeColor = _getGradeColor(h.grade.isNotEmpty ? h.grade : h.category);

                          return Card(
                            elevation: 1.2,
                            margin: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: gold.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        HadithDetailScreen(hadith: h.toHadith()),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Hadith ${h.hadithNumber}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text(
                                            gradeLabel,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          backgroundColor: gradeColor,
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.copy,
                                              size: 20, color: Colors.grey),
                                          tooltip: 'Copy Hadith',
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(
                                              text:
                                                  '${h.arabic}\n\n${h.urdu}\n\n${h.english}\n\n— Hadith ${h.hadithNumber}',
                                            ));
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Hadith copied to clipboard')),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    if (h.arabic.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            h.arabic,
                                            textAlign: TextAlign.right,
                                            maxLines: 5,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.amiri(
                                              fontSize: 20,
                                              height: 1.8,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (h.urdu.isNotEmpty) ...[
                                      const Divider(height: 20, thickness: 1),
                                      Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: Text(
                                            h.urdu,
                                            textAlign: TextAlign.right,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.notoNastaliqUrdu(
                                              fontSize: 15,
                                              height: 1.9,
                                              color: Colors.grey[900],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Tap to read full hadith →',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: gold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    const primary = Color(0xFF0F3D26);
    final isSelected = _selectedGradeFilter == value;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : primary),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: primary,
      labelStyle: GoogleFonts.inter(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : primary,
      ),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? primary : Colors.grey.shade300,
          width: 1,
        ),
      ),
      onSelected: (_) {
        setState(() {
          _selectedGradeFilter = value;
        });
      },
    );
  }
}
