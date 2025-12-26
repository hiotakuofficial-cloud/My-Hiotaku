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
      throw Exception('Service temporarily unavailable');
    } on SocketException {
      throw Exception('Network error: Check internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Request failed');
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
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Search failed');
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
      throw Exception('Service temporarily unavailable');
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

  // Get popular anime
  static Future<HomeResponse> getPopular([int page = 1]) async {
    final cacheKey = 'popular_$page';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    final url = AppConfig.buildUrl('popular', {'page': page});
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHomeResponse(jsonData);
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to get popular anime: $e');
    }
  }

  // Get top upcoming anime
  static Future<HomeResponse> getTopUpcoming([int page = 1]) async {
    final cacheKey = 'top_upcoming_$page';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    final url = AppConfig.buildUrl('top-upcoming', {'page': page});
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHomeResponse(jsonData);
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to get top upcoming anime: $e');
    }
  }

  // Get anime movies
  static Future<HomeResponse> getMovies([int page = 1]) async {
    final cacheKey = 'movies_$page';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    final url = AppConfig.buildUrl('movie', {'page': page});
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHomeResponse(jsonData);
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to get movies: $e');
    }
  }

  // Get subbed anime
  static Future<HomeResponse> getSubbed([int page = 1]) async {
    final cacheKey = 'subbed_$page';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    final url = AppConfig.buildUrl('subbed', {'page': page});
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHomeResponse(jsonData);
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to get subbed anime: $e');
    }
  }

  // Get dubbed anime
  static Future<HomeResponse> getDubbed([int page = 1]) async {
    final cacheKey = 'dubbed_$page';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    final url = AppConfig.buildUrl('dubbed', {'page': page});
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHomeResponse(jsonData);
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to get dubbed anime: $e');
    }
  }

  // Get Hindi anime from hindiv2.php
  static Future<HomeResponse> getHindiAnime([int page = 1]) async {
    final cacheKey = 'hindi_home_$page';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    // Use hindiv2.php endpoint
    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=home&token=${AppConfig.apiToken}';
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHindiResponse(jsonData, 'home');
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to get Hindi anime: $e');
    }
  }

  // Get Hindi dubbed anime list
  static Future<HomeResponse> getHindiDubbed([int page = 1]) async {
    final cacheKey = 'hindi_dubbed_$page';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=hindi&token=${AppConfig.apiToken}';
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHindiResponse(jsonData, 'hindi');
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to get Hindi dubbed anime: $e');
    }
  }

  // Search Hindi anime
  static Future<HomeResponse> searchHindiAnime(String query) async {
    final cacheKey = 'hindi_search_$query';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=search&q=${Uri.encodeComponent(query)}&token=${AppConfig.apiToken}';
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHindiResponse(jsonData, 'search');
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to search Hindi anime: $e');
    }
  }

  // Get Hindi anime details
  static Future<Map<String, dynamic>> getHindiAnimeDetails(String animeId) async {
    final cacheKey = 'hindi_details_$animeId';
    final cached = ApiCache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=info&id=$animeId&token=${AppConfig.apiToken}';
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to get Hindi anime details: $e');
    }
  }

  // Get Hindi anime episodes
  static Future<List<Map<String, dynamic>>> getHindiEpisodes(String animeId) async {
    final cacheKey = 'hindi_episodes_$animeId';
    final cached = ApiCache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null) return cached;

    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=getep&id=$animeId&token=${AppConfig.apiToken}';
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as List;
        final result = jsonData.cast<Map<String, dynamic>>();
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to get Hindi episodes: $e');
    }
  }

  // Get recommendations based on anime ID
  static Future<HomeResponse> getRecommendations(String animeId) async {
    // Use popular anime as recommendations for now
    // In future, can be enhanced with ML-based recommendations
    final url = AppConfig.buildUrl('popular', {'page': 1, 'limit': 10});
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final result = _parseHomeResponse(jsonData);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } on SocketException {
      throw Exception('Network error: Check internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to get recommendations: $e');
    }
  }

  // Get English anime episodes
  static Future<List<Map<String, dynamic>>> getEpisodes(String animeId) async {
    final url = AppConfig.buildUrl('episodes', {'id': animeId});
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData['success'] == true && jsonData['episodes'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['episodes']);
        }
        throw Exception('No episodes found');
      }
      throw Exception('Service temporarily unavailable');
    } on SocketException {
      throw Exception('Network error: Check internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to get episodes: $e');
    }
  }

  // Get English episode stream URL
  static Future<Map<String, dynamic>> getStreamUrl(String animeId, String episodeId) async {
    final url = AppConfig.buildUrl('stream', {'id': animeId, 'episode': episodeId});
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        
        if (jsonData['success'] == true) {
          return jsonData;
        }
        throw Exception('Stream not available');
      }
      throw Exception('Service temporarily unavailable');
    } on SocketException {
      throw Exception('Network error: Check internet connection');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to get stream URL: $e');
    }
  }

  // Get Hindi episode stream URL
  static Future<Map<String, dynamic>> getHindiStreamUrl(String animeId, String episodeId) async {
    final cacheKey = 'hindi_stream_${animeId}_$episodeId';
    final cached = ApiCache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=playep&id=$animeId&ep=$episodeId&token=${AppConfig.apiToken}';
    
    try {
      final response = await _client.get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(AppConfig.requestTimeout);
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        ApiCache.set(cacheKey, result);
        return result;
      }
      throw Exception('Service temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to get Hindi stream URL: $e');
    }
  }

  // Parse Hindi API response (different structure)
  static HomeResponse _parseHindiResponse(dynamic jsonData, String section) {
    if (jsonData is List) {
      final List<AnimeItem> animeList = jsonData.map((item) {
        return AnimeItem(
          id: item['id']?.toString() ?? '',
          title: item['title'] ?? 'Unknown',
          poster: item['thumbnail'] ?? '',
          type: item['type'] ?? 'Hindi Dubbed',
          description: item['description'] ?? '',
        );
      }).toList();
      
      return HomeResponse(
        section: section,
        total: animeList.length,
        page: 1,
        hasMore: false,
        data: animeList,
      );
    }
    throw Exception('Invalid Hindi API response structure');
  }
}
