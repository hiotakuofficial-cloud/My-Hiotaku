import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupabaseSDK {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Direct online status management - no WebSocket needed
  static Future<bool> setUserOnline() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      final userData = await getUserByFirebaseUID(currentUser.uid);
      if (userData == null) return false;
      
      await client
          .from('users')
          .update({
            'is_online': true,
            'last_seen': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userData['id']);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Set user offline when app minimized/closed
  static Future<bool> setUserOffline() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      final userData = await getUserByFirebaseUID(currentUser.uid);
      if (userData == null) return false;
      
      await client
          .from('users')
          .update({
            'is_online': false,
            'last_seen': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userData['id']);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Check if user is online (direct database read - no time calculation)
  static Future<bool> isUserOnlineByUsername(String username) async {
    try {
      final response = await client
          .from('users')
          .select('is_online')
          .eq('username', username)
          .limit(1);
      
      if (response.isNotEmpty) {
        return response.first['is_online'] ?? false;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Only for users table - online status management
  static Future<bool> updateUserStatus({
    required String userId,
    required bool isOnline,
  }) async {
    try {
      await client
          .from('users')
          .update({
            'is_online': isOnline,
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get user by Firebase UID (for WebSocket initialization)
  static Future<Map<String, dynamic>?> getUserByFirebaseUID(String firebaseUID) async {
    try {
      final response = await client
          .from('users')
          .select('id, username')
          .eq('firebase_uid', firebaseUID)
          .limit(1);
      
      return response.isNotEmpty ? response.first : null;
    } catch (e) {
      return null;
    }
  }
  
  // Check user online status
  static Future<bool> isUserOnline(String firebaseUID) async {
    try {
      final response = await client
          .from('users')
          .select('is_online')
          .eq('firebase_uid', firebaseUID)
          .limit(1);
      
      if (response.isNotEmpty) {
        return response.first['is_online'] ?? false;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Subscribe to user status changes (real-time)
  static RealtimeChannel? subscribeToUserStatus({
    required String firebaseUID,
    required Function(bool isOnline) onStatusChange,
  }) {
    try {
      final channel = client
          .channel('user_status_$firebaseUID')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'firebase_uid',
              value: firebaseUID,
            ),
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord != null) {
                final isOnline = newRecord['is_online'] ?? false;
                onStatusChange(isOnline);
              }
            },
          )
          .subscribe();
      
      return channel;
    } catch (e) {
      return null;
    }
  }
}
