import '../../../auth/handler/supabase.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationOfUserHandler {
  
  /// Get notifications for current user (user-specific + public notifications)
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];
      
      // Get user data from Supabase using Firebase UID
      final userData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (userData == null) return [];
      
      final supabaseUserId = userData['id'].toString();
      
      // Get user-specific notifications
      final userNotifications = await SupabaseHandler.getData(
        table: 'notifications',
        filters: {'user_id': supabaseUserId},
      ) ?? [];
      
      // Get public notifications (for all users)
      final publicNotifications = await SupabaseHandler.getData(
        table: 'notifications',
        filters: {'is_public': true},
      ) ?? [];
      
      // Combine and remove duplicates
      final allNotifications = <Map<String, dynamic>>[];
      final seenIds = <String>{};
      
      for (final notification in [...userNotifications, ...publicNotifications]) {
        final id = notification['id']?.toString();
        if (id != null && !seenIds.contains(id)) {
          seenIds.add(id);
          allNotifications.add(notification);
        }
      }
      
      // Sort by created_at (newest first)
      allNotifications.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      return allNotifications;
    } catch (e) {
      return [];
    }
  }
  
  /// Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      return await SupabaseHandler.updateData(
        table: 'notifications',
        filters: {'id': notificationId},
        data: {'is_read': true},
      );
    } catch (e) {
      return false;
    }
  }
  
  /// Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final notifications = await getUserNotifications();
      return notifications.where((n) => n['is_read'] != true).length;
    } catch (e) {
      return 0;
    }
  }
  
  /// Delete notification (only user's own notifications)
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (userData == null) return false;
      
      final supabaseUserId = userData['id'].toString();
      
      // Only delete if it belongs to current user (not public notifications)
      return await SupabaseHandler.deleteData(
        table: 'notifications',
        filters: {
          'id': notificationId,
          'user_id': supabaseUserId,
        },
      );
    } catch (e) {
      return false;
    }
  }
}
