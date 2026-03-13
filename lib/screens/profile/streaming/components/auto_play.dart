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
    required Map<int, List<int>> seasons, // season -> list of episodes
  }) {
    final currentSeasonEpisodes = seasons[currentSeason] ?? [];
    
    // Check if there's next episode in current season
    if (currentSeasonEpisodes.contains(currentEpisode + 1)) {
      return true;
    }
    
    // Check if there's next season
    final nextSeason = currentSeason + 1;
    if (seasons.containsKey(nextSeason) && (seasons[nextSeason]?.isNotEmpty ?? false)) {
      return true;
    }
    
    return false;
  }
  
  /// Get next episode details
  static Map<String, int>? getNextEpisode({
    required int currentSeason,
    required int currentEpisode,
    required Map<int, List<int>> seasons,
  }) {
    final currentSeasonEpisodes = seasons[currentSeason] ?? [];
    
    // Try next episode in current season
    if (currentSeasonEpisodes.contains(currentEpisode + 1)) {
      return {'season': currentSeason, 'episode': currentEpisode + 1};
    }
    
    // Try first episode of next season
    final nextSeason = currentSeason + 1;
    if (seasons.containsKey(nextSeason)) {
      final nextSeasonEpisodes = seasons[nextSeason] ?? [];
      if (nextSeasonEpisodes.isNotEmpty) {
        return {'season': nextSeason, 'episode': nextSeasonEpisodes.first};
      }
    }
    
    return null;
  }
}
