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
  
  // Get Hindi anime list
  static Future<List<Map<String, dynamic>>> getHindiAnimeList() async {
    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=home&token=${AppConfig.apiToken}';
    
    try {
      _showToast('🔄 Loading Hindi anime list...');
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _showToast('✅ Found ${data.length} Hindi anime');
        
        return data.map((anime) => {
          'id': anime['id'],
          'title': anime['title'],
          'description': anime['description'],
          'thumbnail': anime['thumbnail'],
          'type': anime['type'],
        }).toList();
      } else {
        _showToast('❌ Failed to load Hindi anime', isError: true);
      }
      return [];
    } catch (e) {
      _showToast('❌ Error: $e', isError: true);
      return [];
    }
  }
  
  // Get Hindi episodes
  static Future<List<Map<String, dynamic>>> getHindiEpisodes(String animeId) async {
    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=getep&id=$animeId&token=${AppConfig.apiToken}';
    
    try {
      _showToast('🔄 Loading episodes...');
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _showToast('✅ Found ${data.length} episodes');
        
        return data.map((episode) => {
          'episode': episode['episode'],
          'title': episode['title'],
          'id': episode['id'],
          'episode_id': episode['episode_id'],
        }).toList();
      } else {
        _showToast('❌ Failed to load episodes', isError: true);
      }
      return [];
    } catch (e) {
      _showToast('❌ Error: $e', isError: true);
      return [];
    }
  }
  
  // Get Hindi stream URL
  static Future<String?> getHindiStreamUrl(String animeId, String episodeNumber) async {
    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=playep&id=$animeId&ep=$episodeNumber&token=${AppConfig.apiToken}';
    
    try {
      _showToast('🔄 Getting stream URL...');
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['streamUrl'] != null) {
          _showToast('✅ Stream ready!');
          return data['streamUrl'];
        }
        
        if (data['urls'] != null && data['urls'].isNotEmpty) {
          _showToast('✅ Stream ready!');
          return data['urls'][0];
        }
        
        _showToast('❌ No stream found', isError: true);
      } else {
        _showToast('❌ Stream failed', isError: true);
      }
      return null;
    } catch (e) {
      _showToast('❌ Error: $e', isError: true);
      return null;
    }
  }
  
  // Search Hindi anime
  static Future<List<Map<String, dynamic>>> searchHindiAnime(String query) async {
    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=search&q=$query&token=${AppConfig.apiToken}';
    
    try {
      _showToast('🔍 Searching...');
      
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _showToast('✅ Found ${data.length} results');
        
        return data.map((anime) => {
          'id': anime['id'],
          'title': anime['title'],
          'description': anime['description'],
          'thumbnail': anime['thumbnail'],
          'type': anime['type'],
        }).toList();
      } else {
        _showToast('❌ Search failed', isError: true);
      }
      return [];
    } catch (e) {
      _showToast('❌ Error: $e', isError: true);
      return [];
    }
  }
}
