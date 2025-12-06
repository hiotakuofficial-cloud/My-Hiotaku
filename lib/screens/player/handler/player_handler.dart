import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import '../../../config.dart';

class PlayerHandler {
  static String? _detectedApiType; // Store which API worked
  
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
  
  // Auto-detect API and get episodes
  static Future<Map<String, dynamic>> getEpisodesWithDetection(String animeId) async {
    _showToast('🔍 Auto-detecting API for: $animeId');
    
    // Try English API first
    final englishResult = await _tryEnglishEpisodes(animeId);
    if (englishResult['success']) {
      _detectedApiType = 'english';
      _showToast('✅ English API detected');
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
      _showToast('✅ Hindi API detected');
      return {
        'success': true,
        'episodes': hindiResult['episodes'],
        'apiType': 'hindi',
      };
    }
    
    // Both failed
    _showToast('❌ Both APIs failed', isError: true);
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
      _showToast('🌐 Trying English API...');
      final url = AppConfig.buildUrl('episodes', {'id': animeId});
      print('🔍 English API URL: $url');
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      print('🔍 English API Status: ${response.statusCode}');
      print('🔍 English API Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 English API Data: $data');
        
        if (data['success'] == true && data['episodes'] != null) {
          final List<dynamic> episodes = data['episodes'];
          print('🔍 English Episodes Count: ${episodes.length}');
          
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
            
            print('🔍 Mapped Episodes: ${mappedEpisodes.length}');
            return {
              'success': true,
              'episodes': mappedEpisodes,
            };
          }
        } else {
          print('❌ English API: success=${data['success']}, episodes=${data['episodes']}');
        }
      }
    } catch (e) {
      print('❌ English API error: $e');
    }
    
    return {'success': false, 'episodes': []};
  }
  
  // Try Hindi episodes
  static Future<Map<String, dynamic>> _tryHindiEpisodes(String animeId) async {
    try {
      _showToast('🇮🇳 Trying Hindi API...');
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
      print('❌ Hindi API error: $e');
    }
    
    return {'success': false, 'episodes': []};
  }
  
  // Get stream URL using detected API
  static Future<String?> getStreamUrl(String animeId, String episodeId) async {
    if (_detectedApiType == null) {
      _showToast('❌ No API detected', isError: true);
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
      _showToast('🔄 Getting Hindi stream...');
      final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=playep&id=$animeId&ep=$episodeId&token=${AppConfig.apiToken}';
      
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
      }
    } catch (e) {
      print('❌ Hindi stream error: $e');
    }
    
    _showToast('❌ Hindi stream failed', isError: true);
    return null;
  }
  
  // Get English stream URL
  static Future<String?> _getEnglishStreamUrl(String animeId, String episodeId) async {
    try {
      _showToast('🔄 Getting English stream...');
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
                _showToast('✅ English stream ready!');
                return langSources[0]['url'];
              }
            }
          }
        }
      }
    } catch (e) {
      print('❌ English stream error: $e');
    }
    
    _showToast('❌ English stream failed', isError: true);
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
