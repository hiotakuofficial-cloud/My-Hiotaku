import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../services/api_service.dart';
import '../../../config.dart';

class PlayerHandler {
  
  // Working MegaPlay domains (whitelisted referrers)
  static const List<String> whitelistedReferrers = [
    'https://aniwave.best/',
    'https://9anime.skin/',
    'https://animesuge.to/',
    'https://animesugez.to/',
  ];
  
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
  
  // Get Hindi episodes
  static Future<List<Map<String, dynamic>>> getHindiEpisodes(String animeId) async {
    try {
      final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=getep&id=$animeId&token=${AppConfig.apiToken}';
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
  
  // Get Hindi video stream URL
  static Future<String?> getHindiStreamUrl(String animeId, int episodeNumber) async {
    try {
      final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=playep&id=$animeId&ep=$episodeNumber&token=${AppConfig.apiToken}';
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
  
  // Generate simple Hindi video HTML
  static String generateHindiVideoHtml({
    required String streamUrl,
    required String animeTitle,
    required int episodeNumber,
  }) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>$animeTitle - Episode $episodeNumber (Hindi)</title>
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body {
                background: #000;
                overflow: hidden;
            }
            
            iframe {
                width: 100vw;
                height: 100vh;
                border: none;
            }
        </style>
    </head>
    <body>
        <iframe src="$streamUrl" 
                allowfullscreen
                webkitallowfullscreen
                mozallowfullscreen>
        </iframe>
        
        <script>
            console.log('🇮🇳 Hindi Video Player Ready');
            console.log('📺 Playing: $animeTitle - Episode $episodeNumber');
            console.log('🎬 Stream URL: $streamUrl');
            
            // Notify Flutter that player is ready
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('playerReady', {
                    type: 'hindi',
                    animeTitle: '$animeTitle',
                    episodeNumber: $episodeNumber,
                    streamUrl: '$streamUrl'
                });
            }
        </script>
    </body>
    </html>
    ''';
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
  
  // Generate complete MegaPlay HTML (WORKING VERSION)
  static String generateWorkingMegaPlayHtml({
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
    
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <title>File $episodeId - MegaPlay</title>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <meta name="robots" content="noindex,nofollow" />
        <meta http-equiv="content-language" content="en" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="referrer" content="origin">
        <link rel="shortcut icon" href="/images/favicon.png" type="image/x-icon" />
        <link rel="stylesheet" type="text/css" href="https://megaplay.buzz/lib/app.css?v=1" />
        
        <style>
            body {
                margin: 0;
                padding: 0;
                background: #000;
                overflow: hidden;
            }
            
            .mg-3mb3d {
                width: 100vw !important;
                height: 100vh !important;
            }
            
            .mg3-player {
                width: 100% !important;
                height: 100% !important;
            }
            
            .fix-area {
                width: 100% !important;
                height: 100% !important;
            }
        </style>
        
        <!-- Google Analytics -->
        <script async src="https://www.googletagmanager.com/gtag/js?id=G-5FDVV0W2WD"></script>
        
        <!-- DevTools Detection -->
        <script src="https://megaplay.buzz/lib/devtools-detector_v1.new.js?v=1.1"></script>
        
        <!-- Player Settings -->
        <script>
            const settings = {
                time: 0,
                autoPlay: "1",
                playOriginalAudio: "1",
                autoSkipIntro: "0",
                vast: 0,
                base_url: 'https://megaplay.buzz/',
                domain2_url: 'https://mewcdn.online/',
                type: '$language',
                cid: '${_generateCid(episodeId)}',
            };
            
            // Override referrer to whitelisted domain
            Object.defineProperty(document, 'referrer', {
                value: '${whitelistedReferrers[0]}',
                writable: false,
                configurable: false
            });
            
            console.log('🔑 Referrer set to:', document.referrer);
            console.log('🎬 Loading Episode $episodeNumber ($language)');
        </script>
    </head>
    <body>
        <!-- MegaPlay Player Structure -->
        <div class="mg-3mb3d">
            <div class="mg3-player">
                <div class="fix-area" id="megaplay-player" data-ep-id="$episodeId" data-fileversion="0">
                    <div class="content-center">
                        <div class="loading-content" id="loading">
                            <div class="load-circle">
                                <div></div>
                                <div></div>
                            </div>
                        </div>
                    </div>
                </div>
                <div class="error-content" style="display: none;">
                    <div class="text">
                        Brave browser does not support our player. Please try with other browsers such as Chrome or Firefox.
                    </div>
                </div>
            </div>
        </div>

        <!-- jQuery (Required) -->
        <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
        
        <!-- HLS.js for video streaming -->
        <script src="https://cdn.jsdelivr.net/gh/itspro-dev/project_files@master/jw/hls.js?v=0.2"></script>
        
        <!-- MegaPlay Core Scripts (Exact order) -->
        <script src="https://megaplay.buzz/lib/app.main.js?v=1.0"></script>
        <script src="https://megaplay.buzz/lib/jw_player.js?s"></script>
        <script src="https://megaplay.buzz/lib/stream-4-player.min.js?v=1.0.0.1"></script>
        
        <!-- Analytics -->
        <script defer data-domain="megaplay.buzz" src="https://plausible.io/js/script.js"></script>
        
        <!-- MegaPlay Analytics Override & Message Handler -->
        <script>
            !function () { 
                let t = window.fetch; 
                window.fetch = function (e, i = {}) { 
                    let o = "string" == typeof e ? e : e.url, 
                        r = (i.method || "GET").toUpperCase(); 
                    if (o && o.startsWith("https://plausible.io/api/event") && "POST" === r && i.body) 
                        try { 
                            if ("string" == typeof i.body) { 
                                let n = JSON.parse(i.body), 
                                    f = function t(e) { 
                                        if ("string" == typeof e) return e.replace(/megaplay\\.buzz/g, "megaplay2.okay"); 
                                        if (e && "object" == typeof e) for (let i in e) e[i] = t(e[i]); 
                                        return e 
                                    }(n); 
                                i.body = JSON.stringify(f) 
                            } 
                        } catch (p) { } 
                    return t.call(this, e, i) 
                } 
            }();
            
            window.addEventListener("message", (event) => {
                console.log('📨 Player message:', event.data);
                window.parent.postMessage(event.data, "*");
            });
            
            // Flutter communication
            window.addEventListener('DOMContentLoaded', function() {
                console.log('🚀 MegaPlay Player Ready');
                console.log('📋 Episode: $animeTitle - Episode $episodeNumber');
                
                // Notify Flutter that player is ready
                if (window.flutter_inappwebview) {
                    window.flutter_inappwebview.callHandler('playerReady', {
                        type: 'english',
                        episodeId: '$episodeId',
                        episodeNumber: $episodeNumber,
                        language: '$language'
                    });
                }
            });
        </script>
    </body>
    </html>
    ''';
  }
  
  // Generate CID for episode
  static String _generateCid(String episodeId) {
    int hash = 0;
    for (int i = 0; i < episodeId.length; i++) {
      hash = ((hash << 5) - hash) + episodeId.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF; // Convert to 32-bit integer
    }
    return hash.abs().toRadixString(16).substring(0, 4);
  }
  
  // Load MegaPlay with proper headers
  static Map<String, String> getMegaPlayHeaders() {
    return {
      'Referer': whitelistedReferrers[0], // Use aniwave.best
      'User-Agent': 'Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.5',
      'Accept-Encoding': 'gzip, deflate, br',
      'DNT': '1',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
    };
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
  
  // Get language options
  static List<String> getLanguageOptions() {
    return ['sub', 'dub', 'hindi'];
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
  static Future<bool> testStreamAvailability(String episodeId) async {
    try {
      final streamUrl = buildStreamUrl(episodeId: episodeId);
      final response = await http.head(
        Uri.parse(streamUrl),
        headers: getMegaPlayHeaders(),
      ).timeout(Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
