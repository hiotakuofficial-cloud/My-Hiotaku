import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/auth/handler/firebase_handler.dart';

class WebSocketService {
  static Timer? _heartbeatTimer;
  static bool _isOnline = false;
  static String? _currentUserId;
  static String? _currentSupabaseId;
  static bool _isInitialized = false;
  static RealtimeChannel? _userStatusChannel;

  // Initialize WebSocket service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Get current user Firebase UID
      final firebaseHandler = FirebaseHandler();
      final currentUser = firebaseHandler.getCurrentUser();
      _currentUserId = currentUser?.uid;
      
      if (_currentUserId != null) {
        // Get Supabase UUID from Firebase UID
        await _getSupabaseUserId();
        
        if (_currentSupabaseId != null) {
          await _setUserOnline();
          _startHeartbeat();
          _listenToAppLifecycle();
          _isInitialized = true;
          debugPrint('WebSocket service initialized for user: $_currentSupabaseId');
        }
      }
    } catch (e) {
      debugPrint('WebSocket initialization failed: $e');
    }
  }

  // Get Supabase UUID from Firebase UID
  static Future<void> _getSupabaseUserId() async {
    if (_currentUserId == null) return;
    
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('firebase_uid', _currentUserId!)
          .limit(1);
      
      if (response.isNotEmpty) {
        _currentSupabaseId = response.first['id'];
        debugPrint('Found Supabase ID: $_currentSupabaseId for Firebase UID: $_currentUserId');
      } else {
        debugPrint('No Supabase user found for Firebase UID: $_currentUserId');
      }
    } catch (e) {
      debugPrint('Failed to get Supabase user ID: $e');
    }
  }

  // Set user online status
  static Future<void> _setUserOnline() async {
    if (_currentSupabaseId == null) return;
    
    try {
      await Supabase.instance.client
          .from('users')
          .update({
            'is_online': true,
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentSupabaseId!);
      
      _isOnline = true;
      debugPrint('User set to online: $_currentSupabaseId');
    } catch (e) {
      debugPrint('Failed to set user online: $e');
    }
  }

  // Set user offline status
  static Future<void> _setUserOffline() async {
    if (_currentSupabaseId == null) return;
    
    try {
      await Supabase.instance.client
          .from('users')
          .update({
            'is_online': false,
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentSupabaseId!);
      
      _isOnline = false;
      debugPrint('User set to offline: $_currentSupabaseId');
    } catch (e) {
      debugPrint('Failed to set user offline: $e');
    }
  }

  // Update last seen timestamp (heartbeat)
  static Future<void> _updateLastSeen() async {
    if (_currentSupabaseId == null) return;
    
    try {
      await Supabase.instance.client
          .from('users')
          .update({
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentSupabaseId!);
    } catch (e) {
      debugPrint('Failed to update last seen: $e');
    }
  }

  // Start heartbeat timer
  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (_isOnline) {
        _updateLastSeen();
      }
    });
  }

  // Listen to app lifecycle changes
  static void _listenToAppLifecycle() {
    WidgetsBinding.instance.addObserver(_AppLifecycleObserver());
  }

  // Get user online status by firebase_uid
  static Future<bool> isUserOnline(String firebaseUid) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('is_online, last_seen')
          .eq('firebase_uid', firebaseUid)
          .limit(1);
      
      if (response.isNotEmpty) {
        final user = response.first;
        if (user['is_online'] == true) {
          // Check if last seen is within 2 minutes
          final lastSeen = DateTime.parse(user['last_seen']);
          final now = DateTime.now();
          final difference = now.difference(lastSeen).inMinutes;
          
          return difference <= 2;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Failed to check user online status: $e');
      return false;
    }
  }

  // Subscribe to user status changes (real-time)
  static RealtimeChannel? subscribeToUserStatus({
    required String firebaseUid,
    required Function(bool isOnline) onStatusChange,
  }) {
    try {
      final channel = Supabase.instance.client
          .channel('user_status_$firebaseUid')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'users',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'firebase_uid',
              value: firebaseUid,
            ),
            callback: (payload) {
              final newRecord = payload.newRecord;
              if (newRecord != null) {
                final isOnline = newRecord['is_online'] ?? false;
                onStatusChange(isOnline);
              }
            },
          )
          .subscribe();
      
      return channel;
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
  static String? get currentUserId => _currentUserId;
  static String? get currentSupabaseId => _currentSupabaseId;
}

// App lifecycle observer
class _AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (WebSocketService._currentSupabaseId != null) {
          WebSocketService._setUserOnline();
          WebSocketService._startHeartbeat();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        WebSocketService._setUserOffline();
        WebSocketService._heartbeatTimer?.cancel();
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}
