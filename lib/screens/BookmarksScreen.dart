import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quranpak/utils/AppTheme.dart';
import 'package:quranpak/utils/QuranProvider.dart';
import 'package:quranpak/screens/SurahReaderScreen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuranProvider>();
    final bookmarks = provider.bookmarks.toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Book Marks', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 80, color: AppTheme.primary.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  const Text(
                    'No BookMark Available',
                    style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                final parts = bookmark.split(':');

                if (parts.length < 2) {
                  return const SizedBox.shrink(); // Skip malformed bookmark
                }

                try {
                  final surahNum = int.parse(parts[0]);
                  final ayahNum = int.parse(parts[1]);

                  final surah = provider.allSurahs.firstWhere(
                        (s) => s.number == surahNum,
                    orElse: () => provider.allSurahs.first,
                  );

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$surahNum',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      title: Text(
                        surah.englishName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('آیت نمبر $ayahNum'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => provider.toggleBookmark(surahNum, ayahNum),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SurahReaderScreen(
                              surahNumber: surahNum,
                              scrollToAyah: ayahNum,
                            ),
                          ),
                        );
                      },
                    ),
                  );

                }catch (e){
                  throw Exception("Error: $e");
                }
              },
            ),
    );
  }
}
