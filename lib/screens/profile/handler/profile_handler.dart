import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/handler/supabase.dart';

class ProfileHandler {
  static RealtimeChannel? _profileSubscription;
  
  // Get current user data from Supabase with real-time updates
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        print('No Firebase user logged in');
        return null;
      }
      
      print('Firebase user found: ${firebaseUser.email}');
      
      final userData = await _getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) {
        print('No Supabase user data found for UID: ${firebaseUser.uid}');
      } else {
        print('Supabase user data found: ${userData['email']}');
      }
      
      return userData;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }
  
  // Subscribe to real-time profile updates
  static RealtimeChannel subscribeToProfile({
    required Function(Map<String, dynamic>?) onUpdate,
  }) {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) throw Exception('User not authenticated');
    
    _profileSubscription?.unsubscribe();
    
    _profileSubscription = SupabaseHandler.subscribeToTable(
      table: 'users',
      filter: 'firebase_uid=${firebaseUser.uid}',
      onData: (payload) async {
        // Refresh user data when profile changes
        final userData = await getCurrentUserData();
        onUpdate(userData);
      },
    );
    
    return _profileSubscription!;
  }
  
  // Update user profile data
  static Future<bool> updateUserProfile({
    required String displayName,
    String? avatarUrl,
    String? username,
    String? bio,
  }) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      // Update Firebase display name
      await firebaseUser.updateDisplayName(displayName);
      
      // Update Supabase data
      final success = await SupabaseHandler.updateData(
        table: 'users',
        data: {
          'display_name': displayName,
          'avatar_url': avatarUrl,
          'username': username,
          'bio': bio,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'firebase_uid': firebaseUser.uid},
      );
      
      return success;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
  
  // Create or update user profile
  static Future<Map<String, dynamic>?> createOrUpdateUser({
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
      
      final result = await SupabaseHandler.upsertData(
        table: 'users',
        data: userData,
        onConflict: 'firebase_uid',
      );
      
      return result;
    } catch (e) {
      print('Create/Update user error: $e');
      return null;
    }
  }
  
  // Get user statistics
  static Future<Map<String, int>> getUserStats() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return {};
      
      final userData = await _getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return {};
      
      // Get favorites count
      final favorites = await SupabaseHandler.getData(
        table: 'favorites',
        filters: {'user_id': userData['id']},
      );
      
      // Get watch history count (if you have this table)
      final watchHistory = await SupabaseHandler.getData(
        table: 'watch_history',
        filters: {'user_id': userData['id']},
      );
      
      return {
        'favorites': favorites?.length ?? 0,
        'watchHistory': watchHistory?.length ?? 0,
      };
    } catch (e) {
      print('Get user stats error: $e');
      return {};
    }
  }
  
  // Delete user account
  static Future<bool> deleteUserAccount() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      // Delete from Supabase first
      final supabaseSuccess = await SupabaseHandler.deleteData(
        table: 'users',
        filters: {'firebase_uid': firebaseUser.uid},
      );
      
      if (supabaseSuccess) {
        // Delete Firebase user
        await firebaseUser.delete();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Delete user account error: $e');
      return false;
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
    _profileSubscription?.unsubscribe();
    _profileSubscription = null;
  }
}
