import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/notification_service.dart';
import '../../../database/data_validator.dart';

class SupabaseHandler {
  // Supabase Configuration with fallback values
  static const String _supabaseUrl = String.fromEnvironment('SUPA_URL', 
    defaultValue: '');
  static const String _supabaseAnonKey = String.fromEnvironment('ANON_KEY',
    defaultValue: '');
  
  // Base headers for all requests
  static Map<String, String> get _headers => {
    'apikey': _supabaseAnonKey,
    'Authorization': 'Bearer $_supabaseAnonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // Generic REST API methods
  
  /// GET request to Supabase REST API
  static Future<List<Map<String, dynamic>>?> getData({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
  }) async {
    try {
      String url = '$_supabaseUrl/rest/v1/$table';
      
      // Add select parameter
      if (select != null) {
        url += '?select=$select';
      } else {
        url += '?select=*';
      }
      
      // Add filters
      if (filters != null) {
        filters.forEach((key, value) {
          url += '&$key=eq.$value';
        });
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        // Log error without sensitive data
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// POST request to insert data
  static Future<Map<String, dynamic>?> insertData({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/rest/v1/$table'),
        headers: _headers,
        body: json.encode(data),
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode == 201) {
        final List<dynamic> result = json.decode(response.body);
        return result.isNotEmpty ? result[0] : null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  /// PATCH request to update data
  static Future<bool> updateData({
    required String table,
    required Map<String, dynamic> data,
    required Map<String, dynamic> filters,
  }) async {
    try {
      String url = '$_supabaseUrl/rest/v1/$table?';
      
      // Add filters
      filters.forEach((key, value) {
        url += '$key=eq.$value&';
      });
      url = url.substring(0, url.length - 1); // Remove last &
      
      final response = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: json.encode(data),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
  
  /// DELETE request to remove data
  static Future<bool> deleteData({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      String url = '$_supabaseUrl/rest/v1/$table?';
      
      // Add filters
      filters.forEach((key, value) {
        url += '$key=eq.$value&';
      });
      url = url.substring(0, url.length - 1); // Remove last &
      
      final response = await http.delete(
        Uri.parse(url),
        headers: _headers,
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // User-organized methods for specific tables
  
  /// Get user by Firebase UID
  static Future<Map<String, dynamic>?> getUserByFirebaseUID(String firebaseUID) async {
    final users = await getData(
      table: 'users',
      filters: {'firebase_uid': firebaseUID},
    );
    return users?.isNotEmpty == true ? users![0] : null;
  }
  
  /// Create or update user with validation
  static Future<Map<String, dynamic>?> upsertUser({
    required String firebaseUID,
    required String email,
    String? displayName,
    String? avatarUrl,
    String? username,
  }) async {
    try {
      // Validate input data
      final validatedData = DataValidator.validateUserData(
        firebaseUID: firebaseUID,
        email: email,
        displayName: displayName,
        avatarUrl: avatarUrl,
        username: username,
      );
      
      if (validatedData == null) return null;
      
      // Check if user exists
      final existingUser = await getUserByFirebaseUID(firebaseUID);
      
      if (existingUser != null) {
        // Update existing user
        final success = await updateData(
          table: 'users',
          data: validatedData,
          filters: {'firebase_uid': firebaseUID},
        );
        return success ? existingUser : null;
      } else {
        // Create new user
        return await insertData(
          table: 'users',
          data: validatedData,
        );
      }
    } catch (e) {
      return null;
    }
  }

  // Favorites methods
  
  /// Get user's favorites
  static Future<List<Map<String, dynamic>>?> getUserFavorites(String userId) async {
    return await getData(
      table: 'favorites',
      filters: {'user_id': userId},
    );
  }
  
  /// Add to favorites with validation
  static Future<Map<String, dynamic>?> addToFavorites({
    required String userId,
    required String animeId,
    required String animeTitle,
    String? animeImage,
    bool isPublic = false,
  }) async {
    try {
      // Validate input data
      final validatedData = DataValidator.validateFavoriteData(
        userId: userId,
        animeId: animeId,
        animeTitle: animeTitle,
        animeImage: animeImage,
        isPublic: isPublic,
      );
      
      if (validatedData == null) return null;
      
      return await insertData(
        table: 'favorites',
        data: validatedData,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Remove from favorites
  static Future<bool> removeFromFavorites({
    required String userId,
    required String animeId,
  }) async {
    return await deleteData(
      table: 'favorites',
      filters: {'user_id': userId, 'anime_id': animeId},
    );
  }
  
  /// Get public favorites
  static Future<List<Map<String, dynamic>>?> getPublicFavorites() async {
    try {
      // Query favorites with is_public=true and JOIN with users table to get username and avatar
      String url = '$_supabaseUrl/rest/v1/favorites?is_public=eq.true&select=*,users(username,avatar_url)';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': _supabaseAnonKey,
          'Authorization': 'Bearer $_supabaseAnonKey',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Flatten the user data for easier access
        return data.map((item) {
          final Map<String, dynamic> favorite = Map<String, dynamic>.from(item);
          if (favorite['users'] != null && favorite['users'] is Map) {
            final userData = favorite['users'] as Map<String, dynamic>;
            favorite['username'] = userData['username'];
            favorite['avatar_url'] = userData['avatar_url'];
            favorite.remove('users'); // Remove nested object
          }
          return favorite;
        }).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Merge request methods
  
  /// Send merge request with validation
  static Future<Map<String, dynamic>?> sendMergeRequest({
    required String senderId,
    required String receiverId,
    String? message,
  }) async {
    try {
      // Validate input data
      final validatedData = DataValidator.validateMergeRequestData(
        senderId: senderId,
        receiverId: receiverId,
        message: message,
      );
      
      if (validatedData == null) return null;
      
      return await insertData(
        table: 'merge_requests',
        data: validatedData,
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Get pending merge requests for user
  static Future<List<Map<String, dynamic>>?> getPendingMergeRequests(String userId) async {
    return await getData(
      table: 'merge_requests',
      filters: {'receiver_id': userId, 'status': 'pending'},
    );
  }
  
  /// Respond to merge request
  static Future<bool> respondToMergeRequest({
    required String requestId,
    required bool accept,
  }) async {
    return await updateData(
      table: 'merge_requests',
      data: {
        'status': accept ? 'accepted' : 'rejected',
        'responded_at': getCurrentTimestamp(),
      },
      filters: {'id': requestId},
    );
  }
  
  /// Get connected favorites for user
  static Future<List<Map<String, dynamic>>?> getConnectedFavorites(String userId) async {
    try {
      // Query both user1_id and user2_id to get all connections
      final url = '$_supabaseUrl/rest/v1/connected_fav?or=(user1_id.eq.$userId,user2_id.eq.$userId)';
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
      return null;
    } catch (e) {
      // Return null on database error - let caller handle gracefully
      return null;
    }
  }

  // Sync Request System
  
  /// Send sync request to another user
  static Future<bool> sendSyncRequest({
    required String senderId,
    required String receiverId,
    required String senderUsername,
  }) async {
    try {
      // Check if request already exists
      final existing = await getData(
        table: 'merge_requests',
        filters: {
          'sender_id': senderId,
          'receiver_id': receiverId,
        },
      );

      if (existing != null && existing.isNotEmpty) {
        return false; // Request already exists
      }

      // Insert sync request
      final result = await insertData(
        table: 'merge_requests',
        data: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': 'Sync request from $senderUsername',
          'status': 'pending',
          'created_at': getCurrentTimestamp(),
        },
      );

      if (result != null) {
        // Send notification to receiver
        await _sendSyncNotification(receiverId, senderUsername);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check sync request status between two users
  static Future<String> getSyncStatus({
    required String currentUserId,
    required String targetUserId,
  }) async {
    try {
      // Check if current user sent request to target
      final sentRequests = await getData(
        table: 'merge_requests',
        filters: {
          'sender_id': currentUserId,
          'receiver_id': targetUserId,
        },
      );

      if (sentRequests != null && sentRequests.isNotEmpty) {
        final status = sentRequests.first['status'];
        if (status == 'pending') return 'requested';
        if (status == 'accepted') return 'connected';
      }

      // Check if target sent request to current user
      final receivedRequests = await getData(
        table: 'merge_requests',
        filters: {
          'sender_id': targetUserId,
          'receiver_id': currentUserId,
        },
      );

      if (receivedRequests != null && receivedRequests.isNotEmpty) {
        final status = receivedRequests.first['status'];
        if (status == 'accepted') return 'connected';
      }

      return 'none';
    } catch (e) {
      return 'none';
    }
  }

  /// Disconnect from synced user
  static Future<bool> disconnectSync({
    required String userId1,
    required String userId2,
  }) async {
    try {
      // Delete all merge requests between users
      await deleteData(
        table: 'merge_requests',
        filters: {
          'sender_id': userId1,
          'receiver_id': userId2,
        },
      );

      await deleteData(
        table: 'merge_requests',
        filters: {
          'sender_id': userId2,
          'receiver_id': userId1,
        },
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Send notification for sync request
  static Future<void> _sendSyncNotification(String receiverId, String senderUsername) async {
    try {
      // Use existing notification service API
      final success = await NotificationService.sendNotification(
        userId: receiverId,
        title: 'Sync Request',
        body: '$senderUsername wants to sync favorites with you',
        type: 'sync_request',
        screen: '/favourite',
        extraData: {'sender_username': senderUsername},
      );
      
      if (success) {
      } else {
      }
    } catch (e) {
    }
  }

  // Utility methods
  
  /// Get current timestamp
  static String getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }
  
  /// Check if connection is working
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_supabaseUrl/rest/v1/'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
