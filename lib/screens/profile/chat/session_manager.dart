import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_session.dart';

class SessionManager {
  static const String _sessionsKey = 'hisu_chat_sessions';
  static const String _activeSessionKey = 'hisu_active_session';

  // Get all sessions
  static Future<List<ChatSession>> getSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);
      
      if (sessionsJson != null) {
        final List<dynamic> decoded = jsonDecode(sessionsJson);
        return decoded.map((s) => ChatSession.fromJson(s)).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Most recent first
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  // Save all sessions
  static Future<void> saveSessions(List<ChatSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, sessionsJson);
    } catch (e) {
      // Silently fail
    }
  }

  // Get active session ID
  static Future<String?> getActiveSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeSessionKey);
    } catch (e) {
      return null;
    }
  }

  // Set active session ID
  static Future<void> setActiveSessionId(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeSessionKey, sessionId);
    } catch (e) {
      // Silently fail
    }
  }

  // Create new session
  static Future<ChatSession> createNewSession() async {
    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );

    final sessions = await getSessions();
    sessions.insert(0, session);
    await saveSessions(sessions);
    await setActiveSessionId(session.id);

    return session;
  }

  // Update session
  static Future<void> updateSession(ChatSession session) async {
    final sessions = await getSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);
    
    if (index != -1) {
      sessions[index] = session;
      await saveSessions(sessions);
    }
  }

  // Delete session
  static Future<void> deleteSession(String sessionId) async {
    final sessions = await getSessions();
    sessions.removeWhere((s) => s.id == sessionId);
    await saveSessions(sessions);
  }

  // Get session by ID
  static Future<ChatSession?> getSession(String sessionId) async {
    final sessions = await getSessions();
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  // Generate title from first message
  static String generateTitle(String firstMessage) {
    if (firstMessage.isEmpty) return 'New Chat';
    return firstMessage.length > 30 
        ? '${firstMessage.substring(0, 30)}...' 
        : firstMessage;
  }
}
