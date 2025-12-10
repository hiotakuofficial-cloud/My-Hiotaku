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
        table: 'favorites',
        select: 'id',
        filters: {'user_id': userId, 'is_public': true},
      );
      
      // Get synced accounts count (users who merged with this user)
      final syncedAccountsData = await SupabaseHandler.getData(
        table: 'merged_accounts',
        select: 'id',
        filters: {'user1_id': userId}, // Check if user is primary in merge
      );
      
      // Calculate online status (last updated within 5 minutes)
      bool isOnline = false;
      if (user['updated_at'] != null) {
        try {
          DateTime lastUpdate = DateTime.parse(user['updated_at']);
          Duration difference = DateTime.now().difference(lastUpdate);
          isOnline = difference.inMinutes <= 5;
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
          'message': 'User not found for username: $username',
        };
      }
      
      final userId = userData.first['id'];
      
      // Get user's public favorites from favorites table where is_public=true
      final publicFavoritesData = await SupabaseHandler.getData(
        table: 'favorites',
        select: 'anime_id,anime_title,anime_image,created_at',
        filters: {'user_id': userId, 'is_public': true},
      );
      
      // If no public favorites, check total favorites for debugging
      if (publicFavoritesData == null || publicFavoritesData.isEmpty) {
        final allFavorites = await SupabaseHandler.getData(
          table: 'favorites',
          select: 'anime_id,is_public',
          filters: {'user_id': userId},
        );
        
        return {
          'success': true,
          'favorites': [],
          'count': 0,
          'debug_info': 'No public favorites. Total favorites: ${allFavorites?.length ?? 0}',
          'all_favorites': allFavorites?.map((f) => '${f['anime_id']}:${f['is_public']}').join(', ') ?? 'none',
        };
      }
      
      return {
        'success': true,
        'favorites': publicFavoritesData,
        'count': publicFavoritesData.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
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
      
      // Check if already merged
      final existingMerge = await SupabaseHandler.getData(
        table: 'merged_accounts',
        select: 'id',
        filters: {
          'user1_id': currentUserId,
          'user2_id': targetUserId,
        },
      );
      
      if (existingMerge != null && existingMerge.isNotEmpty) {
        return {
          'success': false,
          'message': 'Already merged with this user',
        };
      }
      
      // Check merge limit for current user (max 2 merges)
      final currentUserMerges = await SupabaseHandler.getData(
        table: 'merged_accounts',
        select: 'id',
        filters: {'user1_id': currentUserId},
      );
      
      if ((currentUserMerges?.length ?? 0) >= 2) {
        return {
          'success': false,
          'message': 'Maximum merge limit reached (2 accounts)',
        };
      }
      
      // Create merge request
      final mergeRequestData = {
        'sender_id': currentUserId,
        'receiver_id': targetUserId,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };
      
      final result = await SupabaseHandler.insertData(
        table: 'merge_requests',
        data: mergeRequestData,
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
      
      // Get merged accounts with user details
      final mergeData = await SupabaseHandler.getData(
        table: 'merged_accounts',
        select: 'user2_id,merged_at',
        filters: {'user1_id': userId},
      );
      
      if (mergeData == null || mergeData.isEmpty) {
        return {
          'success': true,
          'synced_accounts': [],
          'count': 0,
        };
      }
      
      // Get details of merged users
      List<Map<String, dynamic>> syncedAccounts = [];
      for (var merge in mergeData) {
        final syncedUserData = await SupabaseHandler.getData(
          table: 'users',
          select: 'username,display_name,avatar_url',
          filters: {'id': merge['user2_id']},
        );
        
        if (syncedUserData != null && syncedUserData.isNotEmpty) {
          syncedAccounts.add({
            ...syncedUserData.first,
            'merged_at': merge['merged_at'],
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
