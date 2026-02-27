import '../screens/auth/handler/supabase.dart';

class SystemSettingsService {
  static Future<Map<String, bool>> getSettings() async {
    try {
      final data = await SupabaseHandler.getData(table: 'system_settings');
      
      if (data != null && data.isNotEmpty) {
        final settings = data[0];
        return {
          'is_chat_enabled': settings['is_chat_enabled'] ?? true,
          'is_download_enabled': settings['is_download_enabled'] ?? true,
        };
      }
      
      return {
        'is_chat_enabled': true,
        'is_download_enabled': true,
      };
    } catch (e) {
      return {
        'is_chat_enabled': true,
        'is_download_enabled': true,
      };
    }
  }
}
