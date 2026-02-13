import 'dart:convert';
import '../../../auth/handler/supabase.dart';

class UserProfileHandler {
  
  /// Get user profile data by username - optimized
  static Future<Map<String, dynamic>> getUserProfile(String username) async {
    try {
      // Get user basic data
      final userData = await SupabaseHandler.getData(
        table: 'users',
        select: 'id,username,display_name,email,avatar_url,created_at,updated_at,is_active',
        filters: {'username': username},
      );
      
      if (userData == null || userData.isEmpty) {
        return {'success': false, 'message': 'User not found'};
      }
      
      final user = userData.first;
      final userId = user['id'];
      
      // Run count queries in parallel
      final countResults = await Future.wait([
        SupabaseHandler.getData(
          table: 'favorites',
          select: 'id',
          filters: {'user_id': userId, 'is_public': true},
        ),
        // Check both directions for merged accounts
        SupabaseHandler.getData(
          table: 'merged_accounts',
          select: 'id',
          filters: {'user1_id': userId},
        ),
        SupabaseHandler.getData(
          table: 'merged_accounts',
          select: 'id',
          filters: {'user2_id': userId},
        ),
      ]);
      
      final favoritesData = countResults[0];
      final syncedAsUser1 = countResults[1];
      final syncedAsUser2 = countResults[2];
      
      // Total synced accounts (user can be user1 or user2 in merged_accounts)
      final totalSyncedAccounts = (syncedAsUser1?.length ?? 0) + (syncedAsUser2?.length ?? 0);
      
      // Calculate online status
      bool isOnline = false;
      if (user['updated_at'] != null) {
        try {
          DateTime lastUpdate = DateTime.parse(user['updated_at']);
          isOnline = DateTime.now().difference(lastUpdate).inMinutes <= 30;
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
          'synced_accounts_count': totalSyncedAccounts,
          'can_sync': totalSyncedAccounts < 2, // Max 2 sync accounts
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
  
  /// Get user's public favorites - optimized
  static Future<Map<String, dynamic>> getUserFavorites(String username) async {
    try {
      final publicFavoritesData = await SupabaseHandler.getData(
        table: 'public_favorites',
        select: 'anime_id,anime_title,anime_image,added_at,username,display_name',
        filters: {'username': username},
      );
      
      return {
        'success': true,
        'favorites': publicFavoritesData ?? [],
        'count': publicFavoritesData?.length ?? 0,
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
  
  /// Get user's synced accounts - optimized
  static Future<Map<String, dynamic>> getUserSyncedAccounts(String username) async {
    try {
      // Get user ID first
      final userData = await SupabaseHandler.getData(
        table: 'users',
        select: 'id',
        filters: {'username': username},
      );
      
      if (userData == null || userData.isEmpty) {
        return {'success': false, 'message': 'User not found'};
      }
      
      final userId = userData.first['id'];
      
      // Get merged accounts with user details in one query
      final mergeData = await SupabaseHandler.getData(
        table: 'merged_accounts',
        select: 'user2_id,merged_at',
        filters: {'user1_id': userId},
      );
      
      if (mergeData == null || mergeData.isEmpty) {
        return {'success': true, 'synced_accounts': [], 'count': 0};
      }
      
      // Get all merged user details in parallel
      final userDetailsFutures = mergeData.map((merge) => 
        SupabaseHandler.getData(
          table: 'users',
          select: 'username,display_name,avatar_url',
          filters: {'id': merge['user2_id']},
        )
      ).toList();
      
      final userDetailsResults = await Future.wait(userDetailsFutures);
      
      List<Map<String, dynamic>> syncedAccounts = [];
      for (int i = 0; i < mergeData.length; i++) {
        final userDetails = userDetailsResults[i];
        if (userDetails != null && userDetails.isNotEmpty) {
          syncedAccounts.add({
            'username': userDetails.first['username'],
            'display_name': userDetails.first['display_name'],
            'avatar_url': userDetails.first['avatar_url'],
            'merged_at': mergeData[i]['merged_at'],
          });
        }
      }
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
