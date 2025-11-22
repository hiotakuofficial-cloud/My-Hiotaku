import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://v1-w3sc.onrender.com';
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'User-Agent': 'HiotakuApp/1.0',
    'Accept': 'application/json',
  };
  
  // Main API endpoints from api.php
  static Future<Map<String, dynamic>> getInfo() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=info'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to get info'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getHome() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=home'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load home data'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> searchAnime(String query) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=search&q=${Uri.encodeComponent(query)}'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Search failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getAnime(String animeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=anime&id=${Uri.encodeComponent(animeId)}'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load anime'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getAnimeDetails(String animeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=details&id=${Uri.encodeComponent(animeId)}'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load anime details'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getEpisodes(String animeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=episodes&id=${Uri.encodeComponent(animeId)}'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load episodes'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getStream(String episodeId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=stream&id=${Uri.encodeComponent(episodeId)}'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to get stream'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getVideoUrl(String animeId, int episode) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=video&id=${Uri.encodeComponent(animeId)}&ep=$episode'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to get video URL'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getPopular([int page = 1]) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=popular&page=$page'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load popular anime'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getTopUpcoming([int page = 1]) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=top-upcoming&page=$page'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load upcoming anime'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getGenre(String type, [int page = 1]) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=genre&type=${Uri.encodeComponent(type)}&page=$page'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load genre'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getMovies([int page = 1]) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=movie&page=$page'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load movies'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getSubbed([int page = 1]) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=subbed&page=$page'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load subbed anime'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getDubbed([int page = 1]) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=dubbed&page=$page'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load dubbed anime'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getSpecial([int page = 1]) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=special&page=$page'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load special anime'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> getAllSections() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=sections'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to load sections'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> analyzeDatabase() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=database'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Failed to analyze database'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
  
  static Future<Map<String, dynamic>> testAll() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl?action=test'), headers: _headers);
      if (response.statusCode == 200) return json.decode(response.body);
      return {'success': false, 'error': 'Test failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
