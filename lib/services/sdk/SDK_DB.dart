import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSDK {
  static SupabaseClient get client => Supabase.instance.client;
  
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
          .select('is_online, last_seen')
          .eq('firebase_uid', firebaseUID)
          .limit(1);
      
      if (response.isNotEmpty) {
        final user = response.first;
        if (user['is_online'] == true) {
          // Check if last seen is within 10 minutes (UTC comparison)
          final lastSeen = DateTime.parse(user['last_seen']).toUtc();
          final now = DateTime.now().toUtc();
          final difference = now.difference(lastSeen).inMinutes;
          
          return difference <= 30;
        }
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
