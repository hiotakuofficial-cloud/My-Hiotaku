import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LanguagePreference {
  static const String _key = 'preferred_language';
  static const String _historyKey = 'language_history';
  
  /// Save user's preferred language and update history
  static Future<void> savePreference(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language);
    
    // Update language history (most recent first)
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = json.decode(historyJson);
    
    // Remove if already exists, then add to front
    history.remove(language);
    history.insert(0, language);
    
    // Keep only last 3 languages
    if (history.length > 3) {
      history.removeRange(3, history.length);
    }
    
    await prefs.setString(_historyKey, json.encode(history));
  }
  
  /// Get saved language preference
  static Future<String?> getPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
  
  /// Get language history (most recent first)
  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey) ?? '[]';
    final List<dynamic> history = json.decode(historyJson);
    return history.cast<String>();
  }
  
  /// Select best language based on preference and availability
  /// Priority: Last used > History (Hindi/Eng/Jap) > English > Original
  static String selectLanguage({
    required List<Map<String, dynamic>> availableLanguages,
    String? savedPreference,
  }) {
    if (availableLanguages.isEmpty) return 'Original';
    
    // Extract language names
    final langNames = availableLanguages
        .map((lang) => lang['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    
    if (langNames.isEmpty) return 'Original';
    
    // 1. Check saved preference (last used)
    if (savedPreference != null && langNames.contains(savedPreference)) {
      return savedPreference;
    }
    
    // 2. Check history (user's frequently used languages)
    // This will be checked in detail page and play.dart
    
    // 3. Fallback to first available
    return langNames.first;
  }
  
  /// Select language with history priority
  static Future<String> selectLanguageWithHistory({
    required List<Map<String, dynamic>> availableLanguages,
  }) async {
    if (availableLanguages.isEmpty) return 'Original';
    
    final langNames = availableLanguages
        .map((lang) => lang['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    
    if (langNames.isEmpty) return 'Original';
    
    // 1. Check last used
    final lastUsed = await getPreference();
    if (lastUsed != null && langNames.contains(lastUsed)) {
      return lastUsed;
    }
    
    // 2. Check history (Hindi > Eng > Jap order based on user usage)
    final history = await getHistory();
    for (final lang in history) {
      if (langNames.contains(lang)) {
        return lang;
      }
    }
    
    // 3. Fallback: English > Original > First available
    if (langNames.contains('English')) return 'English';
    if (langNames.contains('Original')) return 'Original';
    
    return langNames.first;
  }
}
