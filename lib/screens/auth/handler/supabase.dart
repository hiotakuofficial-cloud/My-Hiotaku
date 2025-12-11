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
      var query = client.from(table).select(select ?? '*');
      
      // Add filters
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }
      
      // Add ordering
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      
      // Add limit
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
      final response = await client
          .from(table)
          .insert(data)
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('INSERT Exception: $e');
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
      var query = client.from(table).update(data);
      
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
      var query = client.from(table).delete();
      
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
}
}
