import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/handler/supabase.dart';
import '../../../../services/notification_service.dart';

class RequestsHandler {
  static const String _expiredRequestsKey = 'expired_requests_shown';
  
  // Get all sent requests for current user
  static Future<List<Map<String, dynamic>>> getSentRequests() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (userData == null) {
        final userByEmail = await SupabaseHandler.getData(
          table: 'users',
          filters: {'email': currentUser.email ?? ''},
        );
        
        if (userByEmail != null && userByEmail.isNotEmpty) {
          final userId = userByEmail[0]['id'].toString();
          final myRequests = await SupabaseHandler.getData(
            table: 'merge_requests',
            filters: {'sender_id': userId},
          );
          return myRequests ?? [];
        }
        return [];
      }
      
      final userId = userData['id'].toString();
      final myRequests = await SupabaseHandler.getData(
        table: 'merge_requests',
        filters: {'sender_id': userId},
      );
      
      if (myRequests != null && myRequests.isNotEmpty) {
        for (var request in myRequests) {
          final receiverId = request['receiver_id'];
          if (receiverId != null) {
            final receiverData = await SupabaseHandler.getData(
              table: 'users',
              filters: {'id': receiverId},
            );
            if (receiverData != null && receiverData.isNotEmpty) {
              request['receiver_username'] = receiverData[0]['username'];
              request['receiver_email'] = receiverData[0]['email'];
            }
          }
        }
        return myRequests;
      }
      
