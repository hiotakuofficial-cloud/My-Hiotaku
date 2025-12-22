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
      if (currentUser == null) {
        print('❌ No Firebase user logged in');
        return [];
      }
      
      print('✅ Firebase user: ${currentUser.uid}');
      
      // Get user data from Supabase
      final userData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (userData == null) {
        print('❌ No Supabase user found for Firebase UID: ${currentUser.uid}');
        return [];
      }
      
      print('✅ Supabase user found: ${userData['id']} (${userData['email']})');
      
      // First, get ALL requests to see what's in the table
      final allRequests = await SupabaseHandler.getData(table: 'merge_requests');
      print('📊 Total requests in table: ${allRequests?.length ?? 0}');
      
      if (allRequests != null && allRequests.isNotEmpty) {
        print('📋 Sample request structure: ${allRequests[0]}');
        
        // Check if any requests have our user ID
        final myRequests = allRequests.where((req) => req['sender_id'] == userData['id']).toList();
        print('🎯 My requests found: ${myRequests.length}');
        
        if (myRequests.isNotEmpty) {
          print('📝 My first request: ${myRequests[0]}');
        }
        
        return myRequests;
      }
      
      print('❌ No requests found in table');
      return [];
      
    } catch (e, stackTrace) {
      print('❌ Error in getSentRequests: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  // Check if request is expired (24 hours)
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
    final receiverId = request['receiver_id']?.toString() ?? 'Unknown User';
    
    // Show toast first (only once)
    await showExpiredToast(context, requestId);
    
    // Show dialog for user interaction
    await showExpiredDialog(context, receiverId);
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
