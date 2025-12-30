import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

  // Set user online status
  static Future<void> setOnlineStatus(bool isOnline) async {
    if (!_isInitialized) return;
    
    try {
      final firebaseUid = currentFirebaseUid;
      if (firebaseUid == null) return;

      await _client.from('user_presence').upsert({
        'firebase_uid': firebaseUid,
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
        'status': isOnline ? 'online' : 'offline',
      });
      
      Fluttertoast.showToast(
        msg: isOnline ? "🟢 Online" : "⚫ Offline",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      // Silent fail
    }
  }

  // Auto set offline when app goes to background
  static Future<void> setOfflineOnBackground() async {
    await setOnlineStatus(false);
  }

  // Auto set online when app comes to foreground
  static Future<void> setOnlineOnForeground() async {
    await setOnlineStatus(true);
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

  // Check if user is online (with timeout check)
  static Future<bool> isUserOnline(String firebaseUid) async {
    if (!_isInitialized) return false;
    
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
        final now = DateTime.now();
        final difference = now.difference(lastSeen).inMinutes;
        
        // If last seen more than 5 minutes ago, consider offline
        if (difference > 5) {
          // Auto-update to offline
          await _client.from('user_presence').update({
            'is_online': false,
            'status': 'offline',
          }).eq('firebase_uid', firebaseUid);
          
          return false;
        }
      }
      
      return isOnline;
    } catch (e) {
      return false;
    }
  }
}
