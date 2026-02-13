import 'package:firebase_auth/firebase_auth.dart';
import '../../screens/auth/handler/supabase.dart';
import '../models/notification_model.dart';
import 'firebase_messaging_handler.dart';
import 'local_notification_handler.dart';

class NotificationHandler {
  
  // Initialize notification system
  static Future<void> initialize() async {
    try {
      // Initialize Firebase Messaging
      await FirebaseMessagingHandler.initialize();
      
      // Initialize Local Notifications
      await LocalNotificationHandler.initialize();
      
    } catch (e) {
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
      // Get receiver's FCM tokens
      final tokens = await _getUserFCMTokens(receiverUserId);
      if (tokens.isEmpty) return false;
      
      // Create notification
      final notification = NotificationModel.createMergeRequest(
        requestId: requestId,
        senderName: senderName,
        senderUsername: senderUsername,
      );
      
      // Store notification in database
      await _storeNotification(receiverUserId, notification);
      
      // Send FCM notification (would need server-side implementation)
      // For now, just return true
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Send merge accepted notification
  static Future<bool> sendMergeAcceptedNotification({
    required String senderUserId,
    required String receiverName,
    required String receiverUsername,
  }) async {
    try {
      final tokens = await _getUserFCMTokens(senderUserId);
      if (tokens.isEmpty) return false;
      
      final notification = NotificationModel.createMergeAccepted(
        receiverName: receiverName,
        receiverUsername: receiverUsername,
      );
      
      await _storeNotification(senderUserId, notification);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Send merge rejected notification
  static Future<bool> sendMergeRejectedNotification({
    required String senderUserId,
    required String receiverName,
    required String receiverUsername,
  }) async {
    try {
      final tokens = await _getUserFCMTokens(senderUserId);
      if (tokens.isEmpty) return false;
      
      final notification = NotificationModel.createMergeRejected(
        receiverName: receiverName,
        receiverUsername: receiverUsername,
      );
      
      await _storeNotification(senderUserId, notification);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get user notifications
  static Future<List<NotificationModel>> getUserNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return [];
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return [];
      
      final notifications = await SupabaseHandler.getData(
        table: 'notifications',
        filters: {'user_id': userData['id']},
      );
      
      if (notifications == null) return [];
      
      return notifications
          .map((json) => NotificationModel.fromJson(json))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      return [];
    }
  }
  
  // Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      return await SupabaseHandler.updateData(
        table: 'notifications',
        data: {'is_read': true},
        filters: {'id': notificationId},
      );
    } catch (e) {
      return false;
    }
  }
  
  // Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return 0;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
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
      return 0;
    }
  }
  
  // Clear all notifications
  static Future<bool> clearAllNotifications() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return false;
      
      return await SupabaseHandler.updateData(
        table: 'notifications',
        data: {'is_read': true},
        filters: {'user_id': userData['id']},
      );
    } catch (e) {
      return false;
    }
  }
  
  // Get user's FCM tokens
  static Future<List<String>> _getUserFCMTokens(String userId) async {
    try {
      final tokens = await SupabaseHandler.getData(
        table: 'fcm_tokens',
        filters: {
          'user_id': userId,
          'is_active': true,
        },
      );
      
      if (tokens == null) return [];
      
      return tokens
          .map((token) => token['fcm_token']?.toString())
          .where((token) => token != null)
          .cast<String>()
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Store notification in database
  static Future<void> _storeNotification(String userId, NotificationModel notification) async {
    try {
      await SupabaseHandler.insertData(
        table: 'notifications',
        data: {
          'user_id': userId,
          'title': notification.title,
          'body': notification.body,
          'type': notification.type,
          'data': notification.data,
          'is_read': false,
          'is_sent': false,
        },
      );
    } catch (e) {
    }
  }
}
