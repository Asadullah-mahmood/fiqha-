import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quranpak/models/LastReadProgress.dart';
import 'package:quranpak/models/models.dart';

import '../services/LastReadCloudService.dart';
import '../services/LastReadLocalService.dart';

class LastReadProvider extends ChangeNotifier {
  static const String _localUserId = 'local';

  final LastReadLocalService _local = LastReadLocalService();
  final LastReadCloudService _cloud = LastReadCloudService();

  LastReadProgress? _progress;
  String? _userId;
  int _revision = 0;
  int _lastTimestamp = 0;
  Future<void> _cloudWriteQueue = Future<void>.value();

  LastReadProgress? get progress => _progress;

  Future<void> bindUser(String? userId) async {
    if (_userId != userId) {
      _progress = null;
      notifyListeners();
    }
    _userId = userId;
    final revisionAtStart = _revision;
    final localKey = userId ?? _localUserId;

    try {
      final localProgress = await _local.getForUser(localKey);
      if (_revision != revisionAtStart || _userId != userId) return;
      _progress = localProgress;
      if (localProgress != null) {
        _lastTimestamp = localProgress.updatedAt.millisecondsSinceEpoch;
      }
      notifyListeners();
    } catch (error, stackTrace) {
      debugPrint('Failed to load local last-read progress: $error\n$stackTrace');
    }

    if (userId == null) return;

    try {
      final cloudProgress = await _cloud.fetch(userId);
      if (_revision != revisionAtStart || _userId != userId) return;

      var shouldPushLocal = false;
      if (cloudProgress != null &&
          (_progress == null ||
              cloudProgress.updatedAt.isAfter(_progress!.updatedAt))) {
        _progress = cloudProgress;
        _lastTimestamp =
            cloudProgress.updatedAt.millisecondsSinceEpoch;
        notifyListeners();
        try {
          await _local.save(userId, cloudProgress);
          await _local.markSynced(
            userId,
            cloudProgress.updatedAt.millisecondsSinceEpoch,
          );
        } catch (error, stackTrace) {
          debugPrint('Failed to cache cloud last-read progress locally: '
              '$error\n$stackTrace');
        }
      } else if (_progress != null) {
        shouldPushLocal = true;
      }

      if (shouldPushLocal && _progress != null) {
        unawaited(_pushToCloud(userId, _progress!));
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to sync last-read progress from cloud: '
          '$error\n$stackTrace');
      if (_userId == userId && _progress != null) {
        unawaited(_pushToCloud(userId, _progress!));
      }
    }
  }

  void recordAyah(
    Ayah ayah, {
    required String readerType,
    required int readerSectionNumber,
  }) {
    final previous = _progress;
    final progress = LastReadProgress(
      surahNumber: ayah.surahNumber,
      ayahNumber: ayah.numberInSurah,
      juzNumber: ayah.juz,
      surahName: ayah.surahName ?? '',
      surahEnglishName: ayah.surahEnglishName ?? '',
      readerType: readerType,
      readerSectionNumber: readerSectionNumber,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        _nextTimestamp(),
        isUtc: true,
      ),
    );

    if (previous != null && progress.sameLocationAs(previous)) return;

    _revision++;
    _progress = progress;
    notifyListeners();
    unawaited(_saveProgress(_userId ?? _localUserId, _userId, progress));
  }

  int _nextTimestamp() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastTimestamp = now > _lastTimestamp ? now : _lastTimestamp + 1;
    return _lastTimestamp;
  }

  Future<void> _saveProgress(
    String localKey,
    String? cloudUserId,
    LastReadProgress progress,
  ) async {
    try {
      await _local.save(localKey, progress);
    } catch (error, stackTrace) {
      debugPrint('Failed to save local last-read progress: '
          '$error\n$stackTrace');
    }

    if (cloudUserId != null) {
      await _pushToCloud(cloudUserId, progress);
    }
  }

  Future<void> _pushToCloud(
    String userId,
    LastReadProgress progress,
  ) async {
    _cloudWriteQueue = _cloudWriteQueue.then((_) async {
      try {
        await _cloud.save(userId, progress);
      } catch (error, stackTrace) {
        debugPrint('Failed to sync last-read progress for $userId: '
            '$error\n$stackTrace');
        return;
      }

      try {
        await _local.markSynced(
          userId,
          progress.updatedAt.millisecondsSinceEpoch,
        );
      } catch (error, stackTrace) {
        debugPrint('Cloud saved last-read progress but local sync state '
            'could not be updated for $userId: '
            '$error\n$stackTrace');
      }
    });
    await _cloudWriteQueue;
  }
}
