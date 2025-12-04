import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class PlayerHandler {
  
  // MegaPlay whitelisted referrers
  static const List<String> whitelistedReferrers = [
    'https://aniwave.best/',
    'https://9anime.skin/',
    'https://animesuge.to/',
  ];
  
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
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
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
    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=getep&id=$animeId&token=${AppConfig.apiToken}';
    
    try {
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((episode) => {
          'episode_number': int.parse(episode['episode']),
          'episode_id': episode['episode_id'],
          'title': episode['title'],
          'anime_id': animeId,
        }).toList();
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
    if (isHindi) {
      return await generateHindiPlayerHTML(animeId, episodeNumber, animeTitle);
    } else {
      return await generateEnglishPlayerHTML(episodeId, episodeNumber, animeTitle, language);
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
              body { background: #000; overflow: hidden; }
              iframe { width: 100vw; height: 100vh; border: none; }
          </style>
      </head>
      <body>
          <iframe src="$streamUrl" allowfullscreen webkitallowfullscreen mozallowfullscreen></iframe>
          
          <script>
              console.log("🇮🇳 Hindi Player Ready");
              console.log("📺 $animeTitle - Episode $episodeNumber");
              
              if (window.flutter_inappwebview) {
                  window.flutter_inappwebview.callHandler('playerReady', {
                      type: 'hindi',
                      episode: $episodeNumber,
                      title: '$animeTitle'
                  });
              }
          </script>
      </body>
      </html>
      ''';
    } catch (e) {
      return generateErrorHTML('Failed to load Hindi episode: $e');
    }
  }
  
  // Generate English player HTML (MegaPlay with proper setup)
  static Future<String> generateEnglishPlayerHTML(String episodeId, int episodeNumber, String animeTitle, String language) async {
    try {
      // Get MegaPlay HTML with proper referrer and scripts
      final megaplayHtml = await getMegaPlayHTML(episodeId, language);
      
      if (megaplayHtml == null) {
        return generateErrorHTML('English episode not available');
      }
      
      return megaplayHtml;
    } catch (e) {
      return generateErrorHTML('Failed to load English episode: $e');
    }
  }
  
  // Get Hindi stream URL
  static Future<String?> getHindiStreamUrl(String animeId, int episodeNumber) async {
    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=playep&id=$animeId&ep=$episodeNumber&token=${AppConfig.apiToken}';
    
    try {
      final response = await http.get(Uri.parse(url), headers: AppConfig.defaultHeaders);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['streamUrl'];
      }
      return null;
    } catch (e) {
      print('❌ Error getting Hindi stream URL: $e');
      return null;
    }
  }
  
  // Get MegaPlay HTML with proper referrer and scripts
  static Future<String?> getMegaPlayHTML(String episodeId, String language) async {
    final megaplayUrl = 'https://megaplay.buzz/stream/s-2/$episodeId/$language';
    
    try {
      final response = await http.get(
        Uri.parse(megaplayUrl),
        headers: {
          'Referer': whitelistedReferrers[0],
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate, br',
          'DNT': '1',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      );
      
      if (response.statusCode == 200) {
        // Modify the HTML to add Flutter communication
        String html = response.body;
        
        // Add Flutter communication script before closing body tag
        final flutterScript = '''
        <script>
            console.log("🌐 English MegaPlay Player Ready");
            
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('playerReady', {
                    type: 'english',
                    language: '$language',
                    episodeId: '$episodeId'
                });
            }
        </script>
        ''';
        
        html = html.replaceAll('</body>', '$flutterScript</body>');
        return html;
      }
      return null;
    } catch (e) {
      print('❌ Error getting MegaPlay HTML: $e');
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
