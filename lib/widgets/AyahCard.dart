import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/models/models.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranProvider.dart';

class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final int surahNumber;
  final bool highlight;

  const AyahCard({
    super.key,
    required this.ayah,
    required this.surahNumber,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();
    final isBookmarked = provider.isBookmarked(surahNumber, ayah.numberInSurah);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.gold.withOpacity(0.15)
            : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppTheme.gold : AppTheme.gold.withOpacity(0.2),
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ayah header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                // Verse number
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${ayah.numberInSurah}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'آیت ${ayah.numberInSurah}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                // Juz info
                Text(
                  'پارہ ${ayah.juz}',
                  style: TextStyle(
                    color: AppTheme.primary.withOpacity(0.7),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                // Bookmark button
                InkWell(
                  onTap: () => provider.toggleBookmark(surahNumber, ayah.numberInSurah),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? AppTheme.gold : AppTheme.textSecondary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Arabic text
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              ayah.text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: provider.arabicFontSize,
                fontFamily: 'serif',
                color: AppTheme.arabicText,
                height: 2.2,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Urdu translation
          if (provider.showUrdu && ayah.textUrdu != null) ...[
            const Divider(indent: 16, endIndent: 16, height: 1, color: AppTheme.gold),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.urduText.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'اردو ترجمہ',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.urduText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ayah.textUrdu!,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: provider.translationFontSize + 2,
                      color: AppTheme.urduText,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // English translation
          if (provider.showEnglish && ayah.textEnglish != null) ...[
            const Divider(indent: 16, endIndent: 16, height: 1, color: AppTheme.gold),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.englishText.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'English Translation',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.englishText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ayah.textEnglish!,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: provider.translationFontSize,
                      color: AppTheme.englishText,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!provider.showUrdu && !provider.showEnglish)
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}