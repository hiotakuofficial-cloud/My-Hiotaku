import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';

class ApiService {
  static const String baseUrl = 'https://v1-w3sc.onrender.com';
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'User-Agent': 'HiotakuApp/1.0',
    'Accept': 'application/json',
  };

  static Future<T> _makeRequest<T>(String endpoint, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=$endpoint'), headers: _headers);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return fromJson(json);
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('API Error: $e');
    }
  }

  // API Info
  static Future<InfoResponse> getInfo() async {
    return _makeRequest('info', (json) => InfoResponse.fromJson(json));
  }

  // Home Page
  static Future<HomeResponse> getHome([int page = 1, String section = 'trending']) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=home&page=$page&section=$section'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return HomeResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load home data');
  }

  // Search
  static Future<SearchResponse> searchAnime(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=search&q=${Uri.encodeComponent(query)}'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return SearchResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Search failed');
  }

  // Anime Details
  static Future<AnimeDetailsResponse> getAnimeDetails(String animeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=details&id=${Uri.encodeComponent(animeId)}'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return AnimeDetailsResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load anime details');
  }

  // Episodes
  static Future<EpisodesResponse> getEpisodes(String animeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=episodes&id=${Uri.encodeComponent(animeId)}'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return EpisodesResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load episodes');
  }

  // Video Sources
  static Future<VideoSourcesResponse> getVideoSources(String animeId, String episodeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=video&id=${Uri.encodeComponent(animeId)}&ep=${Uri.encodeComponent(episodeId)}'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return VideoSourcesResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get video sources');
  }

  // Stream URL
  static Future<VideoSourcesResponse> getStream(String episodeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=stream&id=${Uri.encodeComponent(episodeId)}'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return VideoSourcesResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get stream');
  }

  // Popular Anime
  static Future<PaginatedResponse<AnimeItem>> getPopular([int page = 1]) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=popular&page=$page'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body), 
        (json) => AnimeItem.fromJson(json)
      );
    }
    throw Exception('Failed to load popular anime');
  }

  // Top Upcoming
  static Future<PaginatedResponse<AnimeItem>> getTopUpcoming([int page = 1]) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=top-upcoming&page=$page'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body), 
        (json) => AnimeItem.fromJson(json)
      );
    }
    throw Exception('Failed to load upcoming anime');
  }

  // Genre
  static Future<PaginatedResponse<AnimeItem>> getGenre(String type, [int page = 1]) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=genre&type=${Uri.encodeComponent(type)}&page=$page'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body), 
        (json) => AnimeItem.fromJson(json)
      );
    }
    throw Exception('Failed to load genre');
  }

  // Movies
  static Future<PaginatedResponse<AnimeItem>> getMovies([int page = 1]) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=movie&page=$page'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body), 
        (json) => AnimeItem.fromJson(json)
      );
    }
    throw Exception('Failed to load movies');
  }

  // Subbed Anime
  static Future<PaginatedResponse<AnimeItem>> getSubbed([int page = 1]) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=subbed&page=$page'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body), 
        (json) => AnimeItem.fromJson(json)
      );
    }
    throw Exception('Failed to load subbed anime');
  }

  // Dubbed Anime
  static Future<PaginatedResponse<AnimeItem>> getDubbed([int page = 1]) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=dubbed&page=$page'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body), 
        (json) => AnimeItem.fromJson(json)
      );
    }
    throw Exception('Failed to load dubbed anime');
  }

  // Special Anime
  static Future<PaginatedResponse<AnimeItem>> getSpecial([int page = 1]) async {
    final response = await http.get(
      Uri.parse('$baseUrl?action=special&page=$page'), 
      headers: _headers
    );
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(
        jsonDecode(response.body), 
        (json) => AnimeItem.fromJson(json)
      );
    }
    throw Exception('Failed to load special anime');
  }

  // Legacy methods for backward compatibility
  static Future<Map<String, dynamic>> getAnime(String animeId) async {
    try {
      final details = await getAnimeDetails(animeId);
      return {
        'success': true,
        'data': {
          'id': details.id,
          'title': details.title,
          'poster': details.poster,
          'description': details.description,
          'status': details.status,
        }
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getAllSections() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=sections'), headers: _headers);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'error': 'Failed to load sections'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
