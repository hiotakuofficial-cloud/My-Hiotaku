import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import '../../../config.dart';

class PlayerHandler {
  
  // Show toast helper
  static void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 12.0,
    );
    print(message);
  }
  
  // Get episodes based on type (Hindi or English)
  static Future<List<Map<String, dynamic>>> getEpisodes({
    required String animeId,
    required bool isHindi,
  }) async {
    if (isHindi) {
      return await _getHindiEpisodes(animeId);
    } else {
      return await _getEnglishEpisodes(animeId);
    }
  }
  
  // Get Hindi episodes
  static Future<List<Map<String, dynamic>>> _getHindiEpisodes(String animeId) async {
    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=getep&id=$animeId&token=${AppConfig.apiToken}';
    
    try {
      _showToast('🔄 Loading Hindi episodes...');
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _showToast('✅ Found ${data.length} Hindi episodes');
        
        return data.map((episode) => {
          'episode_number': int.tryParse(episode['episode'].toString()) ?? 1,
          'episode_id': episode['episode_id'].toString(),
          'title': episode['title'] ?? 'Episode ${episode['episode']}',
          'type': 'hindi',
        }).toList();
      } else {
        _showToast('❌ Failed to load Hindi episodes', isError: true);
      }
      return [];
    } catch (e) {
      _showToast('❌ Hindi episodes error: $e', isError: true);
      return [];
    }
  }
  
  // Get English episodes
  static Future<List<Map<String, dynamic>>> _getEnglishEpisodes(String animeId) async {
    final url = AppConfig.buildUrl('episodes', {'id': animeId});
    
    try {
      _showToast('🔄 Loading English episodes...');
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['episodes'] != null) {
          final List<dynamic> episodes = data['episodes'];
          _showToast('✅ Found ${episodes.length} English episodes');
          
          return episodes.map((episode) => {
            'episode_number': episode['episode_number'] ?? 1,
            'episode_id': episode['episode_id'].toString(),
            'title': episode['title'] ?? 'Episode ${episode['episode_number']}',
            'type': 'english',
          }).toList();
        }
      } else {
        _showToast('❌ Failed to load English episodes', isError: true);
      }
      return [];
    } catch (e) {
      _showToast('❌ English episodes error: $e', isError: true);
      return [];
    }
  }
  
  // Get stream URL based on type
  static Future<String?> getStreamUrl({
    required String animeId,
    required String episodeId,
    required bool isHindi,
    String language = 'sub',
  }) async {
    if (isHindi) {
      return await _getHindiStreamUrl(animeId, episodeId);
    } else {
      return await _getEnglishStreamUrl(animeId, episodeId, language);
    }
  }
  
  // Get Hindi stream URL
  static Future<String?> _getHindiStreamUrl(String animeId, String episodeId) async {
    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=playep&id=$animeId&ep=$episodeId&token=${AppConfig.apiToken}';
    
    try {
      _showToast('🔄 Getting Hindi stream...');
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['streamUrl'] != null) {
          _showToast('✅ Hindi stream ready!');
          return data['streamUrl'];
        }
        
        if (data['urls'] != null && data['urls'].isNotEmpty) {
          _showToast('✅ Hindi stream ready!');
          return data['urls'][0];
        }
        
        _showToast('❌ No Hindi stream found', isError: true);
      } else {
        _showToast('❌ Hindi stream failed', isError: true);
      }
      return null;
    } catch (e) {
      _showToast('❌ Hindi stream error: $e', isError: true);
      return null;
    }
  }
  
  // Get English stream URL
  static Future<String?> _getEnglishStreamUrl(String animeId, String episodeId, String language) async {
    final url = AppConfig.buildUrl('video', {'id': animeId, 'ep': episodeId});
    
    try {
      _showToast('🔄 Getting English stream...');
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['sources'] != null) {
          final sources = data['sources'];
          
          // Get sources for requested language (sub/dub)
          if (sources[language] != null && sources[language] is List) {
            final languageSources = sources[language] as List;
            if (languageSources.isNotEmpty) {
              _showToast('✅ English stream ready!');
              return languageSources[0]['url'];
            }
          }
          
          // Fallback to first available language
          for (String lang in ['sub', 'dub']) {
            if (sources[lang] != null && sources[lang] is List) {
              final langSources = sources[lang] as List;
              if (langSources.isNotEmpty) {
                _showToast('✅ English stream ready!');
                return langSources[0]['url'];
              }
            }
          }
        }
      } else {
        _showToast('❌ English stream failed', isError: true);
      }
      return null;
    } catch (e) {
      _showToast('❌ English stream error: $e', isError: true);
      return null;
    }
  }
  
  // Generate player data for HTML
  static Map<String, dynamic> generatePlayerData({
    required String animeTitle,
    required int episodeNumber,
    required String streamUrl,
    required bool isHindi,
  }) {
    return {
      'title': animeTitle,
      'episode': episodeNumber,
      'streamUrl': streamUrl,
      'type': isHindi ? 'hindi' : 'english',
      'language': isHindi ? 'Hindi' : 'English',
    };
  }
}
