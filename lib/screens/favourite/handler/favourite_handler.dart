import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/handler/supabase.dart';

class FavouriteHandler {
  static RealtimeChannel? _favoritesSubscription;
  
  // Get current user's favorites with real-time updates
  static Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return [];
      
      final userData = await _getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return [];
      
      final favorites = await SupabaseHandler.getData(
        table: 'favorites',
        filters: {'user_id': userData['id']},
        orderBy: 'created_at',
        ascending: false,
      );
      
      return favorites ?? [];
    } catch (e) {
      print('Get user favorites error: $e');
      return [];
    }
  }
  
  // Subscribe to real-time favorites updates
  static RealtimeChannel subscribeToFavorites({
    required Function(List<Map<String, dynamic>>) onUpdate,
  }) {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) throw Exception('User not authenticated');
    
    _favoritesSubscription?.unsubscribe();
    
    _favoritesSubscription = SupabaseHandler.subscribeToTable(
      table: 'favorites',
      onData: (payload) async {
        // Refresh favorites when any change occurs
        final favorites = await getUserFavorites();
        onUpdate(favorites);
      },
    );
    
    return _favoritesSubscription!;
  }
  
  // Add anime to favorites
  static Future<bool> addToFavorites({
    required String animeId,
    required String animeTitle,
    String? animeImage,
    bool isPublic = false,
  }) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await _getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      final result = await SupabaseHandler.insertData(
        table: 'favorites',
        data: {
          'user_id': userData['id'],
          'anime_id': animeId,
          'anime_title': animeTitle,
          'anime_image': animeImage,
          'is_public': isPublic,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      return result != null;
    } catch (e) {
      print('Add to favorites error: $e');
      return false;
    }
  }
  
  // Remove from favorites
  static Future<bool> removeFromFavorites({
    required String animeId,
  }) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await _getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      final result = await SupabaseHandler.deleteData(
        table: 'favorites',
        filters: {
          'user_id': userData['id'],
          'anime_id': animeId,
        },
      );
      
      return result;
    } catch (e) {
      print('Remove from favorites error: $e');
      return false;
    }
  }
  
  // Check if anime is in favorites
  static Future<bool> isInFavorites({
    required String animeId,
  }) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await _getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      final result = await SupabaseHandler.getData(
        table: 'favorites',
        filters: {
          'user_id': userData['id'],
          'anime_id': animeId,
        },
        limit: 1,
      );
      
      return result != null && result.isNotEmpty;
    } catch (e) {
      print('Check favorites error: $e');
      return false;
    }
  }
  
  // Toggle favorite status
  static Future<bool> toggleFavorite({
    required String animeId,
    required String animeTitle,
    String? animeImage,
    bool isPublic = false,
  }) async {
    final isCurrentlyFavorite = await isInFavorites(animeId: animeId);
    
    if (isCurrentlyFavorite) {
      return await removeFromFavorites(animeId: animeId);
    } else {
      return await addToFavorites(
        animeId: animeId,
        animeTitle: animeTitle,
        animeImage: animeImage,
        isPublic: isPublic,
      );
    }
  }
  
  // Get public favorites
  static Future<List<Map<String, dynamic>>> getPublicFavorites({
    int limit = 50,
  }) async {
    try {
      final favorites = await SupabaseHandler.getData(
        table: 'favorites',
        filters: {'is_public': true},
        orderBy: 'created_at',
        ascending: false,
        limit: limit,
      );
      
      return favorites ?? [];
    } catch (e) {
      print('Get public favorites error: $e');
      return [];
    }
  }
  
  // Helper method to get user by Firebase UID
  static Future<Map<String, dynamic>?> _getUserByFirebaseUID(String firebaseUID) async {
    try {
      final result = await SupabaseHandler.getData(
        table: 'users',
        filters: {'firebase_uid': firebaseUID},
        limit: 1,
      );
      
      return result != null && result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Get user by Firebase UID error: $e');
      return null;
    }
  }
  
  // Cleanup subscriptions
  static void dispose() {
    _favoritesSubscription?.unsubscribe();
    _favoritesSubscription = null;
  }
}
