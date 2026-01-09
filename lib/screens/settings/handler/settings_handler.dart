import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class SettingsHandler {
  // App Download API Configuration
  static const String _supportApiEndpoint = '/support/v1/app.php';
  static const String _authKey = 'nehubaby';
  static const String _authKey2 = 'pihupapa';
  
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
          'error': 'Failed to get download link: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
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
          'error': 'Failed to update URL: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