      return [];
      
    } catch (e) {
      return [];
    }
  }

  // Get all received requests for current user
  static Future<List<Map<String, dynamic>>> getReceivedRequests() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (userData == null) {
        final userByEmail = await SupabaseHandler.getData(
          table: 'users',
          filters: {'email': currentUser.email ?? ''},
        );
        
        if (userByEmail != null && userByEmail.isNotEmpty) {
          final userId = userByEmail[0]['id'].toString();
          final receivedRequests = await SupabaseHandler.getData(
            table: 'merge_requests',
            filters: {'receiver_id': userId},
          );
          return receivedRequests ?? [];
        }
        return [];
      }
      
      final userId = userData['id'].toString();
      final receivedRequests = await SupabaseHandler.getData(
        table: 'merge_requests',
        filters: {'receiver_id': userId},
      );
      
      if (receivedRequests != null && receivedRequests.isNotEmpty) {
        for (var request in receivedRequests) {
          final senderId = request['sender_id'];
          if (senderId != null) {
            final senderData = await SupabaseHandler.getData(
              table: 'users',
              filters: {'id': senderId},
            );
            if (senderData != null && senderData.isNotEmpty) {
              request['sender_username'] = senderData[0]['username'];
              request['sender_email'] = senderData[0]['email'];
            }
          }
        }
        return receivedRequests;
      }
      
      return [];
      
    } catch (e) {
      return [];
    }
  }

  // Delete request from database
  static Future<bool> deleteRequest(String requestId) async {
    try {
      // Get request details before deletion
      final requestData = await SupabaseHandler.getData(
        table: 'merge_requests',
        filters: {'id': requestId},
      );
      
      if (requestData == null || requestData.isEmpty) return false;
      
      final senderId = requestData[0]['sender_id'].toString();
      final receiverId = requestData[0]['receiver_id'].toString();
      
      // Get usernames for notification
      final senderData = await SupabaseHandler.getData(
        table: 'users',
        filters: {'id': senderId},
      );
      final receiverData = await SupabaseHandler.getData(
        table: 'users',
        filters: {'id': receiverId},
      );
      
      final senderUsername = senderData?.isNotEmpty == true ? 
          (senderData![0]['username'] ?? senderData[0]['display_name'] ?? 'Unknown User') : 'Unknown User';
      final receiverUsername = receiverData?.isNotEmpty == true ? 
          (receiverData![0]['username'] ?? receiverData[0]['display_name'] ?? 'Unknown User') : 'Unknown User';
      
      // Delete the request
      final success = await SupabaseHandler.deleteData(
        table: 'merge_requests',
        filters: {'id': requestId},
      );
      
      if (success) {
        // Send notification to the other user (receiver gets notified when sender removes)
        try {
          await NotificationService.sendNotification(
            userId: receiverId,
            title: 'Sync Request Removed',
            body: 'Sync request from $senderUsername has been removed.',
            type: 'sync_removed',
            screen: '/favourite',
          );
        } catch (e) {
        }
      }
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // Check connection limit for user
  static Future<bool> checkConnectionLimit(String userId) async {
    try {
      final connections = await SupabaseHandler.getData(
        table: 'merged_accounts',
        filters: {},
      );
      
      if (connections == null) return false;
      
      int connectionCount = 0;
      for (var connection in connections) {
        if (connection['user1_id'].toString() == userId || 
            connection['user2_id'].toString() == userId) {
          connectionCount++;
        }
      }
      
      return connectionCount >= 2;
    } catch (e) {
      return false;
    }
  }

  // Accept request with connection limit check
  static Future<Map<String, dynamic>> acceptRequest(String requestId) async {
    try {
      // Get request details first
      final requestData = await SupabaseHandler.getData(
        table: 'merge_requests',
        filters: {'id': requestId},
      );
      
      if (requestData == null || requestData.isEmpty) {
        return {'success': false, 'error': 'Request not found'};
      }
      
      final receiverId = requestData[0]['receiver_id'].toString();
      
      // Check connection limit for receiver
      final hasReachedLimit = await checkConnectionLimit(receiverId);
      if (hasReachedLimit) {
        return {
          'success': false, 
          'error': 'limit_exceeded',
          'message': 'You have reached your limit of connected experiences. To continue, please remove one connection.'
        };
      }
      
      // Accept the request
      final success = await SupabaseHandler.updateData(
        table: 'merge_requests',
        filters: {'id': requestId},
        data: {'status': 'accepted', 'responded_at': SupabaseHandler.getCurrentTimestamp()},
      );
      
      if (success) {
        final senderId = requestData[0]['sender_id'].toString();
        
        // Add to merged_accounts table
        await SupabaseHandler.insertData(
          table: 'merged_accounts',
          data: {
            'user1_id': senderId,
            'user2_id': receiverId,
            'merged_at': SupabaseHandler.getCurrentTimestamp(),
          },
        );
        
        // Show merge start notification
        
        // Merge favorites into connected_fav table
        final mergeResult = await _mergeFavoritesToSharedWithToast(senderId, receiverId);
        
        // Show merge completion toast based on result
        if (mergeResult['success'] && mergeResult['count'] > 0) {
          // Success with merged favorites
        } else if (mergeResult['success'] && mergeResult['count'] == 0) {
          // Success but no favorites to merge
        } else {
          // Merge had issues
        }
        
        // Send notification to sender about acceptance
        try {
          await NotificationService.sendNotification(
            userId: senderId,
            title: 'Sync Request Accepted',
            body: 'Your favorites have been synced successfully!',
            type: 'sync_accepted',
            screen: '/favourite',
            extraData: {'request_id': requestId},
          );
        } catch (e) {
        }
        
        return {
          'success': success, 
          'merge_count': mergeResult['success'] ? mergeResult['count'] : 0,
          'merge_error': mergeResult['success'] ? null : mergeResult['error']
        };
      } else {
        return {'success': false, 'error': 'Failed to accept request', 'merge_count': 0};
      }
    } catch (e) {
      return {'success': false, 'error': 'Unknown error occurred', 'merge_count': 0};
    }
  }

  // Disconnect users (for accepted requests)
  static Future<bool> disconnectUsers(String requestId) async {
    try {
      // Get request details
      final requestData = await SupabaseHandler.getData(
        table: 'merge_requests',
        filters: {'id': requestId},
      );
      
      if (requestData == null || requestData.isEmpty) return false;
      
      final senderId = requestData[0]['sender_id'].toString();
      final receiverId = requestData[0]['receiver_id'].toString();
      
      // Delete from merged_accounts
      await SupabaseHandler.deleteData(
        table: 'merged_accounts',
        filters: {
          'user1_id': senderId,
          'user2_id': receiverId,
        },
      );
      
      // Also try reverse order
      await SupabaseHandler.deleteData(
        table: 'merged_accounts',
        filters: {
          'user1_id': receiverId,
          'user2_id': senderId,
        },
      );
      
      // Delete from merge_requests
      await SupabaseHandler.deleteData(
        table: 'merge_requests',
        filters: {'id': requestId},
      );
      
      // Clean connected_fav between these users only
      await cleanupConnectedFavorites(senderId, receiverId);
      
      // Get usernames for notifications
      final senderData = await SupabaseHandler.getData(
        table: 'users',
        filters: {'id': senderId},
      );
      final receiverData = await SupabaseHandler.getData(
        table: 'users',
        filters: {'id': receiverId},
      );
      
      final senderUsername = senderData?.isNotEmpty == true ? 
          (senderData![0]['username'] ?? senderData[0]['display_name'] ?? 'Unknown User') : 'Unknown User';
      final receiverUsername = receiverData?.isNotEmpty == true ? 
          (receiverData![0]['username'] ?? receiverData[0]['display_name'] ?? 'Unknown User') : 'Unknown User';
      
      // Send disconnect notification to both users
      try {
        await NotificationService.sendNotification(
          userId: senderId,
          title: 'Sync Disconnected',
          body: 'Your favorites sync has been disconnected with $receiverUsername.',
          type: 'sync_disconnected',
          screen: '/favourite',
        );
        
        await NotificationService.sendNotification(
          userId: receiverId,
          title: 'Sync Disconnected', 
          body: 'Your favorites sync has been disconnected with $senderUsername.',
          type: 'sync_disconnected',
          screen: '/favourite',
        );
        
      } catch (e) {
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Clean connected favorites between specific users
  static Future<void> cleanupConnectedFavorites(String user1Id, String user2Id) async {
    try {
      // Remove connected favorites between these two users only
      await SupabaseHandler.deleteData(
        table: 'connected_fav',
        filters: {
          'user1_id': user1Id,
          'user2_id': user2Id,
        },
      );
      
      // Also try reverse order
      await SupabaseHandler.deleteData(
        table: 'connected_fav',
        filters: {
          'user1_id': user2Id,
          'user2_id': user1Id,
        },
      );
    } catch (e) {
      // Silent cleanup - don't expose database errors in production
    }
  }

  // Reject request
  static Future<bool> rejectRequest(String requestId) async {
    try {
      final success = await SupabaseHandler.updateData(
        table: 'merge_requests',
        filters: {'id': requestId},
        data: {'status': 'rejected', 'responded_at': SupabaseHandler.getCurrentTimestamp()},
      );
      return success;
    } catch (e) {
      return false;
    }
  }
  static bool isRequestExpired(String createdAt) {
    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(created);
      return difference.inHours >= 24;
    } catch (e) {
      return false;
    }
  }

  // Get request status with expiry check
  static String getRequestStatus(Map<String, dynamic> request) {
    final status = request['status'] as String? ?? 'pending';
    final createdAt = request['created_at'] as String?;
    
    if (status == 'pending' && createdAt != null && isRequestExpired(createdAt)) {
      return 'expired';
    }
    return status;
  }

  // Get status color for UI
  static Color getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.blue;
    }
  }
  
  // Get status icon for UI
  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'expired':
        return Icons.access_time;
      case 'pending':
      default:
        return Icons.schedule;
    }
  }
  
  // Get status display text
  static String getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  // Show expired toast (only once per request)
  static Future<void> showExpiredToast(BuildContext context, String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shownRequests = prefs.getStringList(_expiredRequestsKey) ?? [];
      
      if (!shownRequests.contains(requestId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(child: Text('Request expired after 24 hours')),
                TextButton(
                  onPressed: () async {
                    shownRequests.add(requestId);
                    await prefs.setStringList(_expiredRequestsKey, shownRequests);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  child: const Text('Don\'t show again', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
    }
  }

  // Show expired dialog
  static Future<void> showExpiredDialog(BuildContext context, String recipientName) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'You\'re Late Dear!',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your sync request to $recipientName has expired. Requests are valid for 24 hours only.',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.orange[600])),
          ),
        ],
      ),
    );
  }

  // Handle expired request interaction
  static Future<void> handleExpiredRequest(
    BuildContext context, 
    Map<String, dynamic> request
  ) async {
    final requestId = request['id'].toString();
    final receiverName = request['receiver_username']?.toString() ?? 
                        request['receiver_email']?.toString() ?? 
                        'Unknown User';
    
    // Show toast first (only once)
    await showExpiredToast(context, requestId);
    
    // Show dialog for user interaction
    await showExpiredDialog(context, receiverName);
  }

  // Clear expired request notifications (for settings)
  static Future<void> clearExpiredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expiredRequestsKey);
  }

  // Test method to create dummy requests (for testing only)
  static Future<bool> createTestRequest() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return false;
      }
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (userData == null) {
        return false;
      }
      
      
      // Use the sendSyncRequest method from SupabaseHandler
      final success = await SupabaseHandler.sendSyncRequest(
        senderId: userData['id'],
        receiverId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        senderUsername: userData['username'] ?? 'Test User',
      );
      
      return success;
    } catch (e) {
      return false;
    }
  }

  // Merge both users' favorites into connected_fav table (no duplicates) - production ready
  static Future<Map<String, dynamic>> _mergeFavoritesToSharedWithToast(String user1Id, String user2Id) async {
    try {
      // Get both users' PRIVATE favorites only (is_public=false)
      final user1Favorites = await SupabaseHandler.getData(
        table: 'favorites',
        filters: {'user_id': user1Id, 'is_public': false},
      ) ?? [];
      final user2Favorites = await SupabaseHandler.getData(
        table: 'favorites',
        filters: {'user_id': user2Id, 'is_public': false},
      ) ?? [];
      
      final totalFavorites = user1Favorites.length + user2Favorites.length;
      
      if (totalFavorites == 0) {
        return {'success': true, 'count': 0, 'message': 'No private favorites to merge'};
      }
      
      // Combine and deduplicate by anime_id
      final Map<String, Map<String, dynamic>> uniqueFavorites = {};
      
      // Add both users' private favorites
      for (final fav in [...user1Favorites, ...user2Favorites]) {
        final animeId = fav['anime_id']?.toString();
        if (animeId != null && animeId.isNotEmpty) {
          uniqueFavorites[animeId] = fav;
        }
      }
      
      // Insert unique favorites into connected_fav table
      int successCount = 0;
      for (final fav in uniqueFavorites.values) {
        try {
          await SupabaseHandler.insertData(
            table: 'connected_fav',
            data: {
              'user1_id': user1Id,
              'user2_id': user2Id,
              'anime_id': fav['anime_id'],
              'anime_title': fav['anime_title'],
              'anime_image': fav['anime_image'],
              'added_at': SupabaseHandler.getCurrentTimestamp(),
              'added_by_user_id': fav['user_id'],
            },
          );
          successCount++;
        } catch (e) {
          // Continue processing other favorites even if one fails
          continue;
        }
      }
      
      return {
        'success': true,
        'count': successCount,
        'total': uniqueFavorites.length,
        'message': 'Successfully merged $successCount favorites'
      };
    } catch (e) {
      return {'success': false, 'error': 'Connection failed', 'count': 0};
    }
  }

  // Test merge function directly for debugging
  static Future<Map<String, dynamic>> testMergeFavoritesDirectly(String user1Id, String user2Id) async {
    
    try {
      // Get both users' PRIVATE favorites only (is_public=false)
      final user1Favorites = await SupabaseHandler.getData(
        table: 'favorites',
        filters: {'user_id': user1Id, 'is_public': false},
      ) ?? [];
      final user2Favorites = await SupabaseHandler.getData(
        table: 'favorites',
        filters: {'user_id': user2Id, 'is_public': false},
      ) ?? [];
      
      for (var fav in user1Favorites) {
      }
      
      for (var fav in user2Favorites) {
      }
      
      final totalFavorites = user1Favorites.length + user2Favorites.length;
      
      if (totalFavorites == 0) {
        return {'success': false, 'error': 'No private favorites found', 'count': 0};
      }
      
      // Combine and deduplicate by anime_id
      final Map<String, Map<String, dynamic>> uniqueFavorites = {};
      
      // Add both users' private favorites
      for (final fav in [...user1Favorites, ...user2Favorites]) {
        final animeId = fav['anime_id']?.toString();
        if (animeId != null && animeId.isNotEmpty) {
          uniqueFavorites[animeId] = fav;
        }
      }
      
      
      return {
        'success': true,
        'count': uniqueFavorites.length,
        'total': totalFavorites,
        'message': 'Found ${uniqueFavorites.length} unique private favorites to merge',
        'favorites': uniqueFavorites.values.map((f) => f['anime_title']).toList()
      };
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'count': 0};
    }
  }

  // Original merge function for backward compatibility
  static Future<void> _mergeFavoritesToShared(String user1Id, String user2Id) async {
    try {
      
      // Get both users' PRIVATE favorites only (is_public=false)
      final user1Favorites = await SupabaseHandler.getData(
        table: 'favorites',
        filters: {'user_id': user1Id, 'is_public': false},
      ) ?? [];
      final user2Favorites = await SupabaseHandler.getData(
        table: 'favorites',
        filters: {'user_id': user2Id, 'is_public': false},
      ) ?? [];
      
      
      // Combine and deduplicate by anime_id
      final Map<String, Map<String, dynamic>> uniqueFavorites = {};
      
      // Add user1's private favorites
      for (final fav in user1Favorites) {
        final animeId = fav['anime_id']?.toString();
        if (animeId != null && animeId.isNotEmpty) {
          uniqueFavorites[animeId] = fav;
        }
      }
      
      // Add user2's private favorites (will overwrite if same anime_id)
      for (final fav in user2Favorites) {
        final animeId = fav['anime_id']?.toString();
        if (animeId != null && animeId.isNotEmpty) {
          uniqueFavorites[animeId] = fav;
        }
      }
      
      
      // Insert unique favorites into connected_fav table
      for (final fav in uniqueFavorites.values) {
        try {
          await SupabaseHandler.insertData(
            table: 'connected_fav',
            data: {
              'user1_id': user1Id,
              'user2_id': user2Id,
              'anime_id': fav['anime_id'],
              'anime_title': fav['anime_title'],
              'anime_image': fav['anime_image'],
              'added_at': SupabaseHandler.getCurrentTimestamp(),
              'added_by_user_id': fav['user_id'], // Track who originally added it
            },
          );
        } catch (e) {
          // Continue processing other favorites even if one fails
          continue;
        }
      }
      
    } catch (e) {
    }
  }
}
