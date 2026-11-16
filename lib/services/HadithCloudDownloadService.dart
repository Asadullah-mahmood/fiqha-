import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class HadithCloudDownloadService {
  HadithCloudDownloadService._();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Dio _dio = Dio();

  /// Check if the database file exists locally by book name (e.g., 'sahih-bukhari')
  static Future<bool> isBookDownloaded(String bookName) async {
    final dir = await getDatabasesPath();
    final path = join(dir, '$bookName.db');
    return await File(path).exists();
  }

  /// Get download URL from Firestore collection `db_files` where `name` == bookName
  static Future<String?> fetchDownloadUrl(String bookName) async {
    try {
      final querySnapshot = await _firestore
          .collection('db_files')
          .where('name', isEqualTo: bookName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['url'] as String?;
      }
    } catch (e) {
      print('Error fetching download URL for $bookName: $e');
    }
    return null;
  }

  /// Download a book database on demand with progress reporting
  static Future<void> downloadBook({
    required String bookName,
    required void Function(int received, int total, double percentage) onProgress,
  }) async {
    // 1. Check local storage first
    if (await isBookDownloaded(bookName)) {
      onProgress(100, 100, 100.0);
      return;
    }

    // 2. Fetch URL from Firestore
    final url = await fetchDownloadUrl(bookName);
    if (url == null || url.isEmpty) {
      throw Exception('Download URL not found in Firestore for $bookName');
    }

    final dir = await getDatabasesPath();
    await Directory(dir).create(recursive: true);
    final path = join(dir, '$bookName.db');
    final tmpPath = '$path.tmp';

    // 3. Download via Dio with progress callbacks
    await _dio.download(
      url,
      tmpPath,
      onReceiveProgress: (received, total) {
        if (total > 0) {
          final percentage = (received / total) * 100;
          onProgress(received, total, percentage);
        } else {
          onProgress(received, total, 0.0);
        }
      },
      options: Options(
        receiveTimeout: const Duration(minutes: 10),
        sendTimeout: const Duration(minutes: 2),
      ),
    );

    final tmpFile = File(tmpPath);
    if (await tmpFile.exists() && await tmpFile.length() > 1024) {
      if (await File(path).exists()) {
        await File(path).delete();
      }
      await tmpFile.rename(path);
    } else {
      if (await tmpFile.exists()) await tmpFile.delete();
      throw Exception('Downloaded database file for $bookName is invalid.');
    }
  }

  /// Preload default books ("sahih-bukhari" and "sahih-al-muslim") on first screen open
  static Future<void> downloadAllSixBooksSequentially({
    required void Function(String bookName, double percentage) onBookProgress,
    required void Function(String bookName) onBookCompleted,
  }) async {
    const books = [
      'sahih-bukhari',
      'sahih-muslim',
      'sunan-abu-dawud',
      'jami-at-tirmidhi',
      'sunan-an-nasai',
      'sunan-ibn-majah',
    ];

    for (final bookName in books) {
      if (!await isBookDownloaded(bookName)) {
        try {
          await downloadBook(
            bookName: bookName,
            onProgress: (received, total, percentage) {
              onBookProgress(bookName, percentage);
            },
          );
          onBookCompleted(bookName);
        } catch (e) {
          print('Failed to download $bookName sequentially: $e');
        }
      } else {
        onBookCompleted(bookName);
      }
    }
  }
}
