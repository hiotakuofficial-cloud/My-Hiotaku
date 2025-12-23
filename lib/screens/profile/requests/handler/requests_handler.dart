import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/handler/supabase.dart';

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
      final success = await SupabaseHandler.deleteData(
        table: 'merge_requests',
        filters: {'id': requestId},
      );
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
      print('Error checking connection limit: $e');
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
        // Add to merged_accounts table
        final senderId = requestData[0]['sender_id'].toString();
        await SupabaseHandler.insertData(
          table: 'merged_accounts',
          data: {
            'user1_id': senderId,
            'user2_id': receiverId,
            'merged_at': SupabaseHandler.getCurrentTimestamp(),
          },
        );
      }
      
      return {'success': success};
    } catch (e) {
      return {'success': false, 'error': 'Unknown error occurred'};
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
      
      // Clean shared_favorites between these users only
      await cleanupSharedFavorites(senderId, receiverId);
      
      return true;
    } catch (e) {
      print('Error disconnecting users: $e');
      return false;
    }
  }

  // Clean shared favorites between specific users
  static Future<void> cleanupSharedFavorites(String user1Id, String user2Id) async {
    try {
      // Remove shared favorites between these two users only
      await SupabaseHandler.deleteData(
        table: 'shared_favorites',
        filters: {
          'user1_id': user1Id,
          'user2_id': user2Id,
        },
      );
      
      // Also try reverse order
      await SupabaseHandler.deleteData(
        table: 'shared_favorites',
        filters: {
          'user1_id': user2Id,
          'user2_id': user1Id,
        },
      );
    } catch (e) {
      print('Error cleaning shared favorites: $e');
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
      print('Error showing expired toast: $e');
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
        print('No Firebase user logged in');
        return false;
      }
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (userData == null) {
        print('No Supabase user found');
        return false;
      }
      
      print('Creating test request for user: ${userData['id']}');
      
      // Use the sendSyncRequest method from SupabaseHandler
      final success = await SupabaseHandler.sendSyncRequest(
        senderId: userData['id'],
        receiverId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        senderUsername: userData['username'] ?? 'Test User',
      );
      
      print('Test request result: $success');
      return success;
    } catch (e) {
      print('Error creating test request: $e');
      return false;
    }
  }
}
