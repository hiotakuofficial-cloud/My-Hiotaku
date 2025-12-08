import 'dart:convert';
import '../../../auth/handler/supabase.dart';

class UserProfileHandler {
  
  /// Get user profile data by username
  static Future<Map<String, dynamic>> getUserProfile(String username) async {
    try {
      // Get user basic data
      final userData = await SupabaseHandler.getData(
        table: 'users',
        select: 'id,username,display_name,email,avatar_url,created_at,updated_at,is_active',
        filters: {'username': username},
      );
      
      if (userData == null || userData.isEmpty) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }
      
      final user = userData.first;
      final userId = user['id'];
      
      // Get public favorites count
      final favoritesData = await SupabaseHandler.getData(
        table: 'user_favorites',
        select: 'id',
        filters: {'user_id': userId, 'is_active': true},
      );
      
      // Get synced accounts count (users who synced with this user)
      final syncedAccountsData = await SupabaseHandler.getData(
        table: 'user_sync',
        select: 'id',
        filters: {'target_user_id': userId, 'is_active': true},
      );
      
      // Calculate online status (last updated within 30 minutes)
      bool isOnline = false;
      if (user['updated_at'] != null) {
        try {
          DateTime lastUpdate = DateTime.parse(user['updated_at']);
          Duration difference = DateTime.now().difference(lastUpdate);
          isOnline = difference.inMinutes <= 30;
        } catch (e) {
          isOnline = false;
        }
      }
      
      return {
        'success': true,
        'user': {
          'id': user['id'],
          'username': user['username'],
          'display_name': user['display_name'],
          'email': user['email'],
          'avatar_url': user['avatar_url'],
          'created_at': user['created_at'],
          'is_active': user['is_active'],
          'is_online': isOnline,
          'public_favorites_count': favoritesData?.length ?? 0,
          'synced_accounts_count': syncedAccountsData?.length ?? 0,
          'can_sync': (syncedAccountsData?.length ?? 0) < 2, // Max 2 sync accounts
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load user profile',
        'error': e.toString(),
      };
    }
  }
  
  /// Get user's public favorites
  static Future<Map<String, dynamic>> getUserFavorites(String username) async {
    try {
      // First get user ID
      final userData = await SupabaseHandler.getData(
        table: 'users',
        select: 'id',
        filters: {'username': username},
      );
      
      if (userData == null || userData.isEmpty) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }
      
      final userId = userData.first['id'];
      
      // Get user's favorites
      final favoritesData = await SupabaseHandler.getData(
        table: 'user_favorites',
        select: 'anime_id,anime_title,anime_poster,added_at',
        filters: {'user_id': userId, 'is_active': true},
      );
      
      return {
        'success': true,
        'favorites': favoritesData ?? [],
        'count': favoritesData?.length ?? 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load favorites',
        'error': e.toString(),
      };
    }
  }
  
  /// Sync account with another user (max 2 syncs allowed)
  static Future<Map<String, dynamic>> syncWithUser({
    required String currentUserId,
    required String targetUsername,
  }) async {
    try {
      // Get target user data
      final targetUserData = await SupabaseHandler.getData(
        table: 'users',
        select: 'id,username',
        filters: {'username': targetUsername},
      );
      
      if (targetUserData == null || targetUserData.isEmpty) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }
      
      final targetUserId = targetUserData.first['id'];
      
      // Check if already synced
      final existingSync = await SupabaseHandler.getData(
        table: 'user_sync',
        select: 'id',
        filters: {
          'user_id': currentUserId,
          'target_user_id': targetUserId,
          'is_active': true,
        },
      );
      
      if (existingSync != null && existingSync.isNotEmpty) {
        return {
          'success': false,
          'message': 'Already synced with this user',
        };
      }
      
      // Check sync limit for current user
      final currentUserSyncs = await SupabaseHandler.getData(
        table: 'user_sync',
        select: 'id',
        filters: {'user_id': currentUserId, 'is_active': true},
      );
      
      if ((currentUserSyncs?.length ?? 0) >= 2) {
        return {
          'success': false,
          'message': 'Maximum sync limit reached (2 accounts)',
        };
      }
      
      // Create sync record
      final syncData = {
        'user_id': currentUserId,
        'target_user_id': targetUserId,
        'synced_at': DateTime.now().toIso8601String(),
        'is_active': true,
      };
      
      final result = await SupabaseHandler.insertData(
        table: 'user_sync',
        data: syncData,
      );
      
      if (result != null && result.isNotEmpty) {
        return {
          'success': true,
          'message': 'Successfully synced with ${targetUserData.first['username']}',
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to sync account',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to sync account',
        'error': e.toString(),
      };
    }
  }
  
  /// Get user's synced accounts
  static Future<Map<String, dynamic>> getUserSyncedAccounts(String username) async {
    try {
      // Get user ID
      final userData = await SupabaseHandler.getData(
        table: 'users',
        select: 'id',
        filters: {'username': username},
      );
      
      if (userData == null || userData.isEmpty) {
        return {
          'success': false,
          'message': 'User not found',
        };
      }
      
      final userId = userData.first['id'];
      
      // Get synced accounts with user details
      final syncData = await SupabaseHandler.getData(
        table: 'user_sync',
        select: 'target_user_id,synced_at',
        filters: {'user_id': userId, 'is_active': true},
      );
      
      if (syncData == null || syncData.isEmpty) {
        return {
          'success': true,
          'synced_accounts': [],
          'count': 0,
        };
      }
      
      // Get details of synced users
      List<Map<String, dynamic>> syncedAccounts = [];
      for (var sync in syncData) {
        final syncedUserData = await SupabaseHandler.getData(
          table: 'users',
          select: 'username,display_name,avatar_url',
          filters: {'id': sync['target_user_id']},
        );
        
        if (syncedUserData != null && syncedUserData.isNotEmpty) {
          syncedAccounts.add({
            ...syncedUserData.first,
            'synced_at': sync['synced_at'],
          });
        }
      }
      
      return {
        'success': true,
        'synced_accounts': syncedAccounts,
        'count': syncedAccounts.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to load synced accounts',
        'error': e.toString(),
      };
    }
  }
}
