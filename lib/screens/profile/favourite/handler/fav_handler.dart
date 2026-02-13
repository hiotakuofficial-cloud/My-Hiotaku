import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/handler/supabase.dart';

class FavouriteHandler {
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  static Future<T?> _withRetry<T>(Future<T?> Function() operation) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxRetries) return null;
        await Future.delayed(retryDelay * attempt);
      }
    }
    return null;
  }
  
  static Future<List<Map<String, dynamic>>> getUserFavorites() async {
    return await _withRetry(() async {
      if (currentUserId == null) throw Exception('User not authenticated');
      
      final user = await SupabaseHandler.getUserByFirebaseUID(currentUserId!);
      if (user == null) throw Exception('User not found');
      
      final favorites = await SupabaseHandler.getUserFavorites(user['id']);
      return (favorites ?? []).cast<Map<String, dynamic>>();
    }) ?? [];
  }
  
  static Future<bool> addFavorite({
    required String animeId,
    required String animeTitle,
    String? animeImage,
  }) async {
    final result = await _withRetry(() async {
      if (currentUserId == null) throw Exception('User not authenticated');
      
      final user = await SupabaseHandler.getUserByFirebaseUID(currentUserId!);
      if (user == null) throw Exception('User not found');
      
      final result = await SupabaseHandler.addToFavorites(
        userId: user['id'],
        animeId: animeId,
        animeTitle: animeTitle,
        animeImage: animeImage,
        isPublic: false,
      );
      
      return result != null;
    });
    
    return result ?? false;
  }
  
  static Future<bool> removeFavorite(String animeId) async {
    final result = await _withRetry(() async {
      if (currentUserId == null) throw Exception('User not authenticated');
      
      final user = await SupabaseHandler.getUserByFirebaseUID(currentUserId!);
      if (user == null) throw Exception('User not found');
      
      return await SupabaseHandler.removeFromFavorites(
        userId: user['id'],
        animeId: animeId,
      );
    });
    
    return result ?? false;
  }
  
  static Future<bool> isFavorite(String animeId) async {
    try {
      final favorites = await getUserFavorites();
      return favorites.any((fav) => fav['anime_id'] == animeId);
    } catch (e) {
      return false;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getConnectedFavorites() async {
    return await _withRetry(() async {
      if (currentUserId == null) throw Exception('User not authenticated');
      
      final user = await SupabaseHandler.getUserByFirebaseUID(currentUserId!);
      if (user == null) throw Exception('User not found');
      
      final connected = await SupabaseHandler.getConnectedFavorites(user['id']);
      return (connected ?? []).cast<Map<String, dynamic>>();
    }) ?? [];
  }
}
