import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/handler/supabase.dart';

class PublicHandler {
  
  // Get all public favorites from all users
  static Future<List<Map<String, dynamic>>> getPublicFavorites() async {
    try {
      final publicFavorites = await SupabaseHandler.getPublicFavorites();
      return publicFavorites ?? [];
    } catch (e) {
      print('Get public favorites error: $e');
      return [];
    }
  }
  
  // Get public favorites by specific user ID
  static Future<List<Map<String, dynamic>>> getPublicFavoritesByUser(String userId) async {
    try {
      final userPublicFavorites = await SupabaseHandler.getPublicFavoritesByUser(userId);
      return userPublicFavorites ?? [];
    } catch (e) {
      print('Get user public favorites error: $e');
      return [];
    }
  }
  
  // Get trending public favorites (most favorited animes)
  static Future<List<Map<String, dynamic>>> getTrendingPublicFavorites({int limit = 20}) async {
    try {
      final trendingFavorites = await SupabaseHandler.getTrendingPublicFavorites(limit: limit);
      return trendingFavorites ?? [];
    } catch (e) {
      print('Get trending public favorites error: $e');
      return [];
    }
  }
  
  // Search public favorites by anime title
  static Future<List<Map<String, dynamic>>> searchPublicFavorites(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final searchResults = await SupabaseHandler.searchPublicFavorites(query);
      return searchResults ?? [];
    } catch (e) {
      print('Search public favorites error: $e');
      return [];
    }
  }
  
  // Get public favorites count for specific anime
  static Future<int> getPublicFavoritesCount(String animeId) async {
    try {
      final count = await SupabaseHandler.getPublicFavoritesCount(animeId);
      return count ?? 0;
    } catch (e) {
      print('Get public favorites count error: $e');
      return 0;
    }
  }
  
  // Get users who publicly favorited specific anime
  static Future<List<Map<String, dynamic>>> getUsersWhoFavorited(String animeId) async {
    try {
      final users = await SupabaseHandler.getUsersWhoFavorited(animeId);
      return users ?? [];
    } catch (e) {
      print('Get users who favorited error: $e');
      return [];
    }
  }
  
  // Make current user's favorite public
  static Future<bool> makePublic(String animeId) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      return await SupabaseHandler.updateFavoriteVisibility(
        userId: userData['id'].toString(),
        animeId: animeId,
        isPublic: true,
      );
    } catch (e) {
      print('Make public error: $e');
      return false;
    }
  }
  
  // Make current user's favorite private
  static Future<bool> makePrivate(String animeId) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      return await SupabaseHandler.updateFavoriteVisibility(
        userId: userData['id'].toString(),
        animeId: animeId,
        isPublic: false,
      );
    } catch (e) {
      print('Make private error: $e');
      return false;
    }
  }
  
  // Toggle favorite visibility (public/private)
  static Future<bool> toggleVisibility(String animeId) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      // Get current favorite to check visibility
      final favorites = await SupabaseHandler.getUserFavorites(userData['id'].toString());
      final currentFavorite = favorites?.firstWhere(
        (fav) => fav['anime_id'] == animeId,
        orElse: () => null,
      );
      
      if (currentFavorite == null) return false;
      
      final isCurrentlyPublic = currentFavorite['is_public'] ?? false;
      
      return await SupabaseHandler.updateFavoriteVisibility(
        userId: userData['id'].toString(),
        animeId: animeId,
        isPublic: !isCurrentlyPublic,
      );
    } catch (e) {
      print('Toggle visibility error: $e');
      return false;
    }
  }
  
  // Get public favorites with user info (username, avatar)
  static Future<List<Map<String, dynamic>>> getPublicFavoritesWithUserInfo() async {
    try {
      final publicFavoritesWithUsers = await SupabaseHandler.getPublicFavoritesWithUserInfo();
      return publicFavoritesWithUsers ?? [];
    } catch (e) {
      print('Get public favorites with user info error: $e');
      return [];
    }
  }
  
  // Get recently added public favorites
  static Future<List<Map<String, dynamic>>> getRecentPublicFavorites({int limit = 10}) async {
    try {
      final recentFavorites = await SupabaseHandler.getRecentPublicFavorites(limit: limit);
      return recentFavorites ?? [];
    } catch (e) {
      print('Get recent public favorites error: $e');
      return [];
    }
  }
  
  // Check if current user has anime in public favorites
  static Future<bool> isPubliclyFavorited(String animeId) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      final favorites = await SupabaseHandler.getUserFavorites(userData['id'].toString());
      final favorite = favorites?.firstWhere(
        (fav) => fav['anime_id'] == animeId,
        orElse: () => null,
      );
      
      return favorite != null && (favorite['is_public'] ?? false);
    } catch (e) {
      print('Check public favorite error: $e');
      return false;
    }
  }
  
  // Get public favorites statistics
  static Future<Map<String, dynamic>> getPublicFavoritesStats() async {
    try {
      final stats = await SupabaseHandler.getPublicFavoritesStats();
      return stats ?? {
        'total_public_favorites': 0,
        'total_users_with_public': 0,
        'most_favorited_anime': null,
      };
    } catch (e) {
      print('Get public favorites stats error: $e');
      return {
        'total_public_favorites': 0,
        'total_users_with_public': 0,
        'most_favorited_anime': null,
      };
    }
  }
}
