import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/FullSurahReciter.dart';
import 'AudioServices.dart';
import 'FullSurahAudioService.dart';

enum SurahDlStatus { idle, queued, downloading, done, failed }

class SurahDownloadProgress {
  final int surahNumber;
  final SurahDlStatus status;
  final double progress; // 0..1
  final String? error;

  const SurahDownloadProgress({
    required this.surahNumber,
    this.status = SurahDlStatus.idle,
    this.progress = 0,
    this.error,
  });

  SurahDownloadProgress copyWith({
    SurahDlStatus? status,
    double? progress,
    String? error,
  }) => SurahDownloadProgress(
    surahNumber: surahNumber,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    error: error,
  );
}

class FullSurahDownloadProvider extends ChangeNotifier {
  static const String _prefKeyDefaultReciter = 'full_surah_default_reciter';

  final FullSurahAudioService _svc = FullSurahAudioService();

  String _selectedReciterId = fullSurahReciters.first.id;
  String get selectedReciterId => _selectedReciterId;
  bool _cancelRequested = false;
  String? _activeReciterId;
  CancelToken? _activeCancelToken;
  Completer<void>? _activeDownloadFinished;

  FullSurahReciter get selectedReciter => fullSurahReciters.firstWhere(
    (r) => r.id == _selectedReciterId,
    orElse: () => fullSurahReciters.first,
  );

  final Map<int, SurahDownloadProgress> _progress = {};
  Map<int, SurahDownloadProgress> get progress => Map.unmodifiable(_progress);

  bool _bootstrapping = false;

  FullSurahDownloadProvider() {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedReciterId =
        prefs.getString(_prefKeyDefaultReciter) ?? fullSurahReciters.first.id;
    notifyListeners();
  }

  Future<void> cancelDownload() async {
    _cancelRequested = true;
    _activeCancelToken?.cancel('Download cancelled by user');
    notifyListeners();
  }

  Future<void> setDefaultReciter(String reciterId) async {
    _selectedReciterId = reciterId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyDefaultReciter, reciterId);
    notifyListeners();
  }

  /// Download any list of surahs for a reciter, with progress reporting.
  Future<void> _downloadSurahs(
    List<int> surahNumbers, {
    required String reciterId,
  }) async {
    if (_bootstrapping) return;
    _cancelRequested = false;
    _bootstrapping = true;
    _activeReciterId = reciterId;
    final finished = Completer<void>();
    _activeDownloadFinished = finished;

    final reciter = fullSurahReciters.firstWhere(
      (r) => r.id == reciterId,
      orElse: () => fullSurahReciters.first,
    );

    // Mark all as queued
    for (final s in surahNumbers) {
      _progress[s] = SurahDownloadProgress(
        surahNumber: s,
        status: SurahDlStatus.queued,
      );
    }
    notifyListeners();

    try {
      // Sequential downloads keep progress accurate and avoid excess requests.
      for (final s in surahNumbers) {
        if (_cancelRequested) break;

        try {
          final alreadyDownloaded = await _svc.isDownloaded(
            reciterId: reciterId,
            surahNumber: s,
          );
          if (_cancelRequested) break;
          if (alreadyDownloaded) {
            _progress[s] = _progress[s]!.copyWith(
              status: SurahDlStatus.done,
              progress: 1,
            );
            notifyListeners();
            continue;
          }

          _progress[s] = _progress[s]!.copyWith(
            status: SurahDlStatus.downloading,
            progress: 0,
          );
          notifyListeners();
          final cancelToken = CancelToken();
          _activeCancelToken = cancelToken;

          try {
            await _svc.downloadSurah(
              url: reciter.urlBuilder(s),
              reciterId: reciterId,
              surahNumber: s,
              cancelToken: cancelToken,
              onProgress: (recv, total) {
                if (total <= 0) return;
                _progress[s] = _progress[s]!.copyWith(
                  progress: (recv / total).clamp(0.0, 1.0),
                );
                notifyListeners();
              },
            );
          } catch (primaryErr) {
            if (_cancelRequested) rethrow;
            if (reciter.fallbackBuilder != null) {
              debugPrint('Primary download failed for surah $s ($primaryErr). Retrying with fallback CDN...');
              await _svc.downloadSurah(
                url: reciter.fallbackBuilder!(s),
                reciterId: reciterId,
                surahNumber: s,
                cancelToken: cancelToken,
                onProgress: (recv, total) {
                  if (total <= 0) return;
                  _progress[s] = _progress[s]!.copyWith(
                    progress: (recv / total).clamp(0.0, 1.0),
                  );
                  notifyListeners();
                },
              );
            } else {
              rethrow;
            }
          }

          _progress[s] = _progress[s]!.copyWith(
            status: SurahDlStatus.done,
            progress: 1,
          );
          notifyListeners();
        } catch (e) {
          debugPrint('Failed to download surah $s for $reciterId: $e');
          _progress[s] = _progress[s]!.copyWith(
            status: SurahDlStatus.failed,
            error: e.toString(),
          );
          notifyListeners();
        } finally {
          _activeCancelToken = null;
        }
      }
    } finally {
      _bootstrapping = false;
      _activeReciterId = null;
      _activeCancelToken = null;
      _activeDownloadFinished = null;
      _cancelRequested = false;
      notifyListeners();
      finished.complete();
    }
  }

  /// User-triggered download of any surah.
  Future<void> downloadSurah(int surahNumber, {String? reciterId}) async {
    await _downloadSurahs([
      surahNumber,
    ], reciterId: reciterId ?? _selectedReciterId);
  }

  Future<bool> isSurahDownloaded(int surahNumber, {String? reciterId}) =>
      _svc.isDownloaded(
        reciterId: reciterId ?? _selectedReciterId,
        surahNumber: surahNumber,
      );

  Future<String> resolveSurahPath(int surahNumber, {String? reciterId}) =>
      _svc.resolvePath(
        reciterId: reciterId ?? _selectedReciterId,
        surahNumber: surahNumber,
      );

  Future<List<int>> listDownloaded({String? reciterId}) =>
      _svc.listDownloadedSurahs(reciterId ?? _selectedReciterId);

  Future<void> deleteSurah(int surahNumber) async {
    await deleteSurahForReciter(surahNumber, reciterId: _selectedReciterId);
  }

  Future<void> deleteSurahForReciter(
    int surahNumber, {
    required String reciterId,
  }) async {
    await _svc.deleteSurah(reciterId: reciterId, surahNumber: surahNumber);
    _progress.remove(surahNumber);
    notifyListeners();
  }

  Future<void> deleteReciter(String reciterId) async {
    if (_activeReciterId == reciterId) {
      _cancelRequested = true;
      _activeCancelToken?.cancel('Reciter downloads deleted');
      await _activeDownloadFinished?.future;
    }

    await _svc.deleteReciter(reciterId);
    await AudioDownloadService().deleteReciter(reciterId);
    _progress.clear();
    notifyListeners();
  }

  Future<int> cacheSizeBytes([String? reciterId]) =>
      _svc.getCacheSizeBytes(reciterId ?? _selectedReciterId);
}
