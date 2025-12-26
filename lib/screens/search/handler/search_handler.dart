import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class SearchResult {
  final String id;
  final String title;
  final String poster;
  final String type; // 'english' or 'hindi'
  final String? description;

  SearchResult({
    required this.id,
    required this.title,
    required this.poster,
    required this.type,
    this.description,
  });

  factory SearchResult.fromEnglishApi(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      poster: json['poster'] ?? '',
      type: 'english',
    );
  }

  factory SearchResult.fromHindiApi(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      poster: json['thumbnail'] ?? '',
      type: 'hindi',
      description: json['description'],
    );
  }
}

class CombinedSearchResponse {
  final List<SearchResult> englishResults;
  final List<SearchResult> hindiResults;
  final bool success;
  final String? error;

  CombinedSearchResponse({
    required this.englishResults,
    required this.hindiResults,
    required this.success,
    this.error,
  });

  List<SearchResult> get allResults => [...englishResults, ...hindiResults];
  int get totalResults => englishResults.length + hindiResults.length;
}

class SearchHandler {
  static final http.Client _client = http.Client();
  static const Duration _timeout = Duration(seconds: 30);

  static Future<CombinedSearchResponse> searchAnime(String query) async {
    if (query.trim().isEmpty) {
      return CombinedSearchResponse(
        englishResults: [],
        hindiResults: [],
        success: false,
        error: 'Search query cannot be empty',
      );
    }

    List<SearchResult> englishResults = [];
    List<SearchResult> hindiResults = [];
    String? error;

    // Search both APIs simultaneously
    final futures = await Future.wait([
      _searchEnglishApi(query),
      _searchHindiApi(query),
    ], eagerError: false);

    // Process English API results
    final englishResponse = futures[0];
    if (englishResponse['success'] == true) {
      final results = englishResponse['results'] as List?;
      if (results != null) {
        englishResults = results
            .map((item) => SearchResult.fromEnglishApi(item))
            .toList();
      }
    }

    // Process Hindi API results
    final hindiResponse = futures[1];
    if (hindiResponse['success'] == true) {
      final results = hindiResponse['results'] as List?;
      if (results != null) {
        hindiResults = results
            .map((item) => SearchResult.fromHindiApi(item))
            .toList();
      }
    }

    // Check if both failed
    if (englishResults.isEmpty && hindiResults.isEmpty) {
      error = 'No results found for "$query"';
    }

    return CombinedSearchResponse(
      englishResults: englishResults,
      hindiResults: hindiResults,
      success: englishResults.isNotEmpty || hindiResults.isNotEmpty,
      error: error,
    );
  }

  static Future<Map<String, dynamic>> _searchEnglishApi(String query) async {
    try {
      final url = AppConfig.buildUrl('search', {
        'q': query,
        'page': 1,
      });

      final response = await _client
          .get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'] ?? false,
          'results': data['results'] ?? [],
        };
      } else {
        return {
          'success': false,
          'error': 'Search failed. Please try again.',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': 'English API timeout',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Search failed. Please try again.',
      };
    }
  }

  static Future<Map<String, dynamic>> _searchHindiApi(String query) async {
    try {
      final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=search&q=${Uri.encodeComponent(query)}&token=${AppConfig.apiToken}';

      final response = await _client
          .get(Uri.parse(url), headers: AppConfig.defaultHeaders)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Hindi API returns array directly, not wrapped in success object
        if (data is List) {
          return {
            'success': true,
            'results': data,
          };
        } else if (data is Map && data['success'] == false) {
          return {
            'success': false,
            'error': 'Search failed. Please try again.',
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid Hindi API response format',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Search failed. Please try again.',
        };
      }
    } on TimeoutException {
      return {
        'success': false,
        'error': 'Hindi API timeout',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Search failed. Please try again.',
      };
    }
  }

  static void dispose() {
    _client.close();
  }
}
