import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../screens/auth/handler/supabase.dart';
import '../models/notification_model.dart';
import 'local_notification_handler.dart';
import '../../main.dart'; // For navigatorKey and MainScreen

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
      
      // Handle app launch from notification (when app was completely closed)
      await _handleInitialMessage();
      
      print('FCM initialized successfully');
    } catch (e) {
      print('FCM initialization error: $e');
    }
  }
  
  // Handle app launch from notification
  static Future<void> _handleInitialMessage() async {
    try {
      // Check if app was opened from a notification
      final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      
      if (initialMessage != null) {
        print('App launched from notification: ${initialMessage.messageId}');
        
        // Handle the notification tap after a short delay to ensure app is ready
        Future.delayed(Duration(milliseconds: 1000), () {
          _handleNotificationTap(initialMessage);
        });
      }
    } catch (e) {
      print('Handle initial message error: $e');
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
      
      print('Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      print('Permission request error: $e');
    }
  }
  
  // Get and store FCM token
  static Future<String?> _getFCMToken() async {
    try {
      _currentToken = await _firebaseMessaging.getToken();
      
      if (_currentToken != null) {
        print('FCM Token: $_currentToken');
        await _storeFCMToken(_currentToken!);
      }
      
      return _currentToken;
    } catch (e) {
      print('Get FCM token error: $e');
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
      
      print('FCM token stored successfully');
    } catch (e) {
      print('Store FCM token error: $e');
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
      print('Foreground message received: ${message.messageId}');
      
      // Show local notification
      await LocalNotificationHandler.showNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? '',
        data: message.data,
      );
      
      // Store notification in database
      await _storeNotification(message);
    } catch (e) {
      print('Handle foreground message error: $e');
    }
  }
  
  // Handle background messages (app is closed/background)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      print('Background message received: ${message.messageId}');
      
      // Store notification in database
      await _storeNotification(message);
    } catch (e) {
      print('Handle background message error: $e');
    }
  }
  
  // Handle notification tap
  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    try {
      print('Notification tapped: ${message.messageId}');
      
      // Handle different notification types
      final notificationType = message.data['type'] ?? '';
      
      switch (notificationType) {
        case NotificationModel.mergeRequest:
          // Navigate to merge requests page
          _handleMergeRequestTap(message.data);
          break;
        case NotificationModel.mergeAccepted:
        case NotificationModel.mergeRejected:
          // Navigate to favorites page
          _handleMergeResponseTap(message.data);
          break;
        default:
          // Default navigation
          break;
      }
    } catch (e) {
      print('Handle notification tap error: $e');
    }
  }
  
  // Handle merge request notification tap
  static void _handleMergeRequestTap(Map<String, dynamic> data) {
    try {
      final requestId = data['request_id'] ?? '';
      final senderUsername = data['sender_username'] ?? '';
      
      print('Navigate to merge request: $requestId from $senderUsername');
      
      // Navigate to sync user page or profile page
      if (senderUsername.isNotEmpty) {
        _navigateToPage('/profile/$senderUsername');
      } else {
        _navigateToPage('/sync');
      }
    } catch (e) {
      print('Handle merge request tap error: $e');
    }
  }
  
  // Handle merge response notification tap
  static void _handleMergeResponseTap(Map<String, dynamic> data) {
    try {
      final status = data['status'] ?? '';
      print('Navigate to favorites page - merge $status');
      
      // Navigate to favorites page
      _navigateToPage('/favorites');
    } catch (e) {
      print('Handle merge response tap error: $e');
    }
  }
  
  // Generic navigation helper
  static void _navigateToPage(String route) {
    try {
      // Get current context from navigator key
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Navigate based on route
        switch (route) {
          case '/favorites':
            // Navigate to main screen and switch to favorites tab (index 2)
            Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
            // Switch to favorites tab after navigation
            Future.delayed(Duration(milliseconds: 500), () {
              _switchToTab(2); // Favorites tab index
            });
            break;
          case '/sync':
            // Navigate to main screen and switch to profile tab (index 3)
            Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
            Future.delayed(Duration(milliseconds: 500), () {
              _switchToTab(3); // Profile tab index
            });
            break;
          default:
            if (route.startsWith('/profile/')) {
              // Navigate to main screen and switch to profile tab
              Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
              Future.delayed(Duration(milliseconds: 500), () {
                _switchToTab(3); // Profile tab index
              });
            } else {
              // Default: navigate to home
              Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
            }
            break;
        }
      } else {
        print('No context available for navigation');
      }
    } catch (e) {
      print('Navigation error: $e');
    }
  }
  
  // Helper method to switch tabs in MainScreen
  static void _switchToTab(int tabIndex) {
    try {
      Future.delayed(Duration(milliseconds: 100), () {
        // Call MainScreen's static method to switch tabs
        MainScreen.switchToTab(tabIndex);
        print('Switched to tab: $tabIndex');
      });
    } catch (e) {
      print('Tab switch error: $e');
    }
  }
  
  // Handle token refresh
  static Future<void> _onTokenRefresh(String newToken) async {
    try {
      print('FCM token refreshed: $newToken');
      _currentToken = newToken;
      await _storeFCMToken(newToken);
    } catch (e) {
      print('Token refresh error: $e');
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
      print('Store notification error: $e');
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
      print('Refresh token error: $e');
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
      print('Deactivate token error: $e');
    }
  }
}

// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  await FirebaseMessagingHandler._handleBackgroundMessage(message);
}
