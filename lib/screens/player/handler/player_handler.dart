import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../../config.dart';

class PlayerHandler {
  static String? _detectedApiType; // Store which API worked
  
  // Auto-detect API and get episodes
  static Future<Map<String, dynamic>> getEpisodesWithDetection(String animeId) async {
    try {
      // Try English API first
      final englishResult = await _tryEnglishEpisodes(animeId);
      if (englishResult['success']) {
        _detectedApiType = 'english';
        return {
          'success': true,
          'episodes': englishResult['episodes'],
          'apiType': 'english',
        };
      }
      
      // Try Hindi API if English failed
      final hindiResult = await _tryHindiEpisodes(animeId);
      if (hindiResult['success']) {
        _detectedApiType = 'hindi';
        return {
          'success': true,
          'episodes': hindiResult['episodes'],
          'apiType': 'hindi',
        };
      }
      
      // Both failed
      throw Exception('No episodes found in both APIs');
      
    } on SocketException {
      throw SocketException('No internet connection');
    } on TimeoutException {
      throw TimeoutException('Request timed out', Duration(seconds: 30));
    } on HttpException catch (e) {
      throw HttpException('Server temporarily unavailable');
    } catch (e) {
      throw Exception('Failed to load episodes. Please try again.');
    }
  }
  
  // Try English episodes
  static Future<Map<String, dynamic>> _tryEnglishEpisodes(String animeId) async {
    try {
      final url = AppConfig.buildUrl('episodes', {'id': animeId});
      
      final response = await http.get(
        Uri.parse(url), 
        headers: AppConfig.defaultHeaders
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['episodes'] != null) {
          final List<dynamic> episodes = data['episodes'];
          
          if (episodes.isNotEmpty) {
            final mappedEpisodes = episodes.map((episode) {
              // Handle both string and int episode numbers
              final episodeNum = episode['episode_number'] is String 
                  ? int.tryParse(episode['episode_number']) ?? 1
                  : episode['episode_number'] ?? 1;
              
              return {
                'episode_number': episodeNum,
                'episode_id': episode['episode_id'].toString(),
                'title': episode['title'] ?? 'Episode $episodeNum',
                'type': 'english',
              };
            }).toList();
            
            return {
              'success': true,
              'episodes': mappedEpisodes,
            };
          }
        }
      } else if (response.statusCode >= 500) {
        throw HttpException('Server temporarily unavailable');
      }
      
    } on SocketException {
      throw SocketException('No internet connection');
    } on TimeoutException {
      throw TimeoutException('English API timeout', Duration(seconds: 30));
    } on HttpException {
      rethrow;
    } catch (e) {
      // Silent error for API detection
    }
    
    return {'success': false, 'episodes': []};
  }
  
  // Try Hindi episodes
  static Future<Map<String, dynamic>> _tryHindiEpisodes(String animeId) async {
    try {
      final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=getep&id=$animeId&token=${AppConfig.apiToken}';
      
      final response = await http.get(
        Uri.parse(url), 
        headers: AppConfig.defaultHeaders
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return {
            'success': true,
            'episodes': data.map((episode) => {
              'episode_number': int.tryParse(episode['episode'].toString()) ?? 1,
              'episode_id': episode['episode_id'].toString(),
              'title': episode['title'] ?? 'Episode ${episode['episode']}',
              'type': 'hindi',
            }).toList(),
          };
        }
      }
    } catch (e) {
      // Silent error handling
    }
    
    return {'success': false, 'episodes': []};
  }
  
  // Get stream URL using detected API
  static Future<String?> getStreamUrl(String animeId, String episodeId, {String preferredLanguage = 'sub'}) async {
    try {
      if (_detectedApiType == null) {
        throw Exception('API type not detected');
      }
      
      if (_detectedApiType == 'hindi') {
        return await _getHindiStreamUrl(animeId, episodeId);
      } else {
        return await _getEnglishStreamUrl(animeId, episodeId, preferredLanguage);
      }
    } on SocketException {
      throw SocketException('No internet connection');
    } on TimeoutException {
      throw TimeoutException('Stream URL request timed out', Duration(seconds: 30));
    } on HttpException catch (e) {
      throw HttpException('Server temporarily unavailable');
    } catch (e) {
      throw Exception('Unable to get stream URL');
    }
  }
  
  // Get Hindi stream URL
  static Future<String?> _getHindiStreamUrl(String animeId, String episodeId) async {
    try {
      final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=playep&id=$animeId&ep=$episodeId&token=${AppConfig.apiToken}';
      
      final response = await http.get(
        Uri.parse(url), 
        headers: AppConfig.defaultHeaders
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['streamUrl'] != null) {
          return data['streamUrl'];
        }
        
        if (data['urls'] != null && data['urls'].isNotEmpty) {
          return data['urls'][0];
        }
      }
    } catch (e) {
      // Silent error handling
    }
    
    return null;
  }
  
  // Get English stream URL
  static Future<String?> _getEnglishStreamUrl(String animeId, String episodeId, String preferredLanguage) async {
    try {
      final url = AppConfig.buildUrl('video', {'id': animeId, 'ep': episodeId});
      
      final response = await http.get(
        Uri.parse(url), 
        headers: AppConfig.defaultHeaders
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['sources'] != null) {
          final sources = data['sources'];
          
          // Try preferred language first, then fallback
          final languageOrder = preferredLanguage == 'dub' ? ['dub', 'sub'] : ['sub', 'dub'];
          
          for (String lang in languageOrder) {
            if (sources[lang] != null && sources[lang] is List) {
              final langSources = sources[lang] as List;
              if (langSources.isNotEmpty) {
                return langSources[0]['url'];
              }
            }
          }
        }
      } else if (response.statusCode >= 500) {
        throw HttpException('Stream temporarily unavailable');
      }
      
      throw Exception('No stream URL found for this episode');
      
    } on SocketException {
      throw SocketException('No internet connection');
    } on TimeoutException {
      throw TimeoutException('English stream timeout', Duration(seconds: 30));
    } on HttpException {
      rethrow;
    } catch (e) {
      throw Exception('Unable to get English stream');
    }
  }
  
  // Check available languages for English episodes
  static Future<Map<String, bool>> getAvailableLanguages(String animeId, String episodeId) async {
    try {
      final url = AppConfig.buildUrl('video', {'id': animeId, 'ep': episodeId});
      
      final response = await http.get(
        Uri.parse(url), 
        headers: AppConfig.defaultHeaders
      ).timeout(Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['sources'] != null) {
          final sources = data['sources'];
          
          return {
            'hasSub': sources['sub'] != null && sources['sub'] is List && (sources['sub'] as List).isNotEmpty,
            'hasDub': sources['dub'] != null && sources['dub'] is List && (sources['dub'] as List).isNotEmpty,
          };
        }
      }
    } catch (e) {
      // Silent error handling
    }
    
    return {'hasSub': false, 'hasDub': false};
  }

  // Get detected API type
  static String? getDetectedApiType() {
    return _detectedApiType;
  }
  
  // Reset detection (for new anime)
  static void resetDetection() {
    _detectedApiType = null;
  }
}
