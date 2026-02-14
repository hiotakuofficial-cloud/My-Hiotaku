import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../config.dart';

class SettingsHandler {
  // App Download API Configuration
  static const String _supportApiEndpoint = '/support/v1/app.php';
  static const String _supportTicketEndpoint = '/support/v1/index.php';
  static const String _authKey = 'nehubaby';
  static const String _authKey2 = 'pihupapa';
  
  // Get current user's Firebase UID
  static String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }
  
  // Build support API URL
  static String _buildSupportUrl(String action, {String? url}) {
    final params = <String, String>{
      'action': action,
      'authkey': _authKey,
      'authkey2': _authKey2,
    };
    
    if (url != null) {
      params['url'] = url;
    }
    
    final queryParams = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '${AppConfig.animeApiBaseUrl}$_supportApiEndpoint?$queryParams';
  }

  // Build support ticket API URL
  static String _buildSupportTicketUrl(String action, Map<String, String> params) {
    final allParams = <String, String>{
      'action': action,
      'authkey': _authKey,
      'authkey2': _authKey2,
      ...params,
    };
    
    final queryParams = allParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    return '${AppConfig.animeApiBaseUrl}$_supportTicketEndpoint?$queryParams';
  }
  
  // Get current app download link
  static Future<Map<String, dynamic>> getAppDownloadLink() async {
    try {
      final url = _buildSupportUrl('getapplink');
      
      final response = await http.get(
        Uri.parse(url),
        headers: AppConfig.defaultHeaders,
      ).timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'download_link': data['download_link'],
          'error': data['error'],
        };
      } else {
        return {
          'success': false,
          'error': 'Unable to get download link',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection failed',
      };
    }
  }
  
  // Update app download URL
  static Future<Map<String, dynamic>> updateAppDownloadUrl(String newUrl) async {
    try {
      final url = _buildSupportUrl('updateurl', url: newUrl);
      
      final response = await http.get(
        Uri.parse(url),
        headers: AppConfig.defaultHeaders,
      ).timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'],
          'new_url': data['new_url'],
          'error': data['error'],
        };
      } else {
        return {
          'success': false,
          'error': 'Unable to update download link',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection failed',
      };
    }
  }

  // Submit support request
  static Future<Map<String, dynamic>> submitSupportRequest({
    required String username,
    required String userId,
    required String message,
    String sender = 'user',
  }) async {
    try {
      final url = '${AppConfig.animeApiBaseUrl}$_supportTicketEndpoint?action=support';
      
      // Only send exact fields API expects - no extra fields
      final bodyData = 'authkey=$_authKey&authkey2=$_authKey2&username=${Uri.encodeComponent(username)}&userId=${Uri.encodeComponent(userId)}&message=${Uri.encodeComponent(message)}&sender=$sender';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: bodyData,
      ).timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'],
          'support_ticket': data['support_ticket'],
          'ticket_id': data['ticket_id'],
          'timestamp': data['timestamp'],
          'error': data['error'],
        };
      } else {
        return {
          'success': false,
          'error': 'Unable to process request',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection failed',
      };
    }
  }

  // Get support messages
  static Future<Map<String, dynamic>> getSupportMessages({
    required String support, // 'all' or userId
  }) async {
    try {
      final url = _buildSupportTicketUrl('get', {
        'support': support,
      });
      
      final response = await http.get(
        Uri.parse(url),
        headers: AppConfig.defaultHeaders,
      ).timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'messages': data['messages'],
          'count': data['count'],
          'limit': data['limit'],
          'error': data['error'],
        };
      } else {
        return {
          'success': false,
          'error': 'Unable to get messages',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection failed',
      };
    }
  }

  // Delete support ticket
  static Future<Map<String, dynamic>> deleteSupportTicket(int supportId) async {
    try {
      final url = _buildSupportTicketUrl('delete', {
        'supportId': supportId.toString(),
      });
      
      final response = await http.delete(
        Uri.parse(url),
        headers: AppConfig.defaultHeaders,
      ).timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'message': data['message'],
          'deleted_id': data['deleted_id'],
          'error': data['error'],
        };
      } else {
        return {
          'success': false,
          'error': 'Unable to delete ticket',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Connection failed',
      };
    }
  }
}
