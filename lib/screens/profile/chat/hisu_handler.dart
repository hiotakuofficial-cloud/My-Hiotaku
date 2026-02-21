import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config.dart';

class HisuHandler {
  static const String _historyKey = 'hisu_chat_history';
  static const int _maxHistorySize = 50;
  
  // API Configuration
  static const String _apiUrl = 'https://hiotaku.in/hiotaku/api/v1/chat/';
  static const String _authKey = String.fromEnvironment('hisu_authkey');
  static const String _authKey2 = String.fromEnvironment('hisu_authkey2');
  static const String _babeer = String.fromEnvironment('hisu_babeer');
  static const String _apiKey = String.fromEnvironment('hisu_apikey');

  // Send message to Hisu API
  static Future<Map<String, dynamic>> sendMessage(String message, {String? conversationContext}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'authkey': _authKey,
        'authkey2': _authKey2,
        'babeer': _babeer,
        'apikey': _apiKey,
      };
      
      // Add conversation context if available (max 500 chars)
      if (conversationContext != null && conversationContext.isNotEmpty) {
        final truncatedContext = conversationContext.length > 500 
            ? conversationContext.substring(conversationContext.length - 500)
            : conversationContext;
        headers['user-memory'] = truncatedContext;
      }
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return {
            'success': true,
            'response': data['response'] ?? '',
            'anime_cards': data['anime_cards'] ?? [],
          };
        } else {
          return {
            'success': false,
            'error': 'API returned unsuccessful response',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Unable to connect. Please check your internet connection.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection failed. Please try again later.',
      };
    }
  }

  // Save chat history
  static Future<void> saveChatHistory(List<Map<String, dynamic>> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Keep only last N messages
      final limitedMessages = messages.length > _maxHistorySize
          ? messages.sublist(messages.length - _maxHistorySize)
          : messages;
      
      final jsonString = jsonEncode(limitedMessages);
      await prefs.setString(_historyKey, jsonString);
    } catch (e) {
      // Silently fail - history is not critical
    }
  }

  // Load chat history
  static Future<List<Map<String, dynamic>>> loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_historyKey);
      
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  // Clear chat history
  static Future<void> clearChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      // Silently fail
    }
  }

  // Get history count
  static Future<int> getHistoryCount() async {
    final history = await loadChatHistory();
    return history.length;
  }
}
