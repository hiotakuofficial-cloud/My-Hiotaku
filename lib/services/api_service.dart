import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  static String get baseUrl => AppConfig.baseUrl;
  
  static Future<Map<String, dynamic>> getHome() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=home'));
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
      final response = await http.get(Uri.parse('$baseUrl?action=search&q=${Uri.encodeComponent(query)}'));
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
      final response = await http.get(Uri.parse('$baseUrl?action=anime&id=${Uri.encodeComponent(animeId)}'));
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
      final response = await http.get(Uri.parse('$baseUrl?action=episodes&id=${Uri.encodeComponent(animeId)}'));
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
      final response = await http.get(Uri.parse('$baseUrl?action=stream&id=${Uri.encodeComponent(episodeId)}'));
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
      final response = await http.get(Uri.parse('$baseUrl?action=popular'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'error': 'Failed to load popular anime'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
