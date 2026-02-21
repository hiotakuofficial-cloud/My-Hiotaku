import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HisuHandler {
  static const String _historyKey = 'hisu_chat_history';
  static const int _maxHistorySize = 50;
  
  // API Configuration
  static const String _apiUrl = String.fromEnvironment('hisu_api_url');
  static const String _authKey = String.fromEnvironment('hisu_authkey');
  static const String _authKey2 = String.fromEnvironment('hisu_authkey2');
  static const String _babeer = String.fromEnvironment('hisu_babeer');
  static const String _apiKey = String.fromEnvironment('hisu_apikey');

  // Send message to Hisu API with retry logic
  static Future<Map<String, dynamic>> sendMessage(String message, {String? conversationContext, int retryCount = 0}) async {
    const maxRetries = 2;
    http.Client? client;
    
    try {
      // Validate API URL
      if (_apiUrl.isEmpty) {
        Fluttertoast.showToast(msg: "❌ API URL empty", gravity: ToastGravity.CENTER);
        return {
          'success': false,
          'error': 'API configuration error. Please contact support.',
        };
      }

      Fluttertoast.showToast(msg: "📤 Sending: ${message.substring(0, message.length > 20 ? 20 : message.length)}...", toastLength: Toast.LENGTH_SHORT);

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
        final truncatedContext = conversationContext.length > 500 
            ? conversationContext.substring(conversationContext.length - 500)
            : conversationContext;
        // Sanitize for HTTP header: remove all control characters and newlines
        final sanitizedContext = truncatedContext
            .replaceAll(RegExp(r'[\r\n\t\x00-\x1F\x7F]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (sanitizedContext.isNotEmpty) {
          headers['user-memory'] = sanitizedContext;
          Fluttertoast.showToast(msg: "🧠 Context: ${sanitizedContext.length} chars", toastLength: Toast.LENGTH_SHORT);
        }
      }
      
      final request = http.Request('POST', Uri.parse(_apiUrl))
        ..headers.addAll(headers)
        ..body = jsonEncode({'message': message})
        ..followRedirects = true
        ..maxRedirects = 5;
      
      Fluttertoast.showToast(msg: "⏳ Waiting for response...", toastLength: Toast.LENGTH_SHORT);
      
      final streamedResponse = await client.send(request).timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      Fluttertoast.showToast(msg: "📥 Status: ${response.statusCode}", toastLength: Toast.LENGTH_SHORT);

      // Validate response body
      if (response.body.isEmpty) {
        Fluttertoast.showToast(msg: "⚠️ Empty response body", gravity: ToastGravity.CENTER);
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
          return sendMessage(message, conversationContext: conversationContext, retryCount: retryCount + 1);
        }
        return {
          'success': false,
          'error': 'Empty response from server. Please try again.',
        };
      }

      Fluttertoast.showToast(msg: "📦 Body: ${response.body.length} bytes", toastLength: Toast.LENGTH_SHORT);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        Fluttertoast.showToast(msg: "✅ Success: ${data['success']}", toastLength: Toast.LENGTH_SHORT);
        
        if (data['success'] == true) {
          final responseText = data['response'] ?? '';
          Fluttertoast.showToast(msg: "💬 Response: ${responseText.substring(0, responseText.length > 30 ? 30 : responseText.length)}...", toastLength: Toast.LENGTH_SHORT);
          return {
            'success': true,
            'response': responseText,
            'anime_cards': data['anime_cards'] ?? [],
          };
        } else {
          Fluttertoast.showToast(msg: "❌ API Error: ${data['error']}", gravity: ToastGravity.CENTER);
          return {
            'success': false,
            'error': data['error'] ?? 'API returned unsuccessful response',
          };
        }
      } else {
        Fluttertoast.showToast(msg: "⚠️ HTTP ${response.statusCode}", gravity: ToastGravity.CENTER);
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
      Fluttertoast.showToast(msg: "⏱️ Timeout! Retry ${retryCount + 1}/${maxRetries + 1}", gravity: ToastGravity.CENTER);
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
      Fluttertoast.showToast(msg: "🔧 Parse Error: ${e.toString().substring(0, 50)}", gravity: ToastGravity.CENTER, toastLength: Toast.LENGTH_LONG);
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
      Fluttertoast.showToast(msg: "💥 Error: ${e.toString().substring(0, 50)}", gravity: ToastGravity.CENTER, toastLength: Toast.LENGTH_LONG);
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
