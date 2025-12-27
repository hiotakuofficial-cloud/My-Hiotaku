import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/handler/supabase.dart';
import '../../../database/query_optimizer.dart';

class FavouriteHandler {
  
  // Get current user's favorites with pagination
  static Future<Map<String, dynamic>> getUserFavoritesPaginated({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return {'data': [], 'hasMore': false};
      
      final userData = await QueryOptimizer.getUserOptimized(firebaseUser.uid);
      if (userData == null) return {'data': [], 'hasMore': false};
      
      return await QueryOptimizer.getUserFavoritesPaginated(
        userId: userData['id'].toString(),
        page: page,
        limit: limit,
      );
    } catch (e) {
      return {'data': [], 'hasMore': false};
    }
  }
  
  // Get current user's favorites (legacy method)
  static Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final result = await getUserFavoritesPaginated(page: 1, limit: 100);
      return List<Map<String, dynamic>>.from(result['data']);
    } catch (e) {
      return [];
    }
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
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      final result = await SupabaseHandler.addToFavorites(
        userId: userData['id'].toString(),
        animeId: animeId,
        animeTitle: animeTitle,
        animeImage: animeImage,
        isPublic: isPublic,
      );
      
      return result != null;
    } catch (e) {
      return false;
    }
  }
  
  // Remove anime from favorites
  static Future<bool> removeFromFavorites(String animeId) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      return await SupabaseHandler.removeFromFavorites(
        userId: userData['id'].toString(),
        animeId: animeId,
      );
    } catch (e) {
      return false;
    }
  }
  
  // Check if anime is in favorites
  static Future<bool> isInFavorites(String animeId) async {
    try {
      final favorites = await getUserFavorites();
      return favorites.any((fav) => fav['anime_id'] == animeId);
    } catch (e) {
      return false;
    }
  }
  
  // Get public favorites from all users with pagination
  static Future<Map<String, dynamic>> getPublicFavoritesPaginated({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      return await QueryOptimizer.getPublicFavoritesPaginated(
        page: page,
        limit: limit,
      );
    } catch (e) {
      return {'data': [], 'hasMore': false};
    }
  }
  
  // Get public favorites from all users (legacy method)
  static Future<List<Map<String, dynamic>>> getPublicFavorites() async {
    try {
      final result = await getPublicFavoritesPaginated(page: 1, limit: 100);
      return List<Map<String, dynamic>>.from(result['data']);
    } catch (e) {
      return [];
    }
  }
  
  // Send merge request to another user
  static Future<bool> sendMergeRequest({
    required String receiverUserId,
    String? message,
  }) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      final result = await SupabaseHandler.sendMergeRequest(
        senderId: userData['id'].toString(),
        receiverId: receiverUserId,
        message: message,
      );
      
      return result != null;
    } catch (e) {
      return false;
    }
  }
  
  // Get pending merge requests for current user
  static Future<List<Map<String, dynamic>>> getPendingMergeRequests() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return [];
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return [];
      
      final requests = await SupabaseHandler.getPendingMergeRequests(userData['id'].toString());
      return requests ?? [];
    } catch (e) {
      return [];
    }
  }
  
  // Accept merge request
  static Future<bool> acceptMergeRequest(String requestId) async {
    try {
      return await SupabaseHandler.respondToMergeRequest(
        requestId: requestId,
        accept: true,
      );
    } catch (e) {
      return false;
    }
  }
  
  // Reject merge request
  static Future<bool> rejectMergeRequest(String requestId) async {
    try {
      return await SupabaseHandler.respondToMergeRequest(
        requestId: requestId,
        accept: false,
      );
    } catch (e) {
      return false;
    }
  }
  
  // Get connected favorites (merged with other users)
  static Future<List<Map<String, dynamic>>> getConnectedFavorites() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return [];
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return [];
      
      final connectedFavorites = await SupabaseHandler.getConnectedFavorites(userData['id'].toString());
      return connectedFavorites ?? [];
    } catch (e) {
      // Return empty list on any error - don't expose database issues
      return [];
    }
  }
  
  // Get favorites count
  static Future<int> getFavoritesCount() async {
    try {
      final favorites = await getUserFavorites();
      return favorites.length;
    } catch (e) {
      return 0;
    }
  }
  
  // Toggle favorite status
  static Future<bool> toggleFavorite({
    required String animeId,
    required String animeTitle,
    String? animeImage,
  }) async {
    try {
      final isCurrentlyFavorite = await isInFavorites(animeId);
      
      if (isCurrentlyFavorite) {
        return await removeFromFavorites(animeId);
      } else {
        return await addToFavorites(
          animeId: animeId,
          animeTitle: animeTitle,
          animeImage: animeImage,
        );
      }
    } catch (e) {
      return false;
    }
  }
}
