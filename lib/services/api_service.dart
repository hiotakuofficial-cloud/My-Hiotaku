import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';

class ApiService {
  // Working URL confirmed
  static const String baseUrl = 'https://v1-w3sc.onrender.com';
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'User-Agent': 'HiotakuApp/1.0',
    'Accept': 'application/json',
  };

  // Main API (api.php) - English/Japanese anime
  static Future<InfoResponse> getInfo() async {
    final response = await http.get(Uri.parse('$baseUrl/api.php?action=info'), headers: _headers);
    if (response.statusCode == 200) {
      return InfoResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get API info');
  }

  static Future<HomeResponse> getHome([int page = 1]) async {
    final url = '$baseUrl/api.php?action=home&page=$page';
    print('DEBUG: Calling URL: $url');
    
    try {
      final response = await http.get(
        Uri.parse(url), 
        headers: _headers
      ).timeout(Duration(seconds: 30)); // 30 second timeout
      
      if (response.statusCode == 200) {
        return HomeResponse.fromJson(jsonDecode(response.body));
      }
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to load home data: $e');
    }
  }

  static Future<SearchResponse> searchAnime(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/api.php?action=search&q=${Uri.encodeComponent(query)}'), headers: _headers);
    if (response.statusCode == 200) {
      return SearchResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Search failed');
  }

  static Future<EpisodesResponse> getEpisodes(String animeId) async {
    final response = await http.get(Uri.parse('$baseUrl/api.php?action=episodes&id=${Uri.encodeComponent(animeId)}'), headers: _headers);
    if (response.statusCode == 200) {
      return EpisodesResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load episodes');
  }

  static Future<VideoSourcesResponse> getVideoSources(String animeId, String episodeId) async {
    final response = await http.get(Uri.parse('$baseUrl/api.php?action=video&id=${Uri.encodeComponent(animeId)}&ep=${Uri.encodeComponent(episodeId)}'), headers: _headers);
    if (response.statusCode == 200) {
      return VideoSourcesResponse.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to get video sources');
  }

  static Future<PaginatedResponse<AnimeItem>> getPopular([int page = 1]) async {
    final response = await http.get(Uri.parse('$baseUrl/api.php?action=popular&page=$page'), headers: _headers);
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(jsonDecode(response.body), (json) => AnimeItem.fromJson(json));
    }
    throw Exception('Failed to load popular anime');
  }

  static Future<PaginatedResponse<AnimeItem>> getTopUpcoming([int page = 1]) async {
    final response = await http.get(Uri.parse('$baseUrl/api.php?action=top-upcoming&page=$page'), headers: _headers);
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(jsonDecode(response.body), (json) => AnimeItem.fromJson(json));
    }
    throw Exception('Failed to load upcoming anime');
  }

  static Future<PaginatedResponse<AnimeItem>> getMovies([int page = 1]) async {
    final response = await http.get(Uri.parse('$baseUrl/api.php?action=movie&page=$page'), headers: _headers);
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(jsonDecode(response.body), (json) => AnimeItem.fromJson(json));
    }
    throw Exception('Failed to load movies');
  }

  static Future<PaginatedResponse<AnimeItem>> getSubbed([int page = 1]) async {
    final response = await http.get(Uri.parse('$baseUrl/api.php?action=subbed&page=$page'), headers: _headers);
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(jsonDecode(response.body), (json) => AnimeItem.fromJson(json));
    }
    throw Exception('Failed to load subbed anime');
  }

  static Future<PaginatedResponse<AnimeItem>> getDubbed([int page = 1]) async {
    final response = await http.get(Uri.parse('$baseUrl/api.php?action=dubbed&page=$page'), headers: _headers);
    if (response.statusCode == 200) {
      return PaginatedResponse.fromJson(jsonDecode(response.body), (json) => AnimeItem.fromJson(json));
    }
    throw Exception('Failed to load dubbed anime');
  }

  // Hindi API (hindi.php) - Hindi dubbed anime
  static Future<List<AnimeItem>> getHindiHome() async {
    final response = await http.get(Uri.parse('$baseUrl/hindi.php?action=home'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AnimeItem.fromJson(e)).toList();
    }
    throw Exception('Failed to load Hindi anime');
  }

  static Future<List<AnimeItem>> searchHindiAnime(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/hindi.php?action=search&q=${Uri.encodeComponent(query)}'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AnimeItem.fromJson(e)).toList();
    }
    throw Exception('Hindi search failed');
  }

  // Hindi V2 API (hindiv2.php) - Alternative Hindi source
  static Future<List<AnimeItem>> getHindiV2Home() async {
    final response = await http.get(Uri.parse('$baseUrl/hindiv2.php?action=home'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AnimeItem.fromJson(e)).toList();
    }
    throw Exception('Failed to load Hindi V2 anime');
  }

  static Future<List<AnimeItem>> searchHindiV2Anime(String query) async {
    final response = await http.get(Uri.parse('$baseUrl/hindiv2.php?action=search&q=${Uri.encodeComponent(query)}'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AnimeItem.fromJson(e)).toList();
    }
    throw Exception('Hindi V2 search failed');
  }

  // Combined methods for app
  static Future<Map<String, dynamic>> getAllContent() async {
    try {
      final futures = await Future.wait([
        getHome().catchError((e) => null),
        getHindiHome().catchError((e) => <AnimeItem>[]),
        getHindiV2Home().catchError((e) => <AnimeItem>[]),
      ]);

      return {
        'success': true,
        'english': futures[0],
        'hindi': futures[1],
        'hindi_v2': futures[2],
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Legacy compatibility methods
  static Future<Map<String, dynamic>> getAnimeDetails(String animeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api.php?action=details&id=${Uri.encodeComponent(animeId)}'), headers: _headers);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'error': 'Failed to load anime details'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getStream(String episodeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api.php?action=stream&id=${Uri.encodeComponent(episodeId)}'), headers: _headers);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'error': 'Failed to get stream'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
