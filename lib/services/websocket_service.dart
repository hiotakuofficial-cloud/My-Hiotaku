import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WebSocketService {
  static late SupabaseClient _client;
  static bool _isInitialized = false;
  static String? _connectionId;
  static Map<String, dynamic>? _deviceInfo;
  // Connection state management
  static RealtimeChannel? _presenceChannel;
  static StreamSubscription? _connectionSubscription;
  static bool _isConnected = false;

  static Timer? _heartbeatTimer;

  static bool get isReady => _isInitialized;
  static String? get connectionId => _connectionId;
  static bool get isConnected => _isConnected;
  static SupabaseClient get client => _client;
  static String? get currentFirebaseUid => FirebaseAuth.instance.currentUser?.uid;

  // Initialize WebSocket service with device tracking
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: 'https://brwzqawoncblbxqoqyua.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyd3pxYXdvbmNibGJ4cW9xeXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzM1MjIsImV4cCI6MjA3NzkwOTUyMn0.-HNrfcz5K2N6f_Q8tQsWtsUJCV_SW13Hcj565qU5eCA',
      );
      _client = Supabase.instance.client;
      
      // Generate unique connection ID
      _connectionId = DateTime.now().millisecondsSinceEpoch.toString() + 
                     '_' + (FirebaseAuth.instance.currentUser?.uid ?? 'anonymous');
      
      // Get device information
      await _getDeviceInfo();
      
      // Start connection monitoring
      await _startConnectionMonitoring();
      
      _isInitialized = true;
      
      Fluttertoast.showToast(
        msg: "🔌 WebSocket initialized with connection tracking",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      if (e.toString().contains('already initialized')) {
        _client = Supabase.instance.client;
        _isInitialized = true;
        Fluttertoast.showToast(
          msg: "✅ WebSocket SDK ready",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        _isInitialized = false;
        Fluttertoast.showToast(
          msg: "❌ WebSocket initialization failed: $e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  // Get device information for tracking
  static Future<void> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _deviceInfo = {
          'platform': 'android',
          'model': androidInfo.model,
          'version': androidInfo.version.release,
          'app_version': packageInfo.version,
          'device_id': androidInfo.id,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _deviceInfo = {
          'platform': 'ios',
          'model': iosInfo.model,
          'version': iosInfo.systemVersion,
          'app_version': packageInfo.version,
          'device_id': iosInfo.identifierForVendor,
        };
      } else {
        _deviceInfo = {
          'platform': 'unknown',
          'app_version': packageInfo.version,
        };
      }
    } catch (e) {
      _deviceInfo = {'platform': 'unknown', 'error': e.toString()};
    }
  }

  // Start connection monitoring with auto-reconnection
  static Future<void> _startConnectionMonitoring() async {
    try {
      // Create a simple connection monitor channel
      _presenceChannel = _client.channel('connection_monitor')
        .subscribe();
        
      _isConnected = true;
      Fluttertoast.showToast(
        msg: "🔗 Connection monitoring started",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
        
    } catch (e) {
      _isConnected = false;
      Fluttertoast.showToast(
        msg: "❌ Connection monitoring failed: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Reconnection logic
  static Future<void> _reconnect() async {
    try {
      Fluttertoast.showToast(
        msg: "🔄 Reconnecting...",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      
      // Reinitialize connection
      await _startConnectionMonitoring();
      
      // Restore online status if user was online
      final firebaseUid = currentFirebaseUid;
      if (firebaseUid != null) {
        final response = await _client
            .from('user_presence')
            .select('is_online')
            .eq('firebase_uid', firebaseUid)
            .single();
            
        if (response['is_online'] == true) {
          await setOnlineStatus(true);
        }
      }
      
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Reconnection failed: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Set user online status with multi-device support
  static Future<void> setOnlineStatus(bool isOnline) async {
    if (!_isInitialized) return;
    
    try {
      final firebaseUid = currentFirebaseUid;
      if (firebaseUid == null) return;

      if (isOnline) {
        // Register device session
        await _client.rpc('register_device_session', params: {
          'user_firebase_uid': firebaseUid,
          'conn_id': _connectionId,
          'device_data': _deviceInfo,
        });
        
        _startHeartbeat();
      } else {
        // Deactivate device session
        await _client.rpc('deactivate_device_session', params: {
          'conn_id': _connectionId,
        });
        
        _stopHeartbeat();
      }
      
      Fluttertoast.showToast(
        msg: isOnline ? "🟢 Online (Multi-device)" : "⚫ Offline",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Status update failed: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Send heartbeat every 3 minutes with multi-device support
  static void _startHeartbeat() {
    _stopHeartbeat(); // Stop existing timer
    
    _heartbeatTimer = Timer.periodic(Duration(minutes: 3), (timer) async {
      if (_connectionId != null && _isInitialized) {
        try {
          // Update device heartbeat
          await _client.rpc('update_device_heartbeat', params: {
            'conn_id': _connectionId,
          });
          
          Fluttertoast.showToast(
            msg: "💓 Device heartbeat",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        } catch (e) {
          Fluttertoast.showToast(
            msg: "❌ Heartbeat failed: $e",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
          );
        }
      }
    });
  }

  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Cleanup connections and sessions
  static Future<void> cleanup() async {
    try {
      _stopHeartbeat();
      
      // Deactivate current device session
      if (_connectionId != null) {
        await _client.rpc('deactivate_device_session', params: {
          'conn_id': _connectionId,
        });
      }
      
      // Close connection monitoring
      await _connectionSubscription?.cancel();
      await _presenceChannel?.unsubscribe();
      
      _isConnected = false;
      _isInitialized = false;
      
      Fluttertoast.showToast(
        msg: "🔌 WebSocket cleaned up",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Cleanup failed: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Auto set offline when app goes to background
  static Future<void> setOfflineOnBackground() async {
    _stopHeartbeat(); // Stop heartbeat
    await setOnlineStatus(false);
  }

  // Auto set online when app comes to foreground
  static Future<void> setOnlineOnForeground() async {
    await setOnlineStatus(true); // This will start heartbeat
  }

  // Enhanced subscription with reduced polling
  static RealtimeChannel subscribeToPresence(Function(Map<String, dynamic>) onUpdate) {
    return _client
        .channel('presence_optimized')
        .onPostgresChanges(
          event: PostgresChangeEvent.update, // Only listen to updates, not all changes
          schema: 'public',
          table: 'user_presence',
          callback: (payload) {
            // Only process meaningful changes
            final newRecord = payload.newRecord;
            onUpdate(newRecord);
          },
        )
        .subscribe();
  }

  // Check if user is online (SERVER TIME comparison)
  static Future<bool> isUserOnline(String firebaseUid) async {
    if (!_isInitialized) return false;
    
    try {
      // Use server-side time comparison to avoid timezone issues
      final response = await _client
          .rpc('check_user_online_status', params: {'user_firebase_uid': firebaseUid});
      
      return response ?? false;
    } catch (e) {
      // Fallback to manual check if RPC fails
      try {
        final response = await _client
            .from('user_presence')
            .select('is_online, last_seen')
            .eq('firebase_uid', firebaseUid)
            .single();
        
        final isOnline = response['is_online'] ?? false;
        final lastSeenStr = response['last_seen'];
        
        // If marked online, check if last_seen is recent (within 5 minutes)
        if (isOnline && lastSeenStr != null) {
          final lastSeen = DateTime.parse(lastSeenStr);
          final now = DateTime.now().toUtc(); // Use UTC for comparison
          final difference = now.difference(lastSeen).inMinutes;
          
          // If last seen more than 5 minutes ago, consider offline
          if (difference > 5) {
            // Auto-update to offline using server time
            await _client.from('user_presence').update({
              'is_online': false,
              'status': 'offline',
            }).eq('firebase_uid', firebaseUid);
            
            return false;
          }
        }
        
        return isOnline;
      } catch (e2) {
        return false;
      }
    }
  }

  // Manual function to mark stale devices offline (for testing)
  static Future<void> markStaleUsersOffline() async {
    if (!_isInitialized) return;
    
    try {
      final result = await _client.rpc('mark_stale_devices_offline');
      Fluttertoast.showToast(
        msg: "🔄 Marked $result stale devices offline",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Failed to mark devices offline: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
