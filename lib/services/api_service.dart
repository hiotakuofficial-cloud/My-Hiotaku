import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';
import '../config.dart';
import 'api_cache.dart';

class ApiService {
  static final http.Client _client = http.Client();

  static Future<HomeResponse> getHome([int page = 1]) async {
    final cacheKey = 'home_$page';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    // Build URL with token authentication
    final url = AppConfig.buildUrl('home', {'page': page});
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHomeResponse(jsonData);
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('HTTP ${response.statusCode}');
    } on SocketException {
      throw Exception('Network error: Check internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // Search anime with token
  static Future<HomeResponse> searchAnime(String query, [int page = 1]) async {
    final cacheKey = 'search_${query}_$page';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    final url = AppConfig.buildUrl('search', {
      'query': query,
      'page': page,
    });
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHomeResponse(jsonData);
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Search failed: $e');
    }
  }

  // Get anime details with token
  static Future<Map<String, dynamic>> getAnimeDetails(String animeId) async {
    final cacheKey = 'details_$animeId';
    final cached = ApiCache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    final url = AppConfig.buildUrl('details', {'id': animeId});
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        ApiCache.set(cacheKey, jsonData);
        return jsonData;
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Details failed: $e');
    }
  }

  static HomeResponse _parseHomeResponse(dynamic jsonData) {
    if (jsonData is Map<String, dynamic>) {
      if (jsonData.containsKey('success') && jsonData.containsKey('data')) {
        return HomeResponse.fromJson(jsonData);
      } else if (jsonData.containsKey('data')) {
        return HomeResponse(
          section: 'home',
          total: (jsonData['data'] as List?)?.length ?? 0,
          page: 1,
          hasMore: false,
          data: (jsonData['data'] as List?)?.map((e) => AnimeItem.fromJson(e)).toList() ?? []
        );
      }
    } else if (jsonData is List) {
      return HomeResponse(
        section: 'home',
        total: jsonData.length,
        page: 1,
        hasMore: false,
        data: jsonData.map((e) => AnimeItem.fromJson(e)).toList()
      );
    }
    throw Exception('Unknown response structure');
  }
}
