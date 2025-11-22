import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Test API - replace with secure endpoint in production
  static const String _testBaseUrl = 'https://v1-w3sc.onrender.com';
  
  // Production: Use environment variables or secure storage
  static String get baseUrl {
    // In production, use: Platform.environment['API_BASE_URL'] ?? _testBaseUrl;
    return _testBaseUrl;
  }
  
  // Add headers for security
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'User-Agent': 'HiotakuApp/1.0',
    // Add API key header in production: 'Authorization': 'Bearer $apiKey',
  };
  
  static Future<Map<String, dynamic>> getHome() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=home'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'error': 'Failed to load home data'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> searchAnime(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=search&q=${Uri.encodeComponent(query)}'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'error': 'Search failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getAnimeDetails(String animeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=anime&id=${Uri.encodeComponent(animeId)}'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'error': 'Failed to load anime details'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getEpisodes(String animeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=episodes&id=${Uri.encodeComponent(animeId)}'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'error': 'Failed to load episodes'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getStreamUrl(String episodeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=stream&id=${Uri.encodeComponent(episodeId)}'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'error': 'Failed to get stream URL'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getPopular() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?action=popular'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'error': 'Failed to load popular anime'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
