import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/handler/supabase.dart';

class PublicHandler {
  
  // Get all public favorites from all users
  static Future<List<Map<String, dynamic>>> getPublicFavorites() async {
    try {
      final publicFavorites = await SupabaseHandler.getPublicFavorites();
      return publicFavorites ?? [];
    } catch (e) {
      return [];
    }
  }
  
  // Get public favorites by specific user ID (filtered from all public favorites)
  static Future<List<Map<String, dynamic>>> getPublicFavoritesByUser(String userId) async {
    try {
      final allPublicFavorites = await SupabaseHandler.getPublicFavorites();
      if (allPublicFavorites == null) return [];
      
      return allPublicFavorites.where((fav) => fav['user_id']?.toString() == userId).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get trending public favorites (most favorited animes) - simplified implementation
  static Future<List<Map<String, dynamic>>> getTrendingPublicFavorites({int limit = 20}) async {
    try {
      final allPublicFavorites = await SupabaseHandler.getPublicFavorites();
      if (allPublicFavorites == null) return [];
      
      // Group by anime_id and count occurrences
      final Map<String, Map<String, dynamic>> animeCount = {};
      for (var fav in allPublicFavorites) {
        final animeId = fav['anime_id']?.toString();
        if (animeId != null) {
          if (animeCount.containsKey(animeId)) {
            animeCount[animeId]!['count'] = (animeCount[animeId]!['count'] ?? 0) + 1;
          } else {
            animeCount[animeId] = {
              ...fav,
              'count': 1,
            };
          }
        }
      }
      
      // Sort by count and return top items
      final sortedList = animeCount.values.toList()
        ..sort((a, b) => (b['count'] ?? 0).compareTo(a['count'] ?? 0));
      
      return sortedList.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Search public favorites by username
  static Future<List<Map<String, dynamic>>> searchPublicFavorites(String query) async {
    try {
      if (query.trim().isEmpty) return [];
      
      final allPublicFavorites = await SupabaseHandler.getPublicFavorites();
      if (allPublicFavorites == null) return [];
      
      final lowerQuery = query.toLowerCase();
      return allPublicFavorites.where((fav) {
        final username = fav['username']?.toString().toLowerCase() ?? '';
        return username.contains(lowerQuery);
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Get public favorites count for specific anime
  static Future<int> getPublicFavoritesCount(String animeId) async {
    try {
      final allPublicFavorites = await SupabaseHandler.getPublicFavorites();
      if (allPublicFavorites == null) return 0;
      
      return allPublicFavorites.where((fav) => fav['anime_id']?.toString() == animeId).length;
    } catch (e) {
      return 0;
    }
  }
  
  // Get users who publicly favorited specific anime
  static Future<List<Map<String, dynamic>>> getUsersWhoFavorited(String animeId) async {
    try {
      final allPublicFavorites = await SupabaseHandler.getPublicFavorites();
      if (allPublicFavorites == null) return [];
      
      return allPublicFavorites.where((fav) => fav['anime_id']?.toString() == animeId).toList();
    } catch (e) {
      return [];
    }
  }
  
  // Make current user's favorite public (using updateData)
  static Future<bool> makePublic(String animeId) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      return await SupabaseHandler.updateData(
        table: 'favorites',
        data: {'is_public': true},
        filters: {
          'user_id': userData['id'].toString(),
          'anime_id': animeId,
        },
      );
    } catch (e) {
      return false;
    }
  }
  
  // Make current user's favorite private (using updateData)
  static Future<bool> makePrivate(String animeId) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      return await SupabaseHandler.updateData(
        table: 'favorites',
        data: {'is_public': false},
        filters: {
          'user_id': userData['id'].toString(),
          'anime_id': animeId,
        },
      );
    } catch (e) {
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
        orElse: () => <String, dynamic>{},
      );
      
      if (currentFavorite == null || currentFavorite.isEmpty) return false;
      
      final isCurrentlyPublic = currentFavorite['is_public'] ?? false;
      
      return await SupabaseHandler.updateData(
        table: 'favorites',
        data: {'is_public': !isCurrentlyPublic},
        filters: {
          'user_id': userData['id'].toString(),
          'anime_id': animeId,
        },
      );
    } catch (e) {
      return false;
    }
  }
  
  // Get public favorites with user info (simplified - just return public favorites)
  static Future<List<Map<String, dynamic>>> getPublicFavoritesWithUserInfo() async {
    try {
      return await getPublicFavorites();
    } catch (e) {
      return [];
    }
  }
  
  // Get recently added public favorites
  static Future<List<Map<String, dynamic>>> getRecentPublicFavorites({int limit = 10}) async {
    try {
      final allPublicFavorites = await SupabaseHandler.getPublicFavorites();
      if (allPublicFavorites == null) return [];
      
      // Sort by added_at if available, otherwise return first items
      final sortedFavorites = List<Map<String, dynamic>>.from(allPublicFavorites);
      sortedFavorites.sort((a, b) {
        final aTime = DateTime.tryParse(a['added_at']?.toString() ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['added_at']?.toString() ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      return sortedFavorites.take(limit).toList();
    } catch (e) {
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
        orElse: () => <String, dynamic>{},
      );
      
      return favorite != null && favorite.isNotEmpty && (favorite['is_public'] ?? false);
    } catch (e) {
      return false;
    }
  }
  
  // Get public favorites statistics (simplified)
  static Future<Map<String, dynamic>> getPublicFavoritesStats() async {
    try {
      final allPublicFavorites = await SupabaseHandler.getPublicFavorites();
      if (allPublicFavorites == null) {
        return {
          'total_public_favorites': 0,
          'total_users_with_public': 0,
          'most_favorited_anime': null,
        };
      }
      
      final uniqueUsers = <String>{};
      final animeCount = <String, int>{};
      
      for (var fav in allPublicFavorites) {
        final userId = fav['user_id']?.toString();
        final animeId = fav['anime_id']?.toString();
        
        if (userId != null) uniqueUsers.add(userId);
        if (animeId != null) {
          animeCount[animeId] = (animeCount[animeId] ?? 0) + 1;
        }
      }
      
      String? mostFavoritedAnime;
      int maxCount = 0;
      animeCount.forEach((animeId, count) {
        if (count > maxCount) {
          maxCount = count;
          mostFavoritedAnime = animeId;
        }
      });
      
      return {
        'total_public_favorites': allPublicFavorites.length,
        'total_users_with_public': uniqueUsers.length,
        'most_favorited_anime': mostFavoritedAnime,
      };
    } catch (e) {
      return {
        'total_public_favorites': 0,
        'total_users_with_public': 0,
        'most_favorited_anime': null,
      };
    }
  }
}
