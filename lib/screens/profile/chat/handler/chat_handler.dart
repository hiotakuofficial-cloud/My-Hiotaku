import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../services/websocket_service.dart';
import '../../../auth/handler/supabase.dart';
import '../../../../database/data_validator.dart';

class ChatHandler {
  static String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  static SupabaseClient get _client => WebSocketService.client;
  
  // Chat Room Management
  static Future<String?> createChatRoom({
    required String name,
    required String type, // 'direct' or 'group'
    List<String>? participantIds,
  }) async {
    if (currentUserId == null) return null;
    
    try {
      final roomData = await SupabaseHandler.insertData(
        table: 'chat_rooms',
        data: {
          'name': DataValidator.sanitizeString(name),
          'type': type,
          'created_by': currentUserId,
          'created_at': SupabaseHandler.getCurrentTimestamp(),
        },
      );
      
      if (roomData != null) {
        final roomId = roomData['id'].toString();
        
        // Add creator as participant
        await addParticipant(roomId: roomId, userId: currentUserId!);
        
        // Add other participants
        if (participantIds != null) {
          for (String userId in participantIds) {
            await addParticipant(roomId: roomId, userId: userId);
          }
        }
        
        return roomId;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<bool> addParticipant({
    required String roomId,
    required String userId,
    String role = 'member',
  }) async {
    try {
      final result = await SupabaseHandler.insertData(
        table: 'chat_participants',
        data: {
          'room_id': roomId,
          'user_id': userId,
          'role': role,
          'joined_at': SupabaseHandler.getCurrentTimestamp(),
        },
      );
      return result != null;
    } catch (e) {
      return false;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getUserChatRooms() async {
    if (currentUserId == null) return [];
    
    try {
      final rooms = await SupabaseHandler.getData(
        table: 'chat_participants',
        select: 'room_id,chat_rooms(id,name,type,created_at)',
        filters: {'user_id': currentUserId!},
      );
      
      return rooms?.map((room) {
        final roomData = room['chat_rooms'];
        return {
          'id': roomData['id'],
          'name': roomData['name'],
          'type': roomData['type'],
          'created_at': roomData['created_at'],
        };
      }).toList() ?? [];
    } catch (e) {
      return [];
    }
  }
  
  // Message Management
  static Future<bool> sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
  }) async {
    if (currentUserId == null) return false;
    
    try {
      final result = await SupabaseHandler.insertData(
        table: 'messages',
        data: {
          'room_id': roomId,
          'sender_id': currentUserId,
          'content': DataValidator.sanitizeString(content),
          'message_type': messageType,
          'created_at': SupabaseHandler.getCurrentTimestamp(),
        },
      );
      return result != null;
    } catch (e) {
      return false;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getRoomMessages({
    required String roomId,
    int limit = 50,
    String? beforeMessageId,
  }) async {
    try {
      final response = await _client.from('messages').select('''
        id, content, message_type, created_at,
        users!sender_id(username, display_name, avatar_url)
      ''').eq('room_id', roomId).order('created_at', ascending: false).limit(limit);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
  
  // Typing Indicators
  static Future<void> setTypingStatus({
    required String roomId,
    required bool isTyping,
  }) async {
    if (currentUserId == null) return;
    
    try {
      await SupabaseHandler.updateData(
        table: 'typing_indicators',
        data: {
          'is_typing': isTyping,
          'updated_at': SupabaseHandler.getCurrentTimestamp(),
        },
        filters: {
          'room_id': roomId,
          'user_id': currentUserId!,
        },
      );
    } catch (e) {
      // Silent fail
    }
  }
  
  // Message Reactions
  static Future<bool> addReaction({
    required String messageId,
    required String reactionType,
  }) async {
    if (currentUserId == null) return false;
    
    try {
      final result = await SupabaseHandler.insertData(
        table: 'message_reactions',
        data: {
          'message_id': messageId,
          'user_id': currentUserId,
          'reaction_type': reactionType,
          'created_at': SupabaseHandler.getCurrentTimestamp(),
        },
      );
      return result != null;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> removeReaction({
    required String messageId,
    required String reactionType,
  }) async {
    if (currentUserId == null) return false;
    
    try {
      return await SupabaseHandler.deleteData(
        table: 'message_reactions',
        filters: {
          'message_id': messageId,
          'user_id': currentUserId!,
          'reaction_type': reactionType,
        },
      );
    } catch (e) {
      return false;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getMessageReactions(String messageId) async {
    try {
      return await SupabaseHandler.getData(
        table: 'message_reactions',
        select: 'reaction_type,users(username,avatar_url)',
        filters: {'message_id': messageId},
      ) ?? [];
    } catch (e) {
      return [];
    }
  }
  
  // WebSocket Subscriptions
  static RealtimeChannel? subscribeToRoomMessages({
    required String roomId,
    required Function(Map<String, dynamic>) onMessage,
  }) {
    return WebSocketService.subscribeToChatMessages(roomId, onMessage);
  }
  
  static RealtimeChannel? subscribeToTypingIndicators({
    required String roomId,
    required Function(Map<String, dynamic>) onTyping,
  }) {
    return WebSocketService.subscribeToTypingIndicators(roomId, onTyping);
  }
  
  static RealtimeChannel? subscribeToMessageReactions({
    required String messageId,
    required Function(Map<String, dynamic>) onReaction,
  }) {
    return WebSocketService.subscribeToMessageReactions(messageId, onReaction);
  }
  
  static RealtimeChannel? subscribeToRoomUpdates({
    required Function(Map<String, dynamic>) onRoomUpdate,
  }) {
    return WebSocketService.subscribeToChatRooms(onRoomUpdate);
  }
  
  static RealtimeChannel? subscribeToParticipants({
    required String roomId,
    required Function(Map<String, dynamic>) onParticipantChange,
  }) {
    return WebSocketService.subscribeToChatParticipants(roomId, onParticipantChange);
  }
  
  // Utility Methods
  static Future<bool> isUserInRoom({
    required String roomId,
    required String userId,
  }) async {
    try {
      final participants = await SupabaseHandler.getData(
        table: 'chat_participants',
        filters: {
          'room_id': roomId,
          'user_id': userId,
        },
      );
      return participants?.isNotEmpty ?? false;
    } catch (e) {
      return false;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getRoomParticipants(String roomId) async {
    try {
      return await SupabaseHandler.getData(
        table: 'chat_participants',
        select: 'user_id,role,joined_at,users(username,display_name,avatar_url)',
        filters: {'room_id': roomId},
      ) ?? [];
    } catch (e) {
      return [];
    }
  }
  
  static Future<bool> leaveRoom(String roomId) async {
    if (currentUserId == null) return false;
    
    try {
      return await SupabaseHandler.deleteData(
        table: 'chat_participants',
        filters: {
          'room_id': roomId,
          'user_id': currentUserId!,
        },
      );
    } catch (e) {
      return false;
    }
  }
  
  static Future<int> getUnreadMessageCount(String roomId) async {
    if (currentUserId == null) return 0;
    
    try {
      // This would require a last_read_at field in chat_participants
      // For now, return 0 as placeholder
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
