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
        print('No Firebase user logged in');
        return [];
      }
      
      print('Firebase user: ${currentUser.uid}');
      
      // Get user data from Supabase
      final userData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (userData == null) {
        print('No Supabase user found for Firebase UID: ${currentUser.uid}');
        return [];
      }
      
      print('Supabase user found: ${userData['id']}');
      
      // Get requests from merge_requests table
      final response = await SupabaseHandler.getData(
        table: 'merge_requests',
        filters: {'sender_id': userData['id']},
      );
      
      print('Found ${response?.length ?? 0} requests');
      if (response != null && response.isNotEmpty) {
        print('First request: ${response[0]}');
      }
      
      // Sort by created_at descending
      final sortedResponse = response ?? [];
      sortedResponse.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      return sortedResponse;
    } catch (e) {
      print('Error fetching sent requests: $e');
      return [];
    }
  }
  
  // Check if request is expired (24 hours)
  static bool isRequestExpired(String createdAt) {
    try {
      final createdTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(createdTime);
      return difference.inHours >= 24;
    } catch (e) {
      return false;
    }
  }
  
  // Get request status with expiry check
  static String getRequestStatus(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final createdAt = request['created_at'] as String;
    
    if (status == 'pending' && isRequestExpired(createdAt)) {
      return 'expired';
    }
    return status;
  }
  
  // Show expired request dialog
  static Future<void> showExpiredDialog(BuildContext context, String recipientName) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.access_time, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'You\'re Late Dear!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your sync request to $recipientName has expired.',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sync requests expire after 24 hours for security.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it!',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Show expired toast and mark as shown
  static Future<void> showExpiredToast(BuildContext context, String requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final shownExpired = prefs.getStringList(_expiredRequestsKey) ?? [];
    
    // Don't show if already shown for this request
    if (shownExpired.contains(requestId)) return;
    
    // Show toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.schedule, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Request expired after 24 hours',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
    
    // Mark as shown
    shownExpired.add(requestId);
    await prefs.setStringList(_expiredRequestsKey, shownExpired);
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
  
  // Clear expired request notifications (for settings)
  static Future<void> clearExpiredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_expiredRequestsKey);
  }
  
  // Send notification for sync request status updates
  static Future<void> sendSyncStatusNotification({
    required String userId,
    required String status,
    String? recipientName,
  }) async {
    try {
      String title;
      String body;
      
      switch (status) {
        case 'accepted':
          title = 'Accounts Synced';
          body = 'The user accepted your sync request. You can now access shared favourites.';
          break;
        case 'rejected':
          title = 'Sync Request Update';
          body = 'Your sync request was not accepted.';
          break;
        case 'expired':
        case 'no_response':
          title = 'Sync Request Update';
          body = 'The user did not respond to your sync request.';
          break;
        default:
          return; // Don't send notification for unknown status
      }
      
      final success = await NotificationService.sendNotification(
        userId: userId,
        title: title,
        body: body,
        type: 'sync_status_update',
        screen: '/profile/requests',
        extraData: {
          'status': status,
          'recipient_name': recipientName ?? 'Unknown User',
        },
      );
      
      if (success) {
        print('Sync status notification sent: $status to $userId');
      } else {
        print('Failed to send sync status notification: $status');
      }
    } catch (e) {
      print('Error sending sync status notification: $e');
    }
  }
  
  // Check and notify for status changes
  static Future<void> checkAndNotifyStatusChanges() async {
    try {
      final requests = await getSentRequests();
      final prefs = await SharedPreferences.getInstance();
      const String lastStatusKey = 'last_request_status';
      
      for (final request in requests) {
        final requestId = request['id'].toString();
        final currentStatus = getRequestStatus(request);
        final lastStatus = prefs.getString('${lastStatusKey}_$requestId');
        
        // If status changed, send notification
        if (lastStatus != null && lastStatus != currentStatus) {
          final recipientName = request['profiles']?['display_name'] ?? 'Unknown User';
          
          await sendSyncStatusNotification(
            userId: request['from_user_id'],
            status: currentStatus,
            recipientName: recipientName,
          );
        }
        
        // Update last known status
        await prefs.setString('${lastStatusKey}_$requestId', currentStatus);
      }
    } catch (e) {
      print('Error checking status changes: $e');
    }
  }
  
  // Initialize status tracking for new request
  static Future<void> initializeRequestTracking(String requestId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_request_status_$requestId', status);
    } catch (e) {
      print('Error initializing request tracking: $e');
    }
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
      
      final testRequest = await SupabaseHandler.insertData(
        table: 'merge_requests',
        data: {
          'sender_id': userData['id'],
          'receiver_id': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
          'message': 'Test sync request created at ${DateTime.now()}',
        },
      );
      
      print('Test request result: $testRequest');
      return testRequest != null;
    } catch (e) {
      print('Error creating test request: $e');
      return false;
    }
  }
}
