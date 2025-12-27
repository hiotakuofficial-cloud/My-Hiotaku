import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'SDK_DB.dart';

class WebSocketService {
  static Timer? _heartbeatTimer;
  static bool _isOnline = false;
  static String? _currentFirebaseUID;
  static String? _currentSupabaseId;
  static bool _isInitialized = false;
  static RealtimeChannel? _userStatusChannel;

  // Initialize WebSocket service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get current Firebase user
      final currentUser = FirebaseAuth.instance.currentUser;
      _currentFirebaseUID = currentUser?.uid;
      
      if (_currentFirebaseUID != null) {
        // Get Supabase UUID from Firebase UID using SDK
        await _getSupabaseUserId();
        
        if (_currentSupabaseId != null) {
          await _setUserOnline();
          _startHeartbeat();
          _listenToAppLifecycle();
          _isInitialized = true;
          debugPrint('WebSocket initialized for user: $_currentSupabaseId');
        }
      }
    } catch (e) {
      debugPrint('WebSocket initialization failed: $e');
    }
  }

  // Get Supabase UUID from Firebase UID
  static Future<void> _getSupabaseUserId() async {
    if (_currentFirebaseUID == null) return;
    
    try {
      final userData = await SupabaseSDK.getUserByFirebaseUID(_currentFirebaseUID!);
      if (userData != null) {
        _currentSupabaseId = userData['id'];
        debugPrint('Found Supabase ID: $_currentSupabaseId');
      }
    } catch (e) {
      debugPrint('Failed to get Supabase user ID: $e');
    }
  }

  // Set user online status
  static Future<void> _setUserOnline() async {
    if (_currentSupabaseId == null) return;
    
    try {
      final success = await SupabaseSDK.updateUserStatus(
        userId: _currentSupabaseId!,
        isOnline: true,
      );
      
      if (success) {
        _isOnline = true;
        debugPrint('User set to online: $_currentSupabaseId');
      }
    } catch (e) {
      debugPrint('Failed to set user online: $e');
    }
  }

  // Set user offline status
  static Future<void> _setUserOffline() async {
    if (_currentSupabaseId == null) return;
    
    try {
      final success = await SupabaseSDK.updateUserStatus(
        userId: _currentSupabaseId!,
        isOnline: false,
      );
      
      if (success) {
        _isOnline = false;
        debugPrint('User set to offline: $_currentSupabaseId');
      }
    } catch (e) {
      debugPrint('Failed to set user offline: $e');
    }
  }

  // Update last seen (heartbeat) - lightweight operation
  static Future<void> _updateHeartbeat() async {
    if (_currentSupabaseId == null || !_isOnline) return;
    
    try {
      // Only update if user is still online to avoid unnecessary writes
      await SupabaseSDK.updateUserStatus(
        userId: _currentSupabaseId!,
        isOnline: true,
      );
    } catch (e) {
      // Silent fail for heartbeat - don't spam logs
    }
  }

  // Start optimized heartbeat timer
  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // 90 second intervals to balance real-time vs performance
    _heartbeatTimer = Timer.periodic(Duration(seconds: 90), (timer) {
      if (_isOnline && _currentSupabaseId != null) {
        _updateHeartbeat();
      }
    });
  }

  // Listen to app lifecycle changes
  static void _listenToAppLifecycle() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  }

  // Check if user is online by Firebase UID
  static Future<bool> isUserOnline(String firebaseUID) async {
    try {
      return await SupabaseSDK.isUserOnline(firebaseUID);
    } catch (e) {
      return false;
    }
  }

  // Subscribe to user status changes
  static RealtimeChannel? subscribeToUserStatus({
    required String firebaseUID,
    required Function(bool isOnline) onStatusChange,
  }) {
    try {
      return SupabaseSDK.subscribeToUserStatus(
        firebaseUID: firebaseUID,
        onStatusChange: onStatusChange,
      );
    } catch (e) {
      debugPrint('Failed to subscribe to user status: $e');
      return null;
    }
  }

  // Cleanup resources
  static Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _userStatusChannel?.unsubscribe();
    await _setUserOffline();
    _isInitialized = false;
    debugPrint('WebSocket service disposed');
  }

  // Getters
  static bool get isOnline => _isOnline;
  static bool get isInitialized => _isInitialized;
  static String? get currentFirebaseUID => _currentFirebaseUID;
  static String? get currentSupabaseId => _currentSupabaseId;
}

// Optimized app lifecycle observer
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // User came back - set online and restart heartbeat
        if (WebSocketService._currentSupabaseId != null) {
          WebSocketService._setUserOnline();
          WebSocketService._startHeartbeat();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // User left - set offline and stop heartbeat
        WebSocketService._setUserOffline();
        WebSocketService._heartbeatTimer?.cancel();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
