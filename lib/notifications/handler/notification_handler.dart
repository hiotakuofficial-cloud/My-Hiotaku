import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/auth/handler/supabase.dart';
import '../models/notification_model.dart';
import 'firebase_messaging_handler.dart';
import 'local_notification_handler.dart';

class NotificationHandler {
  static RealtimeChannel? _notificationSubscription;
  
  // Initialize notification system
  static Future<void> initialize() async {
    try {
      // Initialize Firebase Messaging
      await FirebaseMessagingHandler.initialize();
      
      // Initialize Local Notifications
      await LocalNotificationHandler.initialize();
      
      print('Notification system initialized');
    } catch (e) {
      print('Notification initialization error: $e');
    }
  }
  
  // Subscribe to real-time notifications
  static RealtimeChannel subscribeToNotifications({
    required Function(List<Map<String, dynamic>>) onNotifications,
  }) {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) throw Exception('User not authenticated');
    
    _notificationSubscription?.unsubscribe();
    
    _notificationSubscription = SupabaseHandler.subscribeToTable(
      table: 'notifications',
      onData: (payload) async {
        // Get user data first
        final userData = await _getUserByFirebaseUID(firebaseUser.uid);
        if (userData != null) {
          // Refresh notifications when any change occurs
          final notifications = await getUserNotifications();
          onNotifications(notifications);
        }
      },
    );
    
    return _notificationSubscription!;
  }
  
  // Get user notifications
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return [];
      
      final userData = await _getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return [];
      
      final notifications = await SupabaseHandler.getData(
        table: 'notifications',
        filters: {'user_id': userData['id']},
        orderBy: 'created_at',
        ascending: false,
        limit: 50,
      );
      
      return notifications ?? [];
    } catch (e) {
      print('Get notifications error: $e');
      return [];
    }
  }
  
  // Send merge request notification
  static Future<bool> sendMergeRequestNotification({
    required String receiverUserId,
    required String senderName,
    required String senderUsername,
    required String requestId,
  }) async {
    try {
      // Create notification
      final notification = NotificationModel.createMergeRequest(
        requestId: requestId,
        senderName: senderName,
        senderUsername: senderUsername,
      );
      
      // Store notification in database
      final success = await _storeNotification(receiverUserId, notification);
      
      return success;
    } catch (e) {
      print('Send merge request notification error: $e');
      return false;
    }
  }
  
  // Store notification in database
  static Future<bool> _storeNotification(String userId, NotificationModel notification) async {
    try {
      final result = await SupabaseHandler.insertData(
        table: 'notifications',
        data: {
          'user_id': userId,
          'type': notification.type,
          'title': notification.title,
          'message': notification.message,
          'data': notification.data,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      return result != null;
    } catch (e) {
      print('Store notification error: $e');
      return false;
    }
  }
  
  // Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final success = await SupabaseHandler.updateData(
        table: 'notifications',
        data: {'is_read': true},
        filters: {'id': notificationId},
      );
      
      return success;
    } catch (e) {
      print('Mark as read error: $e');
      return false;
    }
  }
  
  // Mark all notifications as read
  static Future<bool> markAllAsRead() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await _getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      final success = await SupabaseHandler.updateData(
        table: 'notifications',
        data: {'is_read': true},
        filters: {'user_id': userData['id']},
      );
      
      return success;
    } catch (e) {
      print('Mark all as read error: $e');
      return false;
    }
  }
  
  // Delete notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final success = await SupabaseHandler.deleteData(
        table: 'notifications',
        filters: {'id': notificationId},
      );
      
      return success;
    } catch (e) {
      print('Delete notification error: $e');
      return false;
    }
  }
  
  // Get unread notifications count
  static Future<int> getUnreadCount() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return 0;
      
      final userData = await _getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return 0;
      
      final notifications = await SupabaseHandler.getData(
        table: 'notifications',
        filters: {
          'user_id': userData['id'],
          'is_read': false,
        },
      );
      
      return notifications?.length ?? 0;
    } catch (e) {
      print('Get unread count error: $e');
      return 0;
    }
  }
  
  // Helper method to get user by Firebase UID
  static Future<Map<String, dynamic>?> _getUserByFirebaseUID(String firebaseUID) async {
    try {
      final result = await SupabaseHandler.getData(
        table: 'users',
        filters: {'firebase_uid': firebaseUID},
        limit: 1,
      );
      
      return result != null && result.isNotEmpty ? result.first : null;
    } catch (e) {
      print('Get user by Firebase UID error: $e');
      return null;
    }
  }
  
  // Cleanup subscriptions
  static void dispose() {
    _notificationSubscription?.unsubscribe();
    _notificationSubscription = null;
  }
}
