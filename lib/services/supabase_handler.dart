import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHandler {
  static final _client = Supabase.instance.client;
  
  // Check if user is logged in
  static bool isUserLoggedIn() {
    return _client.auth.currentUser != null;
  }
  
  // Get current user ID
  static String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }
  
  // Check if anime is in favorites
  static Future<bool> isAnimeFavorited(String animeId) async {
    try {
      if (!isUserLoggedIn()) return false;
      
      final userId = getCurrentUserId();
      if (userId == null) return false;
      
      final response = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('anime_id', animeId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('❌ Error checking favorite status: $e');
      return false;
    }
  }
  
  // Add anime to favorites
  static Future<bool> addToFavorites({
    required String animeId,
    required String animeTitle,
    required String animePoster,
    required String animeType,
  }) async {
    try {
      if (!isUserLoggedIn()) return false;
      
      final userId = getCurrentUserId();
      if (userId == null) return false;
      
      await _client.from('favorites').insert({
        'user_id': userId,
        'anime_id': animeId,
        'anime_title': animeTitle,
        'anime_poster': animePoster,
        'anime_type': animeType,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Added to favorites: $animeTitle');
      return true;
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      return false;
    }
  }
  
  // Remove anime from favorites
  static Future<bool> removeFromFavorites(String animeId) async {
    try {
      if (!isUserLoggedIn()) return false;
      
      final userId = getCurrentUserId();
      if (userId == null) return false;
      
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('anime_id', animeId);
      
      print('✅ Removed from favorites: $animeId');
      return true;
    } catch (e) {
      print('❌ Error removing from favorites: $e');
      return false;
    }
  }
  
  // Get user's favorite animes
  static Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      if (!isUserLoggedIn()) return [];
      
      final userId = getCurrentUserId();
      if (userId == null) return [];
      
      final response = await _client
          .from('favorites')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching favorites: $e');
      return [];
    }
  }
}
