import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/handler/supabase.dart';

class RequestsHandler {
  static const String _expiredRequestsKey = 'expired_requests_shown';
  
  // Get all sent requests for current user
  static Future<List<Map<String, dynamic>>> getSentRequests() async {
    try {
      final currentUser = SupabaseHandler.getCurrentUser();
      if (currentUser == null) return [];
      
      final response = await SupabaseHandler.supabase
          .from('sync_requests')
          .select('*, profiles!sync_requests_to_user_id_fkey(display_name, email)')
          .eq('from_user_id', currentUser.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
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
    final recipientName = request['profiles']?['display_name'] ?? 'Unknown User';
    
    // Show toast first (only once)
    await showExpiredToast(context, requestId);
    
    // Show dialog for user interaction
    await showExpiredDialog(context, recipientName);
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
}
