import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../../../../config.dart';

// Data Models
class AnimeItem {
  final int id;
  final String title;
  final String thumbnail;
  final String? slug;
  final String? date;

  AnimeItem({
    required this.id,
    required this.title,
    required this.thumbnail,
    this.slug,
    this.date,
  });

  factory AnimeItem.fromJson(Map<String, dynamic> json) {
    return AnimeItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      slug: json['slug'],
      date: json['date'],
    );
  }
}

class DownloadLink {
  final String url;
  final String? episode;
  final String? quality;
  final String? platform;
  final String? size;
  final String? type;
  final String? format;

  DownloadLink({
    required this.url,
    this.episode,
    this.quality,
    this.platform,
    this.size,
    this.type,
    this.format,
  });

  factory DownloadLink.fromJson(Map<String, dynamic> json) {
    return DownloadLink(
      url: json['url'] ?? '',
      episode: json['episode'],
      quality: json['quality'],
      platform: json['platform'],
      size: json['size'],
      type: json['type'],
      format: json['format'],
    );
  }
}

class ZipDownload {
  final String url;
  final String quality;
  final String type;
  final String platform;
  final String text;

  ZipDownload({
    required this.url,
    required this.quality,
    required this.type,
    required this.platform,
    required this.text,
  });

  factory ZipDownload.fromJson(Map<String, dynamic> json) {
    return ZipDownload(
      url: json['url'] ?? '',
      quality: json['quality'] ?? '',
      type: json['type'] ?? '',
      platform: json['platform'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

class AnimeDetails {
  final int id;
  final String title;
  final String? content;
  final Map<String, dynamic> info;
  final String? languageType;
  final int totalDownloads;
  final List<DownloadLink> downloads;
  final List<String> downloadLinks;

  AnimeDetails({
    required this.id,
    required this.title,
    this.content,
    required this.info,
    this.languageType,
    required this.totalDownloads,
    required this.downloads,
    required this.downloadLinks,
  });

  factory AnimeDetails.fromJson(Map<String, dynamic> json) {
    // Handle info field - can be List or Map
    Map<String, dynamic> infoMap = {};
    if (json['info'] is Map<String, dynamic>) {
      infoMap = json['info'];
    } else if (json['info'] is List && (json['info'] as List).isNotEmpty) {
      // Convert list to map if needed
      infoMap = {'data': json['info']};
    }
    
    return AnimeDetails(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'],
      info: infoMap,
      languageType: json['language_type'],
      totalDownloads: json['total_downloads'] ?? 0,
      downloads: (json['downloads'] as List?)
          ?.map((e) => DownloadLink.fromJson(e))
          .toList() ?? [],
      downloadLinks: (json['download_links'] as List?)
          ?.map((e) => e.toString())
          .toList() ?? [],
    );
  }
}

// API Response Models
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int? total;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.total,
  });
}

class DownloadHandler {
  // API Configuration - Use environment variables like other services
  static String get baseUrl => '${AppConfig.animeApiBaseUrl}/download/apiv2.php';
  static String get token => AppConfig.apiToken;
  static const Duration _timeout = Duration(seconds: 30);
  
  static Map<String, String> get _headers => {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
    'Accept': 'application/json',
    'Connection': 'keep-alive',
  };

  // Content Types
  static const String hindiDub = 'hindi-dub';
  static const String hindiSub = 'hindi-sub';
  static const String engSub = 'eng-sub';
  static const String movie = 'movie';
  static const String japEng = 'jap-eng';

