import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoPlay {
  static const String _key = 'auto_play_enabled';
  
  /// Save auto-play preference
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
  
  /// Get auto-play preference (default: true)
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }
  
  /// Check if next episode exists and should auto-play
  static bool hasNextEpisode({
    required int currentSeason,
    required int currentEpisode,
    required List<Map<String, dynamic>> seasons,
  }) {
    // Find current season data
    final currentSeasonData = seasons.firstWhere(
      (s) => s['season'] == currentSeason,
      orElse: () => {},
    );
    
    if (currentSeasonData.isEmpty) return false;
    
    final episodes = currentSeasonData['episodes'] as List? ?? [];
    
    // Check if there's next episode in current season
    if (episodes.any((ep) => ep['episode'] == currentEpisode + 1)) {
      return true;
    }
    
    // Check if there's next season
    return seasons.any((s) => s['season'] == currentSeason + 1);
  }
  
  /// Get next episode details
  static Map<String, int>? getNextEpisode({
    required int currentSeason,
    required int currentEpisode,
    required List<Map<String, dynamic>> seasons,
  }) {
    // Find current season data
    final currentSeasonData = seasons.firstWhere(
      (s) => s['season'] == currentSeason,
      orElse: () => {},
    );
    
    if (currentSeasonData.isNotEmpty) {
      final episodes = currentSeasonData['episodes'] as List? ?? [];
      
      // Try next episode in current season
      if (episodes.any((ep) => ep['episode'] == currentEpisode + 1)) {
        return {'season': currentSeason, 'episode': currentEpisode + 1};
      }
    }
    
    // Try first episode of next season
    final nextSeasonData = seasons.firstWhere(
      (s) => s['season'] == currentSeason + 1,
      orElse: () => {},
    );
    
    if (nextSeasonData.isNotEmpty) {
      final episodes = nextSeasonData['episodes'] as List? ?? [];
      if (episodes.isNotEmpty) {
        final firstEp = episodes.first['episode'] as int? ?? 1;
        return {'season': currentSeason + 1, 'episode': firstEp};
      }
    }
    
    return null;
  }
}
