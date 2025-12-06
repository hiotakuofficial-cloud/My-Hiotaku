import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../../../config.dart';

class PlayerHandler {
  static String? _detectedApiType; // Store which API worked
  
  // Auto-detect API and get episodes
  static Future<Map<String, dynamic>> getEpisodesWithDetection(String animeId) async {
    
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
    return {
      'success': false,
      'episodes': [],
      'apiType': null,
      'error': 'No episodes found in both APIs',
    };
  }
  
  // Try English episodes
  static Future<Map<String, dynamic>> _tryEnglishEpisodes(String animeId) async {
    try {
      final url = AppConfig.buildUrl('episodes', {'id': animeId});
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
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
      }
    } catch (e) {
      // Silent error handling
    }
    
    return {'success': false, 'episodes': []};
  }
  
  // Try Hindi episodes
  static Future<Map<String, dynamic>> _tryHindiEpisodes(String animeId) async {
    try {
      final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=getep&id=$animeId&token=${AppConfig.apiToken}';
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
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
  static Future<String?> getStreamUrl(String animeId, String episodeId) async {
    if (_detectedApiType == null) {
      return null;
    }
    
    if (_detectedApiType == 'hindi') {
      return await _getHindiStreamUrl(animeId, episodeId);
    } else {
      return await _getEnglishStreamUrl(animeId, episodeId);
    }
  }
  
  // Get Hindi stream URL
  static Future<String?> _getHindiStreamUrl(String animeId, String episodeId) async {
    try {
      final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=playep&id=$animeId&ep=$episodeId&token=${AppConfig.apiToken}';
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
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
  static Future<String?> _getEnglishStreamUrl(String animeId, String episodeId) async {
    try {
      final url = AppConfig.buildUrl('video', {'id': animeId, 'ep': episodeId});
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['sources'] != null) {
          final sources = data['sources'];
          
          // Try sub first, then dub
          for (String lang in ['sub', 'dub']) {
            if (sources[lang] != null && sources[lang] is List) {
              final langSources = sources[lang] as List;
              if (langSources.isNotEmpty) {
                return langSources[0]['url'];
              }
            }
          }
        }
      }
    } catch (e) {
      // Silent error handling
    }
    
    return null;
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
