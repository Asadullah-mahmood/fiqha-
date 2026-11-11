import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Downloads & caches **one full-surah MP3 per surah** — not per-ayah.
class FullSurahAudioService {
  static final FullSurahAudioService _instance = FullSurahAudioService._();
  factory FullSurahAudioService() => _instance;
  FullSurahAudioService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
      responseType: ResponseType.bytes,
      validateStatus: (c) => c != null && c >= 200 && c < 300,
    ),
  );

  // ── Single source of truth for paths ──
  Future<String> _filePath(String reciterId, int surahNumber) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/quran_full/$reciterId/surah_$surahNumber.mp3';
  }

  Future<String> resolvePath({
    required String reciterId,
    required int surahNumber,
  }) => _filePath(reciterId, surahNumber);

  Future<bool> isDownloaded({
    required String reciterId,
    required int surahNumber,
  }) async {
    final f = File(await _filePath(reciterId, surahNumber));
    return (await f.exists()) && (await f.length()) > 50 * 1024; // >50 KB
  }

  Future<File> downloadSurah({
    required String url,
    required String reciterId,
    required int surahNumber,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final filePath = await _filePath(reciterId, surahNumber);
    final file = File(filePath);

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    // Cached? Skip.
    if (await file.exists() && (await file.length()) > 50 * 1024) {
      return file;
    }

    // Download to a .part file first, then rename atomically.
    final tmpPath = '$filePath.part';
    final tmp = File(tmpPath);
    if (await tmp.exists()) await tmp.delete();

    try {
      final options = Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
        },
      );

      await _dio.download(
        url,
        tmpPath,
        cancelToken: cancelToken,
        options: options,
        onReceiveProgress: onProgress,
      );

      if (!await tmp.exists() || (await tmp.length()) < 50 * 1024) {
        if (await tmp.exists()) await tmp.delete();
        throw Exception('Downloaded file invalid (too small): $url');
      }

      if (await file.exists()) await file.delete();
      await tmp.rename(filePath);
      return file;
    } catch (e) {
      if (await tmp.exists()) await tmp.delete();
      rethrow;
    }
  }

  Future<void> deleteSurah({
    required String reciterId,
    required int surahNumber,
  }) async {
    final f = File(await _filePath(reciterId, surahNumber));
    if (await f.exists()) await f.delete();
  }

  Future<void> deleteReciter(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${dir.path}/quran_full/$reciterId');
    if (await recDir.exists()) {
      await recDir.delete(recursive: true);
    }
  }

  Future<int> getCacheSizeBytes([String? reciterId]) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = reciterId == null
        ? Directory('${dir.path}/quran_full')
        : Directory('${dir.path}/quran_full/$reciterId');
    if (!await target.exists()) return 0;
    int total = 0;
    await for (final e in target.list(recursive: true)) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  Future<List<int>> listDownloadedSurahs(String reciterId) async {
    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${dir.path}/quran_full/$reciterId');
    if (!await recDir.exists()) return [];
    final out = <int>[];
    await for (final e in recDir.list()) {
      if (e is File && e.path.endsWith('.mp3')) {
        // Cross-platform basename extraction
        final name = p.basename(e.path); // surah_36.mp3
        final m = RegExp(r'surah_(\d+)\.mp3').firstMatch(name);
        if (m != null) {
          final n = int.tryParse(m.group(1)!);
          if (n != null && await e.length() > 50 * 1024) out.add(n);
        }
      }
    }
    out.sort();
    return out;
  }
}
