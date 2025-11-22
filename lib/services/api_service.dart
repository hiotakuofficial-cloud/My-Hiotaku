import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _testBaseUrl = 'https://v1-w3sc.onrender.com';
  static const String _apiKey = 'hiotaku_test_key_2024';
  
  static String get baseUrl => _testBaseUrl;
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'User-Agent': 'HiotakuApp/1.0',
    'X-API-Key': _apiKey,
    'Accept': 'application/json',
  };
  
  static Uri _buildUri(String endpoint, [Map<String, String>? queryParams]) {
    final params = <String, String>{
      'key': _apiKey,
      'source': 'mobile_app',
      'version': '1.0',
      ...?queryParams,
    };
    return Uri.parse(baseUrl).replace(queryParameters: params..addAll({'action': endpoint}));
  }
  
  static Future<Map<String, dynamic>> getHome() async {
    try {
      final uri = _buildUri('home', {'limit': '20', 'page': '1'});
      final response = await http.get(uri, headers: _headers);
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
      final uri = _buildUri('search', {
        'q': query,
        'limit': '15',
        'type': 'anime'
      });
      final response = await http.get(uri, headers: _headers);
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
      final uri = _buildUri('anime', {
        'id': animeId,
        'include': 'episodes,genres,rating'
      });
      final response = await http.get(uri, headers: _headers);
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
      final uri = _buildUri('episodes', {
        'id': animeId,
        'sort': 'episode_number',
        'order': 'asc'
      });
      final response = await http.get(uri, headers: _headers);
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
      final uri = _buildUri('stream', {
        'id': episodeId,
        'quality': 'auto',
        'server': 'primary'
      });
      final response = await http.get(uri, headers: _headers);
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
      final uri = _buildUri('popular', {
        'limit': '20',
        'period': 'week',
        'type': 'anime'
      });
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'error': 'Failed to load popular anime'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getGenre(String genre) async {
    try {
      final uri = _buildUri('genre', {
        'type': genre,
        'limit': '20',
        'page': '1'
      });
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'error': 'Failed to load genre'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