  // 1. Get Home Content
  static Future<ApiResponse<List<AnimeItem>>> getHomeContent({String? type}) async {
    try {
      final params = {
        'action': 'home',
        'token': token,
        if (type != null) 'type': type,
      };
      
      final response = await _makeRequest(params);
      
      if (response['success'] == true) {
        final results = (response['results'] as List?)
            ?.map((e) => AnimeItem.fromJson(e))
            .toList() ?? [];
        
        return ApiResponse(
          success: true,
          data: results,
          total: response['total'],
        );
      } else {
        return ApiResponse(
          success: false,
          error: response['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // 2. Search Anime
  static Future<ApiResponse<List<AnimeItem>>> searchAnime(String query) async {
    try {
      if (query.trim().isEmpty) {
        return ApiResponse(
          success: false,
          error: 'Search query cannot be empty',
        );
      }

      final params = {
        'action': 'search',
        'q': query.trim(),
        'token': token,
      };
      
      final response = await _makeRequest(params);
      
      if (response['success'] == true) {
        final results = (response['results'] as List?)
            ?.map((e) => AnimeItem.fromJson(e))
            .toList() ?? [];
        
        return ApiResponse(
          success: true,
          data: results,
          total: response['total'],
        );
      } else {
        return ApiResponse(
          success: false,
          error: response['error'] ?? 'Search failed',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // 3. Get Download Links
  static Future<ApiResponse<AnimeDetails>> getDownloadLinks(int id, {String? type}) async {
    try {
      if (id <= 0) {
        return ApiResponse(
          success: false,
          error: 'Invalid anime ID',
        );
      }

      final params = {
        'action': 'get',
        'id': id.toString(),
        'token': token,
        if (type != null) 'type': type,
      };
      
      final response = await _makeRequest(params);
      
      if (response['success'] == true) {
        final animeDetails = AnimeDetails.fromJson(response);
        
        return ApiResponse(
          success: true,
          data: animeDetails,
        );
      } else {
        return ApiResponse(
          success: false,
          error: response['error'] ?? 'Failed to get download links',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // 4. Get Anime Details
  static Future<ApiResponse<AnimeDetails>> getAnimeDetails(int id) async {
    try {
      if (id <= 0) {
        return ApiResponse(
          success: false,
          error: 'Invalid anime ID',
        );
      }

      final params = {
        'action': 'anime',
        'id': id.toString(),
        'token': token,
      };
      
      final response = await _makeRequest(params);
      
      if (response['success'] == true) {
        final animeDetails = AnimeDetails.fromJson(response);
        
        return ApiResponse(
          success: true,
          data: animeDetails,
        );
      } else {
        return ApiResponse(
          success: false,
          error: response['error'] ?? 'Failed to get anime details',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // 6. Get ZIP Downloads
  static Future<ApiResponse<List<ZipDownload>>> getZipDownloads(int id) async {
    try {
      if (id <= 0) {
        return ApiResponse(
          success: false,
          error: 'Invalid anime ID',
        );
      }

      final params = {
        'action': 'getzip',
        'id': id.toString(),
        'token': token,
      };
      
      final response = await _makeRequest(params);
      
      if (response['success'] == true) {
        final zipDownloads = (response['zip_downloads'] as List?)
            ?.map((e) => ZipDownload.fromJson(e))
            .toList() ?? [];
        
        return ApiResponse(
          success: true,
          data: zipDownloads,
          total: response['total_zip_links'],
        );
      } else {
        return ApiResponse(
          success: false,
          error: response['error'] ?? 'Failed to get ZIP downloads',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // 5. Extract Download Links
  static Future<ApiResponse<Map<String, dynamic>>> extractDownloadLinks(String url) async {
    try {
      if (url.trim().isEmpty) {
        return ApiResponse(
          success: false,
          error: 'URL cannot be empty',
        );
      }

      final params = {
        'action': 'download',
        'url': url.trim(),
        'token': token,
      };
      
      final response = await _makeRequest(params);
      
      if (response['success'] == true) {
        return ApiResponse(
          success: true,
          data: response,
        );
      } else {
        return ApiResponse(
          success: false,
          error: response['error'] ?? 'Failed to extract download links',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  // Private method to make HTTP requests
  static Future<Map<String, dynamic>> _makeRequest(Map<String, String> params) async {
    try {
      final uri = Uri.parse(baseUrl).replace(queryParameters: params);
      
      final response = await http.get(uri, headers: _headers).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else {
          throw const FormatException('Invalid JSON response format');
        }
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException {
      throw const SocketException('No internet connection');
    } on TimeoutException {
      throw TimeoutException('Request timeout', _timeout);
    } on FormatException catch (e) {
      throw FormatException('Invalid response format: ${e.message}');
    } on HttpException {
      rethrow;
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }

  // Helper methods for common content types
  static Future<ApiResponse<List<AnimeItem>>> getHindiDubbed() => 
      getHomeContent(type: hindiDub);
  
  static Future<ApiResponse<List<AnimeItem>>> getMovies() => 
      getHomeContent(type: movie);
  
  static Future<ApiResponse<List<AnimeItem>>> getHindiSubbed() => 
      getHomeContent(type: hindiSub);
  
  static Future<ApiResponse<List<AnimeItem>>> getEngSubbed() => 
      getHomeContent(type: engSub);

  // Utility methods
  static bool isValidContentType(String type) {
    return [hindiDub, hindiSub, engSub, movie, japEng].contains(type);
  }

  static String getContentTypeDisplayName(String type) {
    switch (type) {
      case hindiDub: return 'Hindi Dubbed';
      case hindiSub: return 'Hindi Subbed';
      case engSub: return 'English Subbed';
      case movie: return 'Movies';
      case japEng: return 'Japanese-English';
      default: return type;
    }
  }
}
