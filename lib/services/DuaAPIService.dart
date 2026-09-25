import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/DuaModel.dart';

class DuaApiService {
  static final DuaApiService _instance = DuaApiService._();
  factory DuaApiService() => _instance;
  DuaApiService._();

  static const String _baseUrl = 'https://ummahapi.com/api/duas/random';
  static const String _cacheKeyDua = 'cached_random_dua';
  static const String _cacheKeyDate = 'cached_random_dua_date';

  /// Get a random dua, cached for 24 hours.
  /// Returns cached dua if it's the same calendar day; otherwise fetches fresh.
  Future<DuaApiModel?> getRandomDua({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();

    if (!forceRefresh) {
      final cachedDate = prefs.getString(_cacheKeyDate);
      final cachedJson = prefs.getString(_cacheKeyDua);
      if (cachedDate == today && cachedJson != null) {
        try {
          return DuaApiModel.fromJson(jsonDecode(cachedJson));
        } catch (_) {
          // fall through to network
        }
      }
    }

    // Fetch fresh
    try {
      final resp = await http
          .get(Uri.parse(_baseUrl))
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final dua = DuaApiModel.fromJson(data);
        await prefs.setString(_cacheKeyDua, jsonEncode(data));
        await prefs.setString(_cacheKeyDate, today);
        return dua;
      }
    } catch (_) {}

    // Fallback: return stale cache if available
    final cachedJson = prefs.getString(_cacheKeyDua);
    if (cachedJson != null) {
      try {
        return DuaApiModel.fromJson(jsonDecode(cachedJson));
      } catch (_) {}
    }
    return null;
  }

  /// Optional: force a new dua (pull-to-refresh).
  Future<DuaApiModel?> refresh() => getRandomDua(forceRefresh: true);

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }
}