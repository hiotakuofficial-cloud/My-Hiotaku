import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Initialize WebSocket service with device tracking (optimized)
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: const String.fromEnvironment('SUPA_URL', defaultValue: ''),
        anonKey: const String.fromEnvironment('ANON_KEY', defaultValue: ''),
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
    } catch (e) {
      if (e.toString().contains('already initialized')) {
        _client = Supabase.instance.client;
        _isInitialized = true;
      } else {
        _isInitialized = false;
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

  // Start connection monitoring (optimized)
  static Future<void> _startConnectionMonitoring() async {
    try {
      // Create a simple connection monitor channel
      _presenceChannel = _client.channel('connection_monitor')
        .subscribe();
        
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
    }
  }

  // Reconnection logic (silent)
  static Future<void> _reconnect() async {
    try {
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
      // Silent fail
    }
  }

  // Set user online status (optimized, no toasts)
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
    } catch (e) {
      // Silent fail for performance
    }
  }

  // Optimized heartbeat (silent, reduced frequency)
  static void _startHeartbeat() {
    _stopHeartbeat(); // Stop existing timer
    
    _heartbeatTimer = Timer.periodic(Duration(minutes: 4), (timer) async {
      if (_connectionId != null && _isInitialized) {
        try {
          // Update device heartbeat
          await _client.rpc('update_device_heartbeat', params: {
            'conn_id': _connectionId,
          });
        } catch (e) {
          // Silent fail for performance
        }
      }
    });
  }

  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Cleanup connections and sessions (optimized)
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
    } catch (e) {
      // Silent fail
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

  // Optimized subscription with minimal network calls
  static RealtimeChannel subscribeToPresence(Function(Map<String, dynamic>) onUpdate) {
    return _client
        .channel('presence_optimized')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_presence',
          callback: (payload) {
            // Only process meaningful changes
            final newRecord = payload.newRecord;
            if (newRecord['is_online'] != null) {
              onUpdate(newRecord);
            }
          },
        )
        .subscribe();
  }

  // Subscribe to chat messages in real-time
  static RealtimeChannel? subscribeToChatMessages(String roomId, Function(Map<String, dynamic>) onMessage) {
    if (!_isInitialized || roomId.isEmpty) return null;
    
    try {
      return _client
          .channel('chat_messages_$roomId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (payload) {
              try {
                onMessage(payload.newRecord);
              } catch (e) {
                // Silent callback error handling
              }
            },
          )
          .subscribe();
    } catch (e) {
      return null;
    }
  }

  // Subscribe to typing indicators
  static RealtimeChannel? subscribeToTypingIndicators(String roomId, Function(Map<String, dynamic>) onTyping) {
    if (!_isInitialized || roomId.isEmpty) return null;
    
    try {
      return _client
          .channel('typing_$roomId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'typing_indicators',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (payload) {
              try {
                onTyping(payload.newRecord);
              } catch (e) {
                // Silent callback error handling
              }
            },
          )
          .subscribe();
    } catch (e) {
      return null;
    }
  }

  // Subscribe to message reactions
  static RealtimeChannel? subscribeToMessageReactions(String messageId, Function(Map<String, dynamic>) onReaction) {
    if (!_isInitialized || messageId.isEmpty) return null;
    
    try {
      return _client
          .channel('reactions_$messageId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'message_reactions',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'message_id',
              value: messageId,
            ),
            callback: (payload) {
              try {
                onReaction(payload.newRecord);
              } catch (e) {
                // Silent callback error handling
              }
            },
          )
          .subscribe();
    } catch (e) {
      return null;
    }
  }

  // Subscribe to chat room updates
  static RealtimeChannel? subscribeToChatRooms(Function(Map<String, dynamic>) onRoomUpdate) {
    if (!_isInitialized) return null;
    
    try {
      return _client
          .channel('chat_rooms_updates')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_rooms',
            callback: (payload) {
              try {
                onRoomUpdate(payload.newRecord);
              } catch (e) {
                // Silent callback error handling
              }
            },
          )
          .subscribe();
    } catch (e) {
      return null;
    }
  }

  // Subscribe to chat participants changes
  static RealtimeChannel? subscribeToChatParticipants(String roomId, Function(Map<String, dynamic>) onParticipantChange) {
    if (!_isInitialized || roomId.isEmpty) return null;
    
    try {
      return _client
          .channel('participants_$roomId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'chat_participants',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'room_id',
              value: roomId,
            ),
            callback: (payload) {
              try {
                onParticipantChange(payload.newRecord);
              } catch (e) {
                // Silent callback error handling
              }
            },
          )
          .subscribe();
    } catch (e) {
      return null;
    }
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

  // Manual function to mark stale devices offline (optimized)
  static Future<void> markStaleUsersOffline() async {
    if (!_isInitialized) return;
    
    try {
      await _client.rpc('mark_stale_devices_offline');
    } catch (e) {
      // Silent fail
    }
  }
}
