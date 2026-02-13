import 'dart:convert';
import '../../../auth/handler/supabase.dart';
import '../../../../services/notification_service.dart';

class SyncUserHandler {
  
  /// Sync user data and send welcome notification
  static Future<Map<String, dynamic>> syncUser({
    required String userId,
    required String username,
    required String email,
    String? profileImage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await SupabaseHandler.getData(
        table: 'users',
        select: 'id,username,email,created_at',
        filters: {'id': userId},
      );
      
      bool isNewUser = existingUser == null || existingUser.isEmpty;
      
      if (isNewUser) {
        // Create new user
        final userData = {
          'id': userId,
          'username': username,
          'email': email,
          'profile_image': profileImage,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'is_active': true,
          'notification_enabled': true,
          ...?additionalData,
        };
        
        final result = await SupabaseHandler.insertData(
          table: 'users',
          data: userData,
        );
        
        if (result != null && result.isNotEmpty) {
          // Send welcome notification for new user
          await _sendWelcomeNotification(userId, username);
          
          return {
            'success': true,
            'message': 'User created successfully',
            'user': result[0],
            'isNewUser': true,
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to create user',
            'error': 'Database insertion failed',
          };
        }
      } else {
        // Update existing user
        final updateData = {
          'username': username,
          'email': email,
          'profile_image': profileImage,
          'updated_at': DateTime.now().toIso8601String(),
          'last_login': DateTime.now().toIso8601String(),
          ...?additionalData,
        };
        
        final result = await SupabaseHandler.updateData(
          table: 'users',
          data: updateData,
          filters: {'id': userId},
        );
        
        if (result != null) {
          // Send login notification for returning user
          await _sendLoginNotification(userId, username);
          
          return {
            'success': true,
            'message': 'User updated successfully',
            'user': existingUser.first,
            'isNewUser': false,
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to update user',
            'error': 'Database update failed',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Sync failed',
        'error': e.toString(),
      };
    }
  }
  
  /// Sync user's favorite anime
  static Future<Map<String, dynamic>> syncFavorites({
    required String userId,
    required List<Map<String, dynamic>> favorites,
  }) async {
    try {
      // Clear existing favorites
      await SupabaseHandler.deleteData(
        table: 'user_favorites',
        filters: {'user_id': userId},
      );
      
      // Insert new favorites
      List<Map<String, dynamic>> favoriteData = favorites.map((anime) => {
        'user_id': userId,
        'anime_id': anime['anime_id'],
        'anime_title': anime['title'],
        'anime_poster': anime['poster'],
        'added_at': DateTime.now().toIso8601String(),
        'is_active': true,
      }).toList();
      
      if (favoriteData.isNotEmpty) {
        // Insert each favorite individually
        for (var favorite in favoriteData) {
          await SupabaseHandler.insertData(
            table: 'user_favorites',
            data: favorite,
          );
        }
        
        // Send favorites sync notification
        await _sendFavoritesSyncNotification(userId, favorites.length);
        
        return {
          'success': true,
          'message': 'Favorites synced successfully',
          'count': favorites.length,
        };
      }
      
      return {
        'success': true,
        'message': 'No favorites to sync',
        'count': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to sync favorites',
        'error': e.toString(),
      };
    }
  }
  
  /// Get all users for sync page
  static Future<Map<String, dynamic>> getAllUsers({
    int limit = 50,
    String? searchQuery,
  }) async {
    try {
      Map<String, dynamic>? filters;
      
      // Add search filter if query provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filters = {
          'or': '(username.ilike.%$searchQuery%,email.ilike.%$searchQuery%)',
        };
      }
      
      final result = await SupabaseHandler.getData(
        table: 'users',
        select: 'id,username,email,avatar_url,created_at,updated_at,is_active,firebase_uid,display_name',
        filters: filters,
      );
      
      if (result != null) {
        // Add online status based on updated_at (mock logic)
        List<Map<String, dynamic>> users = result.map((user) {
          // Consider user online if updated within last 30 minutes
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
            ...user,
            'is_online': isOnline,
          };
        }).toList();
        
        // Sort by online status first, then by username
        users.sort((a, b) {
          if (a['is_online'] != b['is_online']) {
            return b['is_online'] ? 1 : -1; // Online users first
          }
          return (a['username'] ?? '').compareTo(b['username'] ?? '');
        });
        
        return {
          'success': true,
          'users': users,
          'count': users.length,
        };
      } else {
        return {
          'success': false,
          'message': 'No users found',
          'users': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get users',
        'error': e.toString(),
        'users': [],
      };
    }
  }
  
  /// Get user's synced data
  static Future<Map<String, dynamic>> getUserData(String userId) async {
    try {
      // Get user info
      final userData = await SupabaseHandler.getData(
        table: 'users',
        select: '*',
        filters: {'id': userId},
      );
      
      // Get user favorites
      final favoritesData = await SupabaseHandler.getData(
        table: 'user_favorites',
        select: '*',
        filters: {'user_id': userId, 'is_active': true},
      );
      
      if (userData != null && userData.isNotEmpty) {
        return {
          'success': true,
          'user': userData.first,
          'favorites': favoritesData ?? [],
          'favorites_count': favoritesData?.length ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'User not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to get user data',
        'error': e.toString(),
      };
    }
  }
  
  /// Enable/disable notifications for user
  static Future<Map<String, dynamic>> updateNotificationSettings({
    required String userId,
    required bool enabled,
  }) async {
    try {
      final result = await SupabaseHandler.updateData(
        table: 'users',
        data: {
          'notification_enabled': enabled,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': userId},
      );
      
      if (result != null) {
        return {
          'success': true,
          'message': 'Notification settings updated',
          'notification_enabled': enabled,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to update notification settings',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to update settings',
        'error': e.toString(),
      };
    }
  }
  
  // Private notification methods
  
  static Future<void> _sendWelcomeNotification(String userId, String username) async {
    try {
      await NotificationService.sendWelcome(userId);
    } catch (e) {
    }
  }
  
  static Future<void> _sendLoginNotification(String userId, String username) async {
    try {
      await NotificationService.sendNotification(
        userId: userId,
        title: 'Welcome Back',
        body: 'Welcome back to Hiotaku! Continue watching your favorite anime.',
        type: 'general',
        screen: '/favourite',
      );
    } catch (e) {
    }
  }
  
  static Future<void> _sendFavoritesSyncNotification(String userId, int count) async {
    try {
      await NotificationService.sendNotification(
        userId: userId,
        title: 'Favorites Synced',
        body: '$count favorite anime have been synced to your account.',
        type: 'favourite',
        screen: '/favourite',
      );
    } catch (e) {
    }
  }
}
