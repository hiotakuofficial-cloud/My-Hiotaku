import 'package:shared_preferences/shared_preferences.dart';

class AudioHandler {
  static const String _preferredLanguageKey = 'preferred_audio_language';

  /// Save user's preferred audio language
  static Future<void> savePreferredLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferredLanguageKey, language);
  }

  /// Get user's preferred audio language
  static Future<String?> getPreferredLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_preferredLanguageKey);
  }

  /// Check if episode has ended (within last 30 seconds)
  static bool hasEpisodeEnded(Duration position, Duration duration) {
    if (duration.inSeconds == 0) return false;
    final remaining = duration.inSeconds - position.inSeconds;
    return remaining <= 30 && remaining >= 0;
  }
}
