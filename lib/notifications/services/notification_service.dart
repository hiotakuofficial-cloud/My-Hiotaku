import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../handler/notification_handler.dart';
import '../models/notification_model.dart';

class NotificationService {
  static Timer? _periodicTimer;
  static StreamController<int>? _unreadCountController;
  static StreamController<List<NotificationModel>>? _notificationsController;
  
  // Initialize notification service
  static Future<void> initialize() async {
    try {
      // Initialize notification handlers
      await NotificationHandler.initialize();
      
      // Setup stream controllers
      _unreadCountController = StreamController<int>.broadcast();
      _notificationsController = StreamController<List<NotificationModel>>.broadcast();
      
      // Start periodic checks
      _startPeriodicChecks();
      
      // Listen to auth state changes
      FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
      
    } catch (e) {
    }
  }
  
  // Dispose service
  static void dispose() {
    _periodicTimer?.cancel();
    _unreadCountController?.close();
    _notificationsController?.close();
  }
  
  // Get unread count stream
  static Stream<int> get unreadCountStream {
    _unreadCountController ??= StreamController<int>.broadcast();
    return _unreadCountController!.stream;
  }
  
  // Get notifications stream
  static Stream<List<NotificationModel>> get notificationsStream {
    _notificationsController ??= StreamController<List<NotificationModel>>.broadcast();
    return _notificationsController!.stream;
  }
  
  // Refresh notifications
  static Future<void> refreshNotifications() async {
    try {
      // Get latest notifications
      final notifications = await NotificationHandler.getUserNotifications();
      _notificationsController?.add(notifications);
      
      // Get unread count
      final unreadCount = await NotificationHandler.getUnreadCount();
      _unreadCountController?.add(unreadCount);
    } catch (e) {
    }
  }
  
  // Mark notification as read and refresh
  static Future<void> markAsReadAndRefresh(String notificationId) async {
    try {
      await NotificationHandler.markAsRead(notificationId);
      await refreshNotifications();
    } catch (e) {
    }
  }
  
  // Clear all notifications and refresh
  static Future<void> clearAllAndRefresh() async {
    try {
      await NotificationHandler.clearAllNotifications();
      await refreshNotifications();
    } catch (e) {
    }
  }
  
  // Send merge request notification
  static Future<bool> sendMergeRequest({
    required String receiverUserId,
    required String senderName,
    required String senderUsername,
    required String requestId,
  }) async {
    return await NotificationHandler.sendMergeRequestNotification(
      receiverUserId: receiverUserId,
      senderName: senderName,
      senderUsername: senderUsername,
      requestId: requestId,
    );
  }
  
  // Send merge response notifications
  static Future<bool> sendMergeResponse({
    required String senderUserId,
    required String receiverName,
    required String receiverUsername,
    required bool isAccepted,
  }) async {
    if (isAccepted) {
      return await NotificationHandler.sendMergeAcceptedNotification(
        senderUserId: senderUserId,
        receiverName: receiverName,
        receiverUsername: receiverUsername,
      );
    } else {
      return await NotificationHandler.sendMergeRejectedNotification(
        senderUserId: senderUserId,
        receiverName: receiverName,
        receiverUsername: receiverUsername,
      );
    }
  }
  
  // Start periodic checks for notifications
  static void _startPeriodicChecks() {
    _periodicTimer = Timer.periodic(Duration(minutes: 5), (timer) {
      refreshNotifications();
    });
  }
  
  // Handle auth state changes
  static void _onAuthStateChanged(User? user) {
    if (user != null) {
      // User logged in - refresh notifications
      refreshNotifications();
    } else {
      // User logged out - clear streams
      _unreadCountController?.add(0);
      _notificationsController?.add([]);
    }
  }
  
  // Handle notification tap from system
  static Future<void> handleNotificationTap(Map<String, dynamic> data) async {
    try {
      final notificationType = data['type'] ?? '';
      final notificationId = data['notification_id'];
      
      // Mark as read if notification ID is provided
      if (notificationId != null) {
        await markAsReadAndRefresh(notificationId);
      }
      
      // Handle navigation based on type
      switch (notificationType) {
        case NotificationModel.mergeRequest:
          _navigateToMergeRequests(data);
          break;
        case NotificationModel.mergeAccepted:
        case NotificationModel.mergeRejected:
          _navigateToFavorites(data);
          break;
        default:
          _navigateToNotifications();
          break;
      }
    } catch (e) {
    }
  }
  
  // Navigation helpers
  static void _navigateToMergeRequests(Map<String, dynamic> data) {
    // TODO: Navigate to merge requests page
  }
  
  static void _navigateToFavorites(Map<String, dynamic> data) {
    // TODO: Navigate to favorites page
  }
  
  static void _navigateToNotifications() {
    // TODO: Navigate to notifications page
  }
  
  // Get current unread count (synchronous)
  static Future<int> getCurrentUnreadCount() async {
    return await NotificationHandler.getUnreadCount();
  }
  
  // Get current notifications (synchronous)
  static Future<List<NotificationModel>> getCurrentNotifications() async {
    return await NotificationHandler.getUserNotifications();
  }
}
