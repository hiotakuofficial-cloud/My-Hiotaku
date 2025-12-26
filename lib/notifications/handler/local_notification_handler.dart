import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Required for Color class
import 'dart:convert';

class LocalNotificationHandler {
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  
  // Initialize local notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Android initialization settings
      const AndroidInitializationSettings androidSettings = 
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const DarwinInitializationSettings iosSettings = 
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      // Combined initialization settings
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      // Initialize with settings
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      
      // Create notification channels for Android
      await _createNotificationChannels();
      
      _isInitialized = true;
    } catch (e) {
    }
  }
  
  // Create notification channels
  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel mergeRequestChannel = AndroidNotificationChannel(
      'merge_requests',
      'Merge Requests',
      description: 'Notifications for merge requests',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
      'general',
      'General',
      description: 'General notifications',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
        FlutterLocalNotificationsPlugin();
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(mergeRequestChannel);
        
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);
  }
  
  // Show notification
  static Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int id = 0,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      // Create notification details
      final notificationDetails = NotificationDetails(
        android: _getAndroidDetails(data),
        iOS: _getIOSDetails(),
      );
      
      // Show notification
      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e) {
    }
  }
  
  // Show merge request notification with actions
  static Future<void> showMergeRequestNotification({
    required String title,
    required String body,
    required String requestId,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (!_isInitialized) await initialize();
      
      // Android notification with action buttons
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'merge_requests',
        'Merge Requests',
        channelDescription: 'Notifications for merge requests',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@drawable/ic_notification_statsebar',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: const Color(0xFFFF8C00),
        actions: [
          AndroidNotificationAction(
            'accept_$requestId',
            'Accept',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_check'),
            contextual: true,
          ),
          AndroidNotificationAction(
            'reject_$requestId',
            'Reject',
            icon: DrawableResourceAndroidBitmap('@drawable/ic_close'),
            contextual: true,
          ),
        ],
      );
      
      // iOS notification details
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );
      
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      // Show notification
      await _localNotifications.show(
        requestId.hashCode,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );
    } catch (e) {
    }
  }
  
  // Get Android notification details
  static AndroidNotificationDetails _getAndroidDetails(Map<String, dynamic>? data) {
    final notificationType = data?['type'] ?? 'general';
    
    return AndroidNotificationDetails(
      _getChannelId(notificationType),
      _getChannelName(notificationType),
      channelDescription: _getChannelDescription(notificationType),
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@drawable/ic_notification_statsebar',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFFFF8C00),
    );
  }
  
  // Get iOS notification details
  static DarwinNotificationDetails _getIOSDetails() {
    return const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
    );
  }
  
  // Get channel ID based on notification type
  static String _getChannelId(String type) {
    switch (type) {
      case 'merge_request':
        return 'merge_requests';
      case 'merge_accepted':
      case 'merge_rejected':
        return 'merge_responses';
      default:
        return 'general';
    }
  }
  
  // Get channel name based on notification type
  static String _getChannelName(String type) {
    switch (type) {
      case 'merge_request':
        return 'Merge Requests';
      case 'merge_accepted':
      case 'merge_rejected':
        return 'Merge Responses';
      default:
        return 'General Notifications';
    }
  }
  
  // Get channel description based on notification type
  static String _getChannelDescription(String type) {
    switch (type) {
      case 'merge_request':
        return 'Notifications for incoming merge requests';
      case 'merge_accepted':
      case 'merge_rejected':
        return 'Notifications for merge request responses';
      default:
        return 'General app notifications';
    }
  }
  
  // Handle notification tap
  static void _onNotificationTap(NotificationResponse response) {
    try {
      final payload = response.payload;
      final actionId = response.actionId;
      
      if (payload != null) {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        
        // Handle action buttons
        if (actionId != null) {
          _handleNotificationAction(actionId, data);
        } else {
          // Handle normal tap
          _handleNotificationTap(data);
        }
      }
    } catch (e) {
    }
  }
  
  // Handle notification action (Accept/Reject buttons)
  static void _handleNotificationAction(String actionId, Map<String, dynamic> data) {
    if (actionId.startsWith('accept_')) {
      final requestId = actionId.replaceFirst('accept_', '');
      _handleAcceptAction(requestId, data);
    } else if (actionId.startsWith('reject_')) {
      final requestId = actionId.replaceFirst('reject_', '');
      _handleRejectAction(requestId, data);
    }
  }
  
  // Handle accept action
  static void _handleAcceptAction(String requestId, Map<String, dynamic> data) {
    // TODO: Call merge request accept API
  }
  
  // Handle reject action
  static void _handleRejectAction(String requestId, Map<String, dynamic> data) {
    // TODO: Call merge request reject API
  }
  
  // Handle notification tap
  static void _handleNotificationTap(Map<String, dynamic> data) {
    final notificationType = data['type'] ?? '';
    
    switch (notificationType) {
      case 'merge_request':
        // TODO: Navigate to merge requests page
        break;
      case 'merge_accepted':
      case 'merge_rejected':
        // TODO: Navigate to favorites page
        break;
      default:
        // TODO: Navigate to notifications page
        break;
    }
  }
  
  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
    } catch (e) {
    }
  }
  
  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
    } catch (e) {
    }
  }
  
  // Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      return [];
    }
  }
}
