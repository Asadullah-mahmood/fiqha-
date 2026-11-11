import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/models/models.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/BookmarkProvider.dart';
import 'package:quranpak/utils/QuranAudioPlayer.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:toastification/toastification.dart';

class AyahCard extends StatelessWidget {
  final Ayah ayah;
  final int surahNumber;
  final bool highlight;
  final VoidCallback? onChangeTranslation;

  const AyahCard({
    super.key,
    required this.ayah,
    required this.surahNumber,
    this.highlight = false,
    this.onChangeTranslation,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();
    final bookmarks = context.watch<BookmarkProvider>();
    final audioPlayer = context.watch<QuranAudioPlayer>();

    final isBookmarked = bookmarks.isBookmarked(surahNumber, ayah.numberInSurah);
    final isPlaying = audioPlayer.isAyahPlaying(surahNumber, ayah.numberInSurah);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.gold.withValues(alpha: 0.12)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlight ? AppTheme.gold : AppTheme.gold.withValues(alpha: 0.25),
          width: highlight ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top Header bar: Surah:Ayah info & Juz ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                // Star / Circle verse badge
                Container(
                  width: 32,
                  height: 32,
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
                const SizedBox(width: 10),
                Text(
                  ayah.surahEnglishName != null && ayah.surahEnglishName!.isNotEmpty
                      ? '${ayah.surahEnglishName} : ${ayah.numberInSurah}'
                      : 'Verse ${ayah.numberInSurah}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Juz ${ayah.juz}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Arabic Text ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              ayah.text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: provider.arabicFontStyle(
                fontSize: provider.arabicFontSize,
                color: AppTheme.arabicText,
                height: 2.2,
              ),
            ),
          ),

          // ── Translations ──
          if (provider.translationEnabled)
            for (
              var index = 0;
              index < provider.selectedTranslationEditions.length;
              index++
            )
              if (_translationFor(ayah, index)?.isNotEmpty == true) ...[
                const Divider(
                  indent: 18,
                  endIndent: 18,
                  height: 1,
                  color: Color(0xFFE8E0D0),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  child: _buildTranslationText(
                    provider,
                    provider.selectedTranslationEditions[index],
                    _translationFor(ayah, index)!,
                  ),
                ),
              ],

          const Divider(
            height: 1,
            color: Color(0xFFEFE8DA),
          ),

          // ── Card Action Icons (strictly bottom-left aligned) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // 1. Change Translation Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onChangeTranslation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.translate_rounded,
                            size: 18,
                            color: AppTheme.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Translation',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // 2. Bookmark Icon
                IconButton(
                  tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Ayat',
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                    color: isBookmarked ? AppTheme.gold : AppTheme.primary,
                    size: 22,
                  ),
                  onPressed: () async {
                    if (isBookmarked) {
                      await bookmarks.removeByAyah(surahNumber, ayah.numberInSurah);
                      if (context.mounted) {
                        toastification.show(
                          context: context,
                          type: ToastificationType.info,
                          style: ToastificationStyle.flatColored,
                          title: const Text('Bookmark removed'),
                          autoCloseDuration: const Duration(seconds: 2),
                        );
                      }
                    } else {
                      final saved = await bookmarks.add(
                        surahNumber: surahNumber,
                        ayahNumber: ayah.numberInSurah,
                        surahName: ayah.surahName ?? '',
                        surahEnglishName: ayah.surahEnglishName ?? '',
                        ayahPreview: ayah.text,
                      );
                      if (context.mounted && saved) {
                        toastification.show(
                          context: context,
                          type: ToastificationType.success,
                          style: ToastificationStyle.flatColored,
                          title: const Text('Ayat bookmarked'),
                          autoCloseDuration: const Duration(seconds: 2),
                        );
                      }
                    }
                  },
                ),

                const SizedBox(width: 4),

                // 3. Ayat Sound Icon
                IconButton(
                  tooltip: isPlaying ? 'Pause Recitation' : 'Play Ayat Audio',
                  icon: Icon(
                    isPlaying ? Icons.pause_circle_filled : Icons.volume_up_rounded,
                    color: isPlaying ? AppTheme.gold : AppTheme.primary,
                    size: 24,
                  ),
                  onPressed: () async {
                    await audioPlayer.playSingleAyah(
                      surahNumber: surahNumber,
                      ayahNumber: ayah.numberInSurah,
                      surahName: ayah.surahEnglishName,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _translationFor(Ayah ayah, int index) =>
      index == 0 ? ayah.translation : ayah.secondTranslation;

  Widget _buildTranslationText(
    QuranProvider provider,
    String editionIdentifier,
    String translation,
  ) {
    final isRtl = [
      'ur',
      'ar',
    ].contains(provider.translationLanguageFor(editionIdentifier));
    final edition = provider.translationEditionFor(editionIdentifier);
    return Column(
      crossAxisAlignment: isRtl
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                edition?.englishName ?? editionIdentifier,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          translation,
          textAlign: isRtl ? TextAlign.right : TextAlign.left,
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          style: TextStyle(
            fontSize: provider.translationFontSize,
            color: AppTheme.textPrimary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
