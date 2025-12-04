import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class PlayerHandler {
  
  // Get episodes based on anime type
  static Future<List<Map<String, dynamic>>> getEpisodes(String animeId, bool isHindi) async {
    try {
      if (isHindi) {
        return await getHindiEpisodes(animeId);
      } else {
        return await getEnglishEpisodes(animeId);
      }
    } catch (e) {
      print('❌ Error fetching episodes: $e');
      return [];
    }
  }
  
  // Get English episodes
  static Future<List<Map<String, dynamic>>> getEnglishEpisodes(String animeId) async {
    final url = AppConfig.buildUrl('episodes', {'id': animeId});
    
    try {
      print('🔄 Fetching English episodes from: $url');
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      print('📡 English API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ English episodes count: ${data['episodes'].length}');
          return List<Map<String, dynamic>>.from(data['episodes']);
        }
      }
      return [];
    } catch (e) {
      print('❌ Error fetching English episodes: $e');
      return [];
    }
  }
  
  // Get Hindi episodes
  static Future<List<Map<String, dynamic>>> getHindiEpisodes(String animeId) async {
    final url = AppConfig.buildHindiUrl('getep', {'id': animeId});
    
    try {
      print('🔄 Fetching Hindi episodes from: $url');
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      print('📡 Hindi API Response Status: ${response.statusCode}');
      print('📋 Hindi API Response Body: ${response.body.substring(0, 200)}...');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('✅ Hindi episodes count: ${data.length}');
        
        return data.map((episode) {
          // Parse episode number - it comes as string like "01", "02"
          final episodeStr = episode['episode'].toString();
          final episodeNumber = int.tryParse(episodeStr) ?? 1;
          
          return {
            'episode_number': episodeNumber,
            'episode_id': episode['episode_id'].toString(),
            'title': episode['title'] ?? 'Episode $episodeNumber',
            'anime_id': animeId,
          };
        }).toList();
      } else {
        print('❌ Hindi API failed with status: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }
      return [];
    } catch (e) {
      print('❌ Error fetching Hindi episodes: $e');
      return [];
    }
  }
  
  // Generate player HTML based on anime type
  static Future<String> generatePlayerHTML({
    required String animeId,
    required String episodeId,
    required int episodeNumber,
    required String animeTitle,
    required bool isHindi,
    String language = 'sub',
  }) async {
    
    print('🎬 Generating player HTML:');
    print('   - Anime ID: $animeId');
    print('   - Episode ID: $episodeId');
    print('   - Episode Number: $episodeNumber');
    print('   - Title: $animeTitle');
    print('   - Is Hindi: $isHindi');
    print('   - Language: $language');
    
    try {
      if (isHindi) {
        print('🇮🇳 Loading Hindi player...');
        return await generateHindiPlayerHTML(animeId, episodeNumber, animeTitle);
      } else {
        print('🌐 Loading English player...');
        return await generateEnglishPlayerHTML(animeId, episodeId, episodeNumber, animeTitle, language);
      }
    } catch (e) {
      print('❌ Error in generatePlayerHTML: $e');
      return generateErrorHTML('Failed to generate player: $e');
    }
  }
  
  // Generate Hindi player HTML (Direct iframe)
  static Future<String> generateHindiPlayerHTML(String animeId, int episodeNumber, String animeTitle) async {
    try {
      // Get Hindi stream URL
      final streamUrl = await getHindiStreamUrl(animeId, episodeNumber);
      
      if (streamUrl == null) {
        return generateErrorHTML('Hindi episode not available');
      }
      
      return '''
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>$animeTitle - Episode $episodeNumber (Hindi)</title>
          <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body { 
                  background: #000; 
                  overflow: hidden;
                  -webkit-touch-callout: none;
                  -webkit-user-select: none;
                  user-select: none;
              }
              iframe { 
                  width: 100vw; 
                  height: 100vh; 
                  border: none;
                  pointer-events: auto;
              }
              .loading {
                  position: absolute;
                  top: 50%;
                  left: 50%;
                  transform: translate(-50%, -50%);
                  color: white;
                  font-family: Arial, sans-serif;
                  z-index: 10;
              }
          </style>
      </head>
      <body>
          <div class="loading" id="loading">Loading Hindi video...</div>
          
          <iframe id="videoFrame" 
                  src="$streamUrl" 
                  allowfullscreen 
                  webkitallowfullscreen 
                  mozallowfullscreen
                  allow="autoplay; fullscreen; picture-in-picture"
                  sandbox="allow-same-origin allow-scripts allow-forms allow-pointer-lock allow-top-navigation allow-presentation">
          </iframe>
          
          <script>
              console.log("🇮🇳 Hindi Player Ready");
              console.log("📺 $animeTitle - Episode $episodeNumber");
              
              document.getElementById('videoFrame').onload = function() {
                  document.getElementById('loading').style.display = 'none';
                  console.log("✅ Hindi video loaded");
              };
              
              if (window.flutter_inappwebview) {
                  window.flutter_inappwebview.callHandler('playerReady', {
                      type: 'hindi',
                      episode: $episodeNumber,
                      title: '$animeTitle'
                  });
              }
              
              setTimeout(function() {
                  document.getElementById('loading').style.display = 'none';
              }, 10000);
          </script>
      </body>
      </html>
      ''';
    } catch (e) {
      return generateErrorHTML('Failed to load Hindi episode: $e');
    }
  }
  
  // Generate English player HTML (Direct API-based)
  static Future<String> generateEnglishPlayerHTML(String animeId, String episodeId, int episodeNumber, String animeTitle, String language) async {
    try {
      print('🔄 Getting English stream for: $animeId, episode: $episodeId, language: $language');
      
      // Get English stream URL from API
      final streamUrl = await getEnglishStreamUrl(animeId, episodeId, language);
      
      if (streamUrl == null) {
        print('❌ No English stream URL found');
        return generateErrorHTML('English episode not available');
      }
      
      print('✅ English stream URL found: $streamUrl');
      
      return '''
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>$animeTitle - Episode $episodeNumber (${language.toUpperCase()})</title>
          <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body { 
                  background: #000; 
                  overflow: hidden;
                  -webkit-touch-callout: none;
                  -webkit-user-select: none;
                  user-select: none;
              }
              iframe { 
                  width: 100vw; 
                  height: 100vh; 
                  border: none;
                  pointer-events: auto;
              }
              .loading {
                  position: absolute;
                  top: 50%;
                  left: 50%;
                  transform: translate(-50%, -50%);
                  color: white;
                  font-family: Arial, sans-serif;
                  text-align: center;
                  z-index: 10;
              }
              .spinner {
                  border: 3px solid rgba(255, 255, 255, 0.3);
                  border-top: 3px solid #FF8C00;
                  border-radius: 50%;
                  width: 40px;
                  height: 40px;
                  animation: spin 1s linear infinite;
                  margin: 0 auto 16px;
              }
              @keyframes spin {
                  0% { transform: rotate(0deg); }
                  100% { transform: rotate(360deg); }
              }
          </style>
      </head>
      <body>
          <div class="loading" id="loading">
              <div class="spinner"></div>
              <p>Loading ${language.toUpperCase()} Episode $episodeNumber...</p>
          </div>
          
          <iframe id="videoFrame" 
                  src="$streamUrl" 
                  allowfullscreen 
                  webkitallowfullscreen 
                  mozallowfullscreen
                  allow="autoplay; fullscreen; picture-in-picture"
                  sandbox="allow-same-origin allow-scripts allow-forms allow-pointer-lock allow-top-navigation allow-presentation">
          </iframe>
          
          <script>
              console.log("🌐 English Player Ready");
              console.log("📺 $animeTitle - Episode $episodeNumber (${language.toUpperCase()})");
              console.log("🎬 Stream URL: $streamUrl");
              
              // Hide loading when iframe loads
              document.getElementById('videoFrame').onload = function() {
                  document.getElementById('loading').style.display = 'none';
                  console.log("✅ English video iframe loaded");
              };
              
              // Handle iframe errors
              document.getElementById('videoFrame').onerror = function() {
                  document.getElementById('loading').innerHTML = '<p>Failed to load video</p>';
                  console.log("❌ English video iframe failed");
              };
              
              // Notify Flutter
              if (window.flutter_inappwebview) {
                  window.flutter_inappwebview.callHandler('playerReady', {
                      type: 'english',
                      language: '$language',
                      episode: $episodeNumber,
                      title: '$animeTitle'
                  });
              }
              
              // Auto-hide loading after 15 seconds
              setTimeout(function() {
                  document.getElementById('loading').style.display = 'none';
              }, 15000);
          </script>
      </body>
      </html>
      ''';
    } catch (e) {
      print('❌ Error in generateEnglishPlayerHTML: $e');
      return generateErrorHTML('Failed to load English episode: $e');
    }
  }
  
  // Get Hindi stream URL
  static Future<String?> getHindiStreamUrl(String animeId, int episodeNumber) async {
    final url = AppConfig.buildHindiUrl('playep', {'id': animeId, 'ep': episodeNumber});
    
    try {
      print('🔄 Getting Hindi stream URL from: $url');
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      print('📡 Hindi Stream API Status: ${response.statusCode}');
      print('📋 Hindi Stream Response: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final streamUrl = data['streamUrl'];
        print('✅ Hindi stream URL: $streamUrl');
        return streamUrl;
      } else {
        print('❌ Hindi stream API failed: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('❌ Error getting Hindi stream URL: $e');
      return null;
    }
  }
  
  // Get English stream URL from API
  static Future<String?> getEnglishStreamUrl(String animeId, String episodeId, String language) async {
    final url = AppConfig.buildUrl('video', {
      'id': animeId,
      'ep': episodeId,
    });
    
    try {
      print('🔄 Getting English stream URL from: $url');
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      print('📡 English Stream API Status: ${response.statusCode}');
      print('📋 English Stream Response: ${response.body.substring(0, 300)}...');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['sources'] != null) {
          final sources = data['sources'];
          
          // Get sources for requested language (sub/dub)
          if (sources[language] != null && sources[language] is List) {
            final languageSources = sources[language] as List;
            if (languageSources.isNotEmpty) {
              final streamUrl = languageSources[0]['url'];
              print('✅ English stream URL ($language): $streamUrl');
              return streamUrl;
            }
          }
          
          // Fallback to first available language
          for (String lang in ['sub', 'dub']) {
            if (sources[lang] != null && sources[lang] is List) {
              final langSources = sources[lang] as List;
              if (langSources.isNotEmpty) {
                final streamUrl = langSources[0]['url'];
                print('✅ English stream URL (fallback $lang): $streamUrl');
                return streamUrl;
              }
            }
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting English stream URL: $e');
      return null;
    }
  }
  
  // Generate error HTML
  static String generateErrorHTML(String message) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Error</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
                background: #000; 
                color: white; 
                font-family: Arial, sans-serif;
                display: flex;
                align-items: center;
                justify-content: center;
                height: 100vh;
                text-align: center;
            }
            .error { padding: 20px; }
            h1 { color: #f44336; margin-bottom: 10px; }
        </style>
    </head>
    <body>
        <div class="error">
            <h1>⚠️ Error</h1>
            <p>$message</p>
        </div>
    </body>
    </html>
    ''';
  }
  
  // Get next episode
  static Map<String, dynamic>? getNextEpisode(List<Map<String, dynamic>> episodes, int currentEpisodeNumber) {
    try {
      return episodes.firstWhere(
        (episode) => episode['episode_number'] == currentEpisodeNumber + 1,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Get previous episode
  static Map<String, dynamic>? getPreviousEpisode(List<Map<String, dynamic>> episodes, int currentEpisodeNumber) {
    try {
      return episodes.firstWhere(
        (episode) => episode['episode_number'] == currentEpisodeNumber - 1,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Get episode by number
  static Map<String, dynamic>? getEpisodeByNumber(List<Map<String, dynamic>> episodes, int episodeNumber) {
    try {
      return episodes.firstWhere(
        (episode) => episode['episode_number'] == episodeNumber,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Generate episode title
  static String generateEpisodeTitle(String animeTitle, int episodeNumber, String? episodeTitle) {
    if (episodeTitle != null && episodeTitle.isNotEmpty) {
      return '$animeTitle - Episode $episodeNumber: $episodeTitle';
    }
    return '$animeTitle - Episode $episodeNumber';
  }
  
  // Get language options based on anime type
  static List<String> getLanguageOptions(bool isHindi) {
    if (isHindi) {
      return ['hindi'];
    } else {
      return ['sub', 'dub'];
    }
  }
}
