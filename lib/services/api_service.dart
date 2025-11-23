import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';
import 'api_cache.dart';

class ApiService {
  static const String baseUrl = 'https://v1-w3sc.onrender.com';
  static final http.Client _client = http.Client();
  
  static Map<String, String> get _headers => {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/91.0.4472.120 Mobile Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Connection': 'keep-alive',
  };

  static Future<HomeResponse> getHome([int page = 1]) async {
    final cacheKey = 'home_$page';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null) return cached;

    final url = '$baseUrl/api.php?action=home&page=$page';
    
    try {
      final response = await _client.get(Uri.parse(url), headers: _headers)
          .timeout(Duration(seconds: 30));
      
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
