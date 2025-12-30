import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

class WebSocketService {
  static late SupabaseClient _client;
  static bool _isInitialized = false;

  // Initialize WebSocket service
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: 'https://brwzqawoncblbxqoqyua.supabase.co',
        anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyd3pxYXdvbmNibGJ4cW9xeXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzM1MjIsImV4cCI6MjA3NzkwOTUyMn0.-HNrfcz5K2N6f_Q8tQsWtsUJCV_SW13Hcj565qU5eCA',
      );
      _client = Supabase.instance.client;
      _isInitialized = true;
      
      Fluttertoast.showToast(
        msg: "✅ WebSocket SDK initialized",
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
        Fluttertoast.showToast(
          msg: "❌ WebSocket SDK failed: $e",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    }
  }

  static bool get isReady => _isInitialized;
  static SupabaseClient get client => _client;
  static String? get currentFirebaseUid => FirebaseAuth.instance.currentUser?.uid;

  // Set user online status with heartbeat (FIXED SERVER TIME)
  static Future<void> setOnlineStatus(bool isOnline) async {
    if (!_isInitialized) return;
    
    try {
      final firebaseUid = currentFirebaseUid;
      if (firebaseUid == null) return;

      // FIXED: Use proper server timestamp function
      if (isOnline) {
        await _client.from('user_presence').upsert({
          'firebase_uid': firebaseUid,
          'is_online': true,
          'status': 'online',
        });
        
        // Update last_seen with server function call
        await _client.rpc('update_user_heartbeat', params: {
          'user_firebase_uid': firebaseUid
        });
      } else {
        await _client.from('user_presence').upsert({
          'firebase_uid': firebaseUid,
          'is_online': false,
          'status': 'offline',
        });
      }
      
      // Start heartbeat if going online
      if (isOnline) {
        _startHeartbeat();
      } else {
        _stopHeartbeat();
      }
      
      Fluttertoast.showToast(
        msg: isOnline ? "🟢 Online (Fixed)" : "⚫ Offline",
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

  static Timer? _heartbeatTimer;

  // Send heartbeat every 3 minutes (FIXED TIMING)
  static void _startHeartbeat() {
    _stopHeartbeat(); // Stop existing timer
    
    _heartbeatTimer = Timer.periodic(Duration(minutes: 3), (timer) async {
      final firebaseUid = currentFirebaseUid;
      if (firebaseUid != null && _isInitialized) {
        try {
          // FIXED: Use RPC function instead of direct update
          await _client.rpc('update_user_heartbeat', params: {
            'user_firebase_uid': firebaseUid
          });
          
          Fluttertoast.showToast(
            msg: "💓 Heartbeat (Fixed)",
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

  // Auto set offline when app goes to background
  static Future<void> setOfflineOnBackground() async {
    _stopHeartbeat(); // Stop heartbeat
    await setOnlineStatus(false);
  }

  // Auto set online when app comes to foreground
  static Future<void> setOnlineOnForeground() async {
    await setOnlineStatus(true); // This will start heartbeat
  }

  // Subscribe to presence updates
  static RealtimeChannel subscribeToPresence(Function(Map<String, dynamic>) onUpdate) {
    return _client
        .channel('presence_global')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_presence',
          callback: (payload) => onUpdate(payload.newRecord),
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
            
            Fluttertoast.showToast(
              msg: "🔄 Auto-marked user offline (${difference}min ago)",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.BOTTOM,
            );
            
            return false;
          }
        }
        
        return isOnline;
      } catch (e2) {
        return false;
      }
    }
  }

  // Manual function to mark stale users offline (for testing)
  static Future<void> markStaleUsersOffline() async {
    if (!_isInitialized) return;
    
    try {
      await _client.rpc('mark_stale_users_offline');
      Fluttertoast.showToast(
        msg: "🔄 Marked stale users offline",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "❌ Failed to mark users offline: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
