import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHandler {
  // Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
  
  /// GET request using Supabase SDK
  static Future<List<Map<String, dynamic>>?> getData({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      dynamic query = client.from(table).select(select ?? '*');
      
      // Add filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }
      
      // Add ordering and limit in chain
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('GET Exception: $e');
      return null;
    }
  }
  
  /// INSERT data using Supabase SDK
  static Future<Map<String, dynamic>?> insertData({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      print('📝 Inserting into $table: $data');
      
      final response = await client
          .from(table)
          .insert(data)
          .select()
          .single();
      
      print('✅ Insert successful: $response');
      return response;
    } catch (e) {
      print('❌ INSERT Exception: $e');
      return null;
    }
  }
  
  /// UPDATE data using Supabase SDK
  static Future<bool> updateData({
    required String table,
    required Map<String, dynamic> data,
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = client.from(table).update(data);
      
      // Add filters
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
      
      await query;
      return true;
    } catch (e) {
      print('UPDATE Exception: $e');
      return false;
    }
  }
  
  /// DELETE data using Supabase SDK
  static Future<bool> deleteData({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      dynamic query = client.from(table).delete();
      
      // Add filters
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
      
      await query;
      return true;
    } catch (e) {
      print('DELETE Exception: $e');
      return false;
    }
  }
  
  /// UPSERT data using Supabase SDK
  static Future<Map<String, dynamic>?> upsertData({
    required String table,
    required Map<String, dynamic> data,
    String? onConflict,
  }) async {
    try {
      final response = await client
          .from(table)
          .upsert(data, onConflict: onConflict)
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('UPSERT Exception: $e');
      return null;
    }
  }
  
  /// Real-time subscription
  static RealtimeChannel subscribeToTable({
    required String table,
    required Function(PostgresChangePayload) onData,
    PostgresChangeEvent event = PostgresChangeEvent.all,
    String? filter,
  }) {
    final channel = client
        .channel('public:$table')
        .onPostgresChanges(
          event: event,
          schema: 'public',
          table: table,
          filter: filter != null ? PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: filter.split('=')[0],
            value: filter.split('=')[1],
          ) : null,
          callback: onData,
        )
        .subscribe();
    
    return channel;
  }
  
  /// Get current user
  static User? get currentUser => client.auth.currentUser;
  
  /// Check if user is authenticated
  static bool get isAuthenticated => client.auth.currentUser != null;
  
  /// Sign in with email and password
  static Future<AuthResponse?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }
  
  /// Sign up with email and password
  static Future<AuthResponse?> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: data,
      );
      return response;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }
  
  /// Sign out
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
  }
  
  /// Listen to auth state changes
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
  
  /// Update user's last seen timestamp for online status
  static Future<void> updateUserLastSeen(String firebaseUID) async {
    try {
      await updateData(
        table: 'users',
        data: {
          'last_seen': DateTime.now().toIso8601String(),
          'is_online': true,
        },
        filters: {'firebase_uid': firebaseUID},
      );
    } catch (e) {
      print('Update last seen error: $e');
    }
  }
  
  /// Set user offline status
  static Future<void> setUserOffline(String firebaseUID) async {
    try {
      await updateData(
        table: 'users',
        data: {
          'is_online': false,
          'last_seen': DateTime.now().toIso8601String(),
        },
        filters: {'firebase_uid': firebaseUID},
      );
    } catch (e) {
      print('Set user offline error: $e');
    }
  }
  
  /// Get user by Firebase UID
  static Future<Map<String, dynamic>?> getUserByFirebaseUID(String firebaseUID) async {
    try {
      final result = await getData(
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
  
  /// Get user favorites
  static Future<List<Map<String, dynamic>>?> getUserFavorites(String userId) async {
    try {
      final favorites = await getData(
        table: 'favorites',
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );
      
      return favorites;
    } catch (e) {
      print('Get user favorites error: $e');
      return null;
    }
  }
  
  /// Add to favorites
  static Future<Map<String, dynamic>?> addToFavorites({
    required String userId,
    required String animeId,
    required String animeTitle,
    String? animeImage,
    bool isPublic = false,
  }) async {
    try {
      final result = await insertData(
        table: 'favorites',
        data: {
          'user_id': userId,
          'anime_id': animeId,
          'anime_title': animeTitle,
          'anime_image': animeImage,
          'is_public': isPublic,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      return result;
    } catch (e) {
      print('Add to favorites error: $e');
      return null;
    }
  }
  
  /// Remove from favorites
  static Future<bool> removeFromFavorites({
    required String userId,
    required String animeId,
  }) async {
    try {
      final success = await deleteData(
        table: 'favorites',
        filters: {
          'user_id': userId,
          'anime_id': animeId,
        },
      );
      
      return success;
    } catch (e) {
      print('Remove from favorites error: $e');
      return false;
    }
  }
  
  /// Get public favorites with user info
  static Future<List<Map<String, dynamic>>?> getPublicFavorites() async {
    try {
      final favorites = await getData(
        table: 'favorites',
        select: '*, users!inner(id, display_name, username, avatar_url)',
        filters: {'is_public': true},
        orderBy: 'added_at',
        ascending: false,
        limit: 50,
      );
      
      return favorites;
    } catch (e) {
      print('Get public favorites error: $e');
      return null;
    }
  }
  
  /// Upsert user
  static Future<Map<String, dynamic>?> upsertUser({
    required String firebaseUID,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? username,
  }) async {
    try {
      final userData = {
        'firebase_uid': firebaseUID,
        'email': email,
        'display_name': displayName ?? email.split('@')[0],
        'avatar_url': avatarUrl,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final result = await upsertData(
        table: 'users',
        data: userData,
        onConflict: 'firebase_uid',
      );
      
      return result;
    } catch (e) {
      print('Upsert user error: $e');
      return null;
    }
  }
}
