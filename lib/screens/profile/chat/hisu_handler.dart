import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'components/sanitizer.dart';

class HisuHandler {
  static const String _historyKey = 'hisu_chat_history';
  static const int _maxHistorySize = 50;
  
  // API Configuration
  static const String _apiUrl = String.fromEnvironment('hisu_api_url');
  static const String _authKey = String.fromEnvironment('hisu_authkey');
  static const String _authKey2 = String.fromEnvironment('hisu_authkey2');
  static const String _babeer = String.fromEnvironment('hisu_babeer');
  static const String _apiKey = String.fromEnvironment('hisu_apikey');
  
  // Anime API token (from environment)
  static const String _animeApiToken = String.fromEnvironment('API_TOKEN');
  
  // Fetch anime details (Hindi or English API based on ID)
  static Future<Map<String, dynamic>> fetchAnimeDetails(String animeId) async {
    try {
      // Check if ID is purely numeric (Hindi API)
      final isNumeric = RegExp(r'^\d+$').hasMatch(animeId);
      
      if (isNumeric) {
        // Hindi API
        final url = 'https://www.hiotaku.in/hindiv2.php?action=info&id=$animeId&token=$_animeApiToken';
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['error'] == null) {
            return data;
          }
        }
      }
      
      // English API (alphanumeric or letters only)
      final url = 'https://www.hiotaku.in/api.php?action=details&id=$animeId&token=$_animeApiToken';
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true || data['error'] == null) {
          return data;
        }
      }
      
      throw Exception('Failed to fetch anime details');
    } catch (e) {
      throw Exception('Anime fetch failed: $e');
    }
  }

  // Send message to Hisu API with retry logic
  static Future<Map<String, dynamic>> sendMessage(String message, {String? conversationContext, int retryCount = 0}) async {
    const maxRetries = 2;
    http.Client? client;
    
    try {
      // Validate API URL
      if (_apiUrl.isEmpty) {
        return {
          'success': false,
          'error': 'API configuration error. Please contact support.',
        };
      }


      client = http.Client();
      
      final headers = {
        'Content-Type': 'application/json',
        'authkey': _authKey,
        'authkey2': _authKey2,
        'babeer': _babeer,
        'apikey': _apiKey,
      };
      
      // Add conversation context if available (max 500 chars)
      if (conversationContext != null && conversationContext.isNotEmpty) {
        // Context is already cleaned and truncated to 500 chars
        headers['user-memory'] = conversationContext;
      }
      
      final request = http.Request('POST', Uri.parse(_apiUrl))
        ..headers.addAll(headers)
        ..body = jsonEncode({'message': message})
        ..followRedirects = true
        ..maxRedirects = 5;
      
      
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);


      // Validate response body
      if (response.body.isEmpty) {
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
          return sendMessage(message, conversationContext: conversationContext, retryCount: retryCount + 1);
        }
        return {
          'success': false,
          'error': 'Empty response from server. Please try again.',
        };
      }


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        
        if (data['success'] == true) {
          final responseText = data['response'] ?? '';
          return {
            'success': true,
            'response': responseText,
            'anime_cards': data['anime_cards'] ?? [],
          };
        } else {
          return {
            'success': false,
            'error': data['error'] ?? 'API returned unsuccessful response',
          };
        }
      } else {
        // Retry on server errors
        if (retryCount < maxRetries && (response.statusCode >= 500 || response.statusCode == 307)) {
          await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
          return sendMessage(message, conversationContext: conversationContext, retryCount: retryCount + 1);
        }
        return {
          'success': false,
          'error': 'Server error (${response.statusCode}). Please try again.',
        };
      }
    } on TimeoutException {
      // Retry on timeout
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
        return sendMessage(message, conversationContext: conversationContext, retryCount: retryCount + 1);
      }
      return {
        'success': false,
        'error': 'Request timeout. Please check your internet connection.',
      };
    } on FormatException catch (e) {
      // Retry on format errors (malformed response)
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
        return sendMessage(message, conversationContext: conversationContext, retryCount: retryCount + 1);
      }
      return {
        'success': false,
        'error': 'Invalid response from server. Please try again.',
      };
    } catch (e) {
      // Retry on any other error
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
        return sendMessage(message, conversationContext: conversationContext, retryCount: retryCount + 1);
      }
      return {
        'success': false,
        'error': 'Connection failed. Please try again later.',
      };
    } finally {
      client?.close();
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
