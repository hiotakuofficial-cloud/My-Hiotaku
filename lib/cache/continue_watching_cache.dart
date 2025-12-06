import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ContinueWatchingCache {
  static const String _key = 'continue_watching_list';
  
  // Save anime to continue watching
  static Future<void> saveProgress({
    required String animeId,
    required String title,
    required String image,
    required String episode,
    required int progressSeconds,
    required int totalSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing list
    List<Map<String, dynamic>> continueList = await getContinueWatching();
    
    // Remove existing entry for same anime
    continueList.removeWhere((item) => item['animeId'] == animeId);
    
    // Add new entry at beginning
    continueList.insert(0, {
      'animeId': animeId,
      'title': title,
      'image': image,
      'episode': episode,
      'progressSeconds': progressSeconds,
      'totalSeconds': totalSeconds,
      'progressPercent': (progressSeconds / totalSeconds * 100).round(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    // Keep only last 20 items
    if (continueList.length > 20) {
      continueList = continueList.take(20).toList();
    }
    
    // Save to preferences
    await prefs.setString(_key, json.encode(continueList));
  }
  
  // Get continue watching list
  static Future<List<Map<String, dynamic>>> getContinueWatching() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    
    if (data != null) {
      return List<Map<String, dynamic>>.from(json.decode(data));
    }
    
    return [];
  }
  
  // Remove item from continue watching
  static Future<void> removeItem(String animeId) async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> continueList = await getContinueWatching();
    
    continueList.removeWhere((item) => item['animeId'] == animeId);
    await prefs.setString(_key, json.encode(continueList));
  }
  
  // Clear all continue watching
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
