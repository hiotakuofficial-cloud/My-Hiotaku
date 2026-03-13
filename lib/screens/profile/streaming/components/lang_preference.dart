import 'package:shared_preferences/shared_preferences.dart';

class LanguagePreference {
  static const String _key = 'preferred_language';
  
  /// Save user's preferred language
  static Future<void> savePreference(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, language);
  }
  
  /// Get saved language preference
  static Future<String?> getPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }
  
  /// Select best language based on preference and availability
  /// Priority: Saved preference > Hindi > English > Original
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
    
    // 1. Check saved preference
    if (savedPreference != null && langNames.contains(savedPreference)) {
      return savedPreference;
    }
    
    // 2. Priority list
    const priorities = ['Hindi', 'English', 'Original'];
    
    for (final priority in priorities) {
      if (langNames.contains(priority)) {
        return priority;
      }
    }
    
    // 3. Fallback to first available
    return langNames.first;
  }
}
