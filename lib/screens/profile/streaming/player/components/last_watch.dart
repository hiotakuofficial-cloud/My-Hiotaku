import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LastWatchHandler {
  static const String _keyPrefix = 'last_watch_';
  
  // Save watch position (called every 10 seconds)
  static Future<void> savePosition({
    required String subjectId,
    required int season,
    required int episode,
    required int positionSeconds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(subjectId, season, episode);
      
      final data = {
        'subjectId': subjectId,
        'season': season,
        'episode': episode,
        'position': positionSeconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(key, jsonEncode(data));
    } catch (e) {
      // Silent fail
    }
  }
  
  // Get last watch position
  static Future<int?> getPosition({
    required String subjectId,
    required int season,
    required int episode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(subjectId, season, episode);
      final dataStr = prefs.getString(key);
      
      if (dataStr == null) return null;
      
      final data = jsonDecode(dataStr);
      return data['position'] as int?;
    } catch (e) {
      return null;
    }
  }
  
  // Clear position (when episode completed)
  static Future<void> clearPosition({
    required String subjectId,
    required int season,
    required int episode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _buildKey(subjectId, season, episode);
      await prefs.remove(key);
    } catch (e) {
      // Silent fail
    }
  }
  
  // Build cache key
  static String _buildKey(String subjectId, int season, int episode) {
    return '$_keyPrefix${subjectId}_s${season}_e$episode';
  }
}
