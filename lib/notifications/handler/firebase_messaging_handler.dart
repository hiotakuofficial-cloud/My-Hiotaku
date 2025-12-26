import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../screens/auth/handler/supabase.dart';
import '../models/notification_model.dart';
import 'local_notification_handler.dart';

class FirebaseMessagingHandler {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static String? _currentToken;
  
  // Initialize FCM
  static Future<void> initialize() async {
    try {
      // Request notification permissions
      await _requestPermissions();
      
      // Get FCM token
      await _getFCMToken();
      
      // Setup message handlers
      _setupMessageHandlers();
      
      // Initialize local notifications
      await LocalNotificationHandler.initialize();
      
    } catch (e) {
    }
  }
  
  // Request notification permissions
  static Future<void> _requestPermissions() async {
    try {
      // Request FCM permissions
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      // Request system permissions (Android)
      if (defaultTargetPlatform == TargetPlatform.android) {
        await Permission.notification.request();
      }
      
    } catch (e) {
    }
  }
  
  // Get and store FCM token
  static Future<String?> _getFCMToken() async {
    try {
      _currentToken = await _firebaseMessaging.getToken();
      
      if (_currentToken != null) {
        await _storeFCMToken(_currentToken!);
      }
      
      return _currentToken;
    } catch (e) {
      return null;
    }
  }
  
  // Store FCM token in Supabase
  static Future<void> _storeFCMToken(String token) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return;
      
      // Check if token already exists
      final existingTokens = await SupabaseHandler.getData(
        table: 'fcm_tokens',
        filters: {'fcm_token': token},
      );
      
      if (existingTokens == null || existingTokens.isEmpty) {
        // Insert new token
        await SupabaseHandler.insertData(
          table: 'fcm_tokens',
          data: {
            'user_id': userData['id'],
            'fcm_token': token,
            'device_type': _getDeviceType(),
            'is_active': true,
            'last_used_at': DateTime.now().toIso8601String(),
          },
        );
      } else {
        // Update existing token
        await SupabaseHandler.updateData(
          table: 'fcm_tokens',
          data: {
            'is_active': true,
            'last_used_at': DateTime.now().toIso8601String(),
          },
          filters: {'fcm_token': token},
        );
      }
      
    } catch (e) {
    }
  }
  
  // Get device type
  static String _getDeviceType() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'android';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'ios';
    } else {
      return 'web';
    }
  }
  
  // Setup message handlers
  static void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Handle token refresh
    _firebaseMessaging.onTokenRefresh.listen(_onTokenRefresh);
  }
  
  // Handle foreground messages (app is active)
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      
      // Show local notification
      await LocalNotificationHandler.showNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        data: message.data,
      );
      
      // Store notification in database
      await _storeNotification(message);
    } catch (e) {
    }
  }
  
  // Handle background messages (app is closed/background)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      
      // Store notification in database
      await _storeNotification(message);
    } catch (e) {
    }
  }
  
  // Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      // Just open the app - no specific navigation needed
    } catch (e) {
    }
  }
  
  // Handle merge request notification tap
  static void _handleMergeRequestTap(Map<String, dynamic> data) {
    // App opens automatically - no navigation needed
  }
  
  // Handle merge response notification tap
  static void _handleMergeResponseTap(Map<String, dynamic> data) {
    // App opens automatically - no navigation needed
  }
  
  // Handle token refresh
  static Future<void> _onTokenRefresh(String newToken) async {
    try {
      _currentToken = newToken;
      await _storeFCMToken(newToken);
    } catch (e) {
    }
  }
  
  // Store notification in database
  static Future<void> _storeNotification(RemoteMessage message) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return;
      
      await SupabaseHandler.insertData(
        table: 'notifications',
        data: {
          'user_id': userData['id'],
          'title': message.notification?.title ?? 'New Notification',
          'body': message.notification?.body ?? '',
          'type': message.data['type'] ?? 'general',
          'data': message.data,
          'is_sent': true,
          'sent_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
    }
  }
  
  // Get current FCM token
  static String? getCurrentToken() {
    return _currentToken;
  }
  
  // Refresh FCM token
  static Future<String?> refreshToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      return await _getFCMToken();
    } catch (e) {
      return null;
    }
  }
  
  // Deactivate current device token
  static Future<void> deactivateToken() async {
    try {
      if (_currentToken == null) return;
      
      await SupabaseHandler.updateData(
        table: 'fcm_tokens',
        data: {'is_active': false},
        filters: {'fcm_token': _currentToken!},
      );
      
      await _firebaseMessaging.deleteToken();
      _currentToken = null;
    } catch (e) {
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await FirebaseMessagingHandler._handleBackgroundMessage(message);
}
