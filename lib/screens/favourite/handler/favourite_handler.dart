import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/handler/supabase.dart';

class FavouriteHandler {
  
  // Get current user's favorites
  static Future<List<Map<String, dynamic>>> getUserFavorites() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return [];
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return [];
      
      final favorites = await SupabaseHandler.getUserFavorites(userData['id'].toString());
      return favorites ?? [];
    } catch (e) {
      print('Get user favorites error: $e');
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
      print('Add to favorites error: $e');
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
      print('Remove from favorites error: $e');
      return false;
    }
  }
  
  // Check if anime is in favorites
  static Future<bool> isInFavorites(String animeId) async {
    try {
      final favorites = await getUserFavorites();
      return favorites.any((fav) => fav['anime_id'] == animeId);
    } catch (e) {
      print('Check favorites error: $e');
      return false;
    }
  }
  
  // Get public favorites from all users
  static Future<List<Map<String, dynamic>>> getPublicFavorites() async {
    try {
      final publicFavorites = await SupabaseHandler.getPublicFavorites();
      return publicFavorites ?? [];
    } catch (e) {
      print('Get public favorites error: $e');
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
      print('Send merge request error: $e');
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
      print('Get pending requests error: $e');
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
      print('Accept merge request error: $e');
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
      print('Reject merge request error: $e');
      return false;
    }
  }
  
  // Get shared favorites (merged with other users)
  static Future<List<Map<String, dynamic>>> getSharedFavorites() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return [];
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return [];
      
      final sharedFavorites = await SupabaseHandler.getSharedFavorites(userData['id'].toString());
      return sharedFavorites ?? [];
    } catch (e) {
      print('Get shared favorites error: $e');
      return [];
    }
  }
  
  // Get favorites count
  static Future<int> getFavoritesCount() async {
    try {
      final favorites = await getUserFavorites();
      return favorites.length;
    } catch (e) {
      print('Get favorites count error: $e');
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
      print('Toggle favorite error: $e');
      return false;
    }
  }
}
