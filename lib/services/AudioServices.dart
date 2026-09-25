import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class AudioDownloadService {
  static final AudioDownloadService _instance = AudioDownloadService._();
  factory AudioDownloadService() => _instance;
  AudioDownloadService._();

  final Dio _dio = Dio();

  // ─────────────────────────────────────────────────────────────
  // SINGLE SOURCE OF TRUTH FOR PATHS
  // ─────────────────────────────────────────────────────────────
  Future<String> _filePath({
    required String reciterId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/quran_audio/$reciterId/$surahNumber/ayah_$ayahNumber.mp3';
  }

  Future<String> resolvePath({
    required String reciterId,
    required int surahNumber,
    required int ayahNumber,
  }) =>
      _filePath(
        reciterId: reciterId,
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
      );

  // ─────────────────────────────────────────────────────────────
  // DOWNLOAD
  // ─────────────────────────────────────────────────────────────
  Future<File> downloadAyahAudio({
    required String url,
    required String reciterId,
    required int surahNumber,
    required int ayahNumber,
    void Function(int received, int total)? onProgress,
  }) async {
    final filePath = await _filePath(
      reciterId: reciterId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    final file = File(filePath);

    // Ensure folder exists
    final parent = file.parent;
    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    // Already cached
    if (await file.exists() && (await file.length()) > 0) {
      return file;
    }

    // Download
    await _dio.download(
      url,
      filePath,
      onReceiveProgress: onProgress,
      options: Options(
        receiveTimeout: const Duration(minutes: 2),
        sendTimeout: const Duration(seconds: 30),
        // Prevent HTML error pages from being saved as mp3
        responseType: ResponseType.bytes,
        validateStatus: (code) => code != null && code >= 200 && code < 300,
      ),
    );

    // Sanity-check: file must exist and be non-empty
    if (!await file.exists() || (await file.length()) < 1024) {
      // Too small → probably an error page
      if (await file.exists()) await file.delete();
      throw Exception('Downloaded file is invalid (too small): $url');
    }

    return file;
  }

  Future<bool> isDownloaded({
    required String reciterId,
    required int surahNumber,
    required int ayahNumber,
  }) async {
    final filePath = await _filePath(
      reciterId: reciterId,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    final file = File(filePath);
    return (await file.exists()) && (await file.length()) > 1024;
  }

  Future<void> deleteSurahAudio({
    required String reciterId,
    required int surahNumber,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir =
    Directory('${dir.path}/quran_audio/$reciterId/$surahNumber');
    if (await audioDir.exists()) {
      await audioDir.delete(recursive: true);
    }
  }

  Future<int> getCacheSizeBytes() async {
    final dir = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${dir.path}/quran_audio');
    if (!await audioDir.exists()) return 0;
    int total = 0;
    await for (final entity in audioDir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  Future<List<String>> listRecitersWithDownloads() async {
    final dir = await getApplicationDocumentsDirectory();
    final root = Directory('${dir.path}/quran_audio');
    if (!await root.exists()) return [];

    final result = <String>[];
    await for (final entity in root.list()) {
      if (entity is Directory) {
        final name = entity.path.split('/').last;
        // Only include if it has at least one non-empty surah folder
        final surahs = await entity.list().toList();
        if (surahs.any((e) => e is Directory)) result.add(name);
      }
    }
    return result;
  }

  /// Returns all surah numbers downloaded for a given reciter.
  Future<List<int>> listDownloadedSurahs(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final reciterDir = Directory('${dir.path}/quran_audio/$reciterId');
    if (!await reciterDir.exists()) return [];

    final surahs = <int>[];
    await for (final entity in reciterDir.list()) {
      if (entity is Directory) {
        final num = int.tryParse(entity.path.split('/').last);
        if (num != null) {
          // Verify at least one ayah file exists
          final hasAyahs = await entity
              .list()
              .any((f) => f is File && f.path.endsWith('.mp3'));
          if (hasAyahs) surahs.add(num);
        }
      }
    }
    surahs.sort();
    return surahs;
  }

  /// Count ayahs downloaded for a given (reciter, surah).
  Future<int> countAyahs(String reciterId, int surahNumber) async {
    final dir = await getApplicationDocumentsDirectory();
    final surahDir =
    Directory('${dir.path}/quran_audio/$reciterId/$surahNumber');
    if (!await surahDir.exists()) return 0;

    int count = 0;
    await for (final entity in surahDir.list()) {
      if (entity is File && entity.path.endsWith('.mp3')) {
        final len = await entity.length();
        if (len > 1024) count++;
      }
    }
    return count;
  }

  /// Total size in bytes for a reciter (or all if null).
  Future<int> getReciterSizeBytes(String? reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = reciterId == null
        ? Directory('${dir.path}/quran_audio')
        : Directory('${dir.path}/quran_audio/$reciterId');
    if (!await target.exists()) return 0;

    int total = 0;
    await for (final entity in target.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Delete everything for a reciter.
  Future<void> deleteReciter(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final reciterDir = Directory('${dir.path}/quran_audio/$reciterId');
    if (await reciterDir.exists()) {
      await reciterDir.delete(recursive: true);
    }
  }
}