import 'package:flutter_test/flutter_test.dart';
import 'package:quranpak/models/LastReadProgress.dart';

void main() {
  final progress = LastReadProgress(
    surahNumber: 2,
    ayahNumber: 13,
    juzNumber: 1,
    surahName: 'البقرة',
    surahEnglishName: 'Al-Baqarah',
    readerType: 'juz',
    readerSectionNumber: 1,
    updatedAt: DateTime.parse('2026-10-07T12:00:00.000Z'),
  );

  test('persists the location and reader section in the local record', () {
    final restored = LastReadProgress.fromMap(
      progress.toMap(userId: 'user-1', syncState: 1),
    );

    expect(restored.surahNumber, 2);
    expect(restored.ayahNumber, 13);
    expect(restored.juzNumber, 1);
    expect(restored.readerType, 'juz');
    expect(restored.readerSectionNumber, 1);
    expect(restored.updatedAt.toUtc(), progress.updatedAt);
  });

  test('serializes last-read progress for the cloud document', () {
    final restored = LastReadProgress.fromFirestore(progress.toFirestore());

    expect(restored.surahNumber, 2);
    expect(restored.ayahNumber, 13);
    expect(restored.surahEnglishName, 'Al-Baqarah');
    expect(restored.readerType, 'juz');
    expect(restored.readerSectionNumber, 1);
    expect(restored.updatedAt, progress.updatedAt);
  });
}
