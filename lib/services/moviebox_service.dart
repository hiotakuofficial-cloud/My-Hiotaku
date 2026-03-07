import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class MovieBoxService {
  // Get home content (platforms + sections)
  static Future<Map<String, dynamic>> getHome() async {
    final url = AppConfig.buildMovieBoxUrl('home', {});
    final response = await http.get(
      Uri.parse(url),
      headers: AppConfig.movieBoxHeaders,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load home: ${response.statusCode}');
  }
  
  // Get trending content
  static Future<Map<String, dynamic>> getTrending({
    int page = 0,
    int perPage = 20,
  }) async {
    final url = AppConfig.buildMovieBoxUrl('trending', {
      'page': page,
      'perPage': perPage,
    });
    
    final response = await http.get(
      Uri.parse(url),
      headers: AppConfig.movieBoxHeaders,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load trending: ${response.statusCode}');
  }
  
  // Search content
  static Future<Map<String, dynamic>> search({
    required String keyword,
    int page = 0,
    int perPage = 28,
    int subjectType = 0,
  }) async {
    final url = AppConfig.buildMovieBoxUrl('search', {
      'keyword': keyword,
      'page': page,
      'perPage': perPage,
      'subjectType': subjectType,
    });
    
    final response = await http.get(
      Uri.parse(url),
      headers: AppConfig.movieBoxHeaders,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to search: ${response.statusCode}');
  }
  
  // Get content details
  static Future<Map<String, dynamic>> getDetail({
    String? id,
    String? path,
  }) async {
    if (id == null && path == null) {
      throw Exception('Either id or path is required');
    }
    
    final params = <String, dynamic>{};
    if (id != null) params['id'] = id;
    if (path != null) params['path'] = path;
    
    final url = AppConfig.buildMovieBoxUrl('detail', params);
    final response = await http.get(
      Uri.parse(url),
      headers: AppConfig.movieBoxHeaders,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load detail: ${response.statusCode}');
  }
  
  // Get recommendations
  static Future<Map<String, dynamic>> getRecommendations({
    required String id,
    int page = 1,
    int perPage = 12,
  }) async {
    final url = AppConfig.buildMovieBoxUrl('recommendations', {
      'id': id,
      'page': page,
      'perPage': perPage,
    });
    
    final response = await http.get(
      Uri.parse(url),
      headers: AppConfig.movieBoxHeaders,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load recommendations: ${response.statusCode}');
  }
  
  // Get streaming URLs
  static Future<Map<String, dynamic>> getPlayUrls({
    required String id,
    required String path,
    required int season,
    required int episode,
  }) async {
    final url = AppConfig.buildMovieBoxUrl('play', {
      'id': id,
      'path': path,
      'season': season,
      'episode': episode,
    });
    
    final response = await http.get(
      Uri.parse(url),
      headers: AppConfig.movieBoxHeaders,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load play URLs: ${response.statusCode}');
  }
  
  // Get subtitles
  static Future<Map<String, dynamic>> getCaptions({
    required String id,
    required String subjectId,
    required String path,
    String format = 'MP4',
  }) async {
    final url = AppConfig.buildMovieBoxUrl('captions', {
      'id': id,
      'subjectId': subjectId,
      'path': path,
      'format': format,
    });
    
    final response = await http.get(
      Uri.parse(url),
      headers: AppConfig.movieBoxHeaders,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load captions: ${response.statusCode}');
  }
  
  // Get cache stats
  static Future<Map<String, dynamic>> getCacheStats() async {
    final url = AppConfig.buildMovieBoxUrl('cache', {'sub': 'stats'});
    final response = await http.get(
      Uri.parse(url),
      headers: AppConfig.movieBoxHeaders,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load cache stats: ${response.statusCode}');
  }
  
  // Clear cache
  static Future<Map<String, dynamic>> clearCache() async {
    final url = AppConfig.buildMovieBoxUrl('cache', {'sub': 'clear'});
    final response = await http.get(
      Uri.parse(url),
      headers: AppConfig.movieBoxHeaders,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to clear cache: ${response.statusCode}');
  }
}
