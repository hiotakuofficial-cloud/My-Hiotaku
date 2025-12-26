import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/handler/supabase.dart';

class NotificationUserHandler {
  
  /// Get notifications for current user using Supabase UUID
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];
      
      // Get user data from Supabase using Firebase UID
      final userData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (userData == null) return [];
      
      // Use Supabase UUID (not Firebase UID) for notifications
      final supabaseUserId = userData['id'].toString();
      
      // Get user-specific notifications using Supabase UUID
      final userNotifications = await SupabaseHandler.getData(
        table: 'notifications',
        filters: {'user_id': supabaseUserId},
      ) ?? [];
      
      // Sort by created_at (newest first)
      userNotifications.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      
      return userNotifications;
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
  
  /// Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      return await SupabaseHandler.deleteData(
        table: 'notifications',
        filters: {'id': notificationId},
      );
    } catch (e) {
      return false;
    }
  }
}
