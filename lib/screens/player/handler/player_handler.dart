import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/api_service.dart';

class PlayerHandler {
  
  // Server configurations
  static const List<String> streamDomains = [
    'https://megaplay.buzz',
    'https://vidwish.live',
  ];
  
  static const List<String> streamServers = ['s-2', 's-4'];
  
  // Get episodes for anime
  static Future<List<Map<String, dynamic>>> getEpisodes(String animeId) async {
    try {
      final episodes = await ApiService.getEpisodes(animeId);
      return episodes;
    } catch (e) {
      print('❌ Error fetching episodes: $e');
      return [];
    }
  }
  
  // Build MegaPlay stream URL
  static String buildStreamUrl({
    required String episodeId,
    String language = 'sub',
    String server = 's-2',
    int domainIndex = 0,
  }) {
    final domain = streamDomains[domainIndex];
    return '$domain/stream/$server/$episodeId/$language';
  }
  
  // Generate iframe HTML for WebView
  static String generateIframeHtml({
    required String episodeId,
    required String animeTitle,
    required int episodeNumber,
    String language = 'sub',
    String server = 's-2',
    int domainIndex = 0,
  }) {
    final streamUrl = buildStreamUrl(
      episodeId: episodeId,
      language: language,
      server: server,
      domainIndex: domainIndex,
    );
    
    final fallbackUrl = buildStreamUrl(
      episodeId: episodeId,
      language: language,
      server: 's-4',
      domainIndex: domainIndex,
    );
    
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <meta name="referrer" content="origin">
        <title>$animeTitle - Episode $episodeNumber</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            body {
                background: #000;
                overflow: hidden;
                font-family: 'Arial', sans-serif;
            }
            .player-container {
                position: relative;
                width: 100vw;
                height: 100vh;
            }
            iframe {
                width: 100%;
                height: 100%;
                border: none;
                display: block;
            }
            .loading {
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                color: #fff;
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
            .error {
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                color: #fff;
                text-align: center;
                z-index: 20;
                display: none;
            }
        </style>
    </head>
    <body>
        <div class="player-container">
            <div class="loading" id="loading">
                <div class="spinner"></div>
                <p>Loading Episode $episodeNumber...</p>
                <small>Server: ${streamDomains[domainIndex].split('//')[1]}/$server</small>
            </div>
            
            <div class="error" id="error">
                <h3>⚠️ Playback Error</h3>
                <p>Episode $episodeNumber is not available</p>
                <button onclick="retryPlayback()" style="
                    background: #FF8C00;
                    color: white;
                    border: none;
                    padding: 8px 16px;
                    border-radius: 4px;
                    margin-top: 12px;
                    cursor: pointer;
                ">Retry</button>
            </div>
            
            <iframe id="player"
                    src="$streamUrl"
                    allowfullscreen
                    webkitallowfullscreen
                    mozallowfullscreen
                    onload="hideLoading()"
                    onerror="handleError()">
            </iframe>
        </div>
        
        <script>
            let retryCount = 0;
            const maxRetries = 2;
            
            function hideLoading() {
                document.getElementById('loading').style.display = 'none';
            }
            
            function showError() {
                document.getElementById('loading').style.display = 'none';
                document.getElementById('error').style.display = 'block';
            }
            
            function handleError() {
                retryCount++;
                if (retryCount <= maxRetries) {
                    // Try fallback server
                    document.getElementById('player').src = '$fallbackUrl';
                } else {
                    showError();
                }
            }
            
            function retryPlayback() {
                retryCount = 0;
                document.getElementById('error').style.display = 'none';
                document.getElementById('loading').style.display = 'block';
                document.getElementById('player').src = '$streamUrl';
            }
            
            // Hide loading after 10 seconds if iframe doesn't load
            setTimeout(() => {
                if (document.getElementById('loading').style.display !== 'none') {
                    handleError();
                }
            }, 10000);
        </script>
    </body>
    </html>
    ''';
  }
  
  // Get episode info by ID
  static Map<String, dynamic>? getEpisodeById(
    List<Map<String, dynamic>> episodes, 
    String episodeId
  ) {
    try {
      return episodes.firstWhere(
        (episode) => episode['episode_id'] == episodeId,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Get next episode
  static Map<String, dynamic>? getNextEpisode(
    List<Map<String, dynamic>> episodes, 
    int currentEpisodeNumber
  ) {
    try {
      return episodes.firstWhere(
        (episode) => episode['episode_number'] == currentEpisodeNumber + 1,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Get previous episode
  static Map<String, dynamic>? getPreviousEpisode(
    List<Map<String, dynamic>> episodes, 
    int currentEpisodeNumber
  ) {
    try {
      return episodes.firstWhere(
        (episode) => episode['episode_number'] == currentEpisodeNumber - 1,
      );
    } catch (e) {
      return null;
    }
  }
  
  // Validate episode ID format
  static bool isValidEpisodeId(String episodeId) {
    return RegExp(r'^\d+$').hasMatch(episodeId);
  }
  
  // Get stream quality options
  static List<String> getQualityOptions() {
    return ['Auto', '1080p', '720p', '480p', '360p'];
  }
  
  // Get language options
  static List<String> getLanguageOptions() {
    return ['sub', 'dub'];
  }
  
  // Check if episode supports dub
  static bool supportsDub(Map<String, dynamic> episode) {
    // Most anime episodes support both sub and dub
    // Can be enhanced with API data
    return true;
  }
  
  // Generate episode title
  static String generateEpisodeTitle(
    String animeTitle, 
    int episodeNumber, 
    String? episodeTitle
  ) {
    if (episodeTitle != null && episodeTitle.isNotEmpty) {
      return '$animeTitle - Episode $episodeNumber: $episodeTitle';
    }
    return '$animeTitle - Episode $episodeNumber';
  }
  
  // Test stream availability
  static Future<bool> testStreamAvailability(String streamUrl) async {
    try {
      final response = await http.head(
        Uri.parse(streamUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
          'Referer': 'https://aniwave.to/',
        },
      ).timeout(Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
