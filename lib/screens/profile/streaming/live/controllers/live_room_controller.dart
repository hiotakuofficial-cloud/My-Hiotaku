import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../screens/auth/handler/supabase.dart';

class LiveRoomController {
  static final _client = Supabase.instance.client;

  RealtimeChannel? _channel;
  StreamController<Map<String, dynamic>>? _roomStream;

  Stream<Map<String, dynamic>>? get roomUpdates => _roomStream?.stream;

  // ── Create Room ──────────────────────────────────────────────
  static Future<Map<String, dynamic>?> createRoom({
    required String title,
    String? password,
    String? playId,
    String? thumbnail,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final userData = await SupabaseHandler.getUserByFirebaseUID(uid);
    if (userData == null) return null;

    return await SupabaseHandler.insertData(
      table: 'live_rooms',
      data: {
        'user_id': userData['id'],
        'title': title,
        if (password != null) 'password': password,
        'video_timestamp': 0.0,
        if (playId != null) 'play_id': playId,
        if (thumbnail != null) 'thumbnail': thumbnail,
      },
    );
  }

  // ── Join Room ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>?> joinRoom({
    required String roomId,
    String? password,
  }) async {
    final rooms = await SupabaseHandler.getData(
      table: 'live_rooms',
      filters: {'room_id': roomId},
    );
    if (rooms == null || rooms.isEmpty) return null;

    final room = rooms.first;
    if (room['password'] != null && room['password'] != password) return null;

    return room;
  }

  // ── Sync Timestamp (host only) ────────────────────────────────
  static Future<void> updateTimestamp({
    required String roomId,
    required double timestamp,
  }) async {
    await _client
        .from('live_rooms')
        .update({'video_timestamp': timestamp})
        .eq('room_id', roomId);
  }

  // ── Subscribe to Room (WebSocket realtime) ────────────────────
  void subscribeToRoom({
    required String roomId,
    required void Function(Map<String, dynamic> room) onUpdate,
  }) {
    _roomStream = StreamController<Map<String, dynamic>>.broadcast();

    _channel = _client
        .channel('live_room:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'live_rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            final updated = payload.newRecord;
            _roomStream?.add(updated);
            onUpdate(updated);
          },
        )
        .subscribe();
  }

  // ── Unsubscribe ───────────────────────────────────────────────
  Future<void> dispose() async {
    await _channel?.unsubscribe();
    await _roomStream?.close();
  }

  // ── Delete Room (host only) ───────────────────────────────────
  static Future<void> deleteRoom(String roomId) async {
    await SupabaseHandler.deleteData(
      table: 'live_rooms',
      filters: {'room_id': roomId},
    );
  }
}
