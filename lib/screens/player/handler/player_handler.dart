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
              body { 
                  background: #000; 
                  overflow: hidden;
                  -webkit-touch-callout: none;
                  -webkit-user-select: none;
                  -khtml-user-select: none;
                  -moz-user-select: none;
                  -ms-user-select: none;
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
              console.log("🎬 Stream URL: $streamUrl");
              
              // Hide loading when iframe loads
              document.getElementById('videoFrame').onload = function() {
                  document.getElementById('loading').style.display = 'none';
                  console.log("✅ Hindi video iframe loaded");
              };
              
              // Handle iframe errors
              document.getElementById('videoFrame').onerror = function() {
                  document.getElementById('loading').innerHTML = 'Failed to load video';
                  console.log("❌ Hindi video iframe failed");
              };
              
              // Prevent page freeze on touch
              document.addEventListener('touchstart', function(e) {
                  console.log('Touch detected on Hindi player');
              }, { passive: true });
              
              // Notify Flutter
              if (window.flutter_inappwebview) {
                  window.flutter_inappwebview.callHandler('playerReady', {
                      type: 'hindi',
                      episode: $episodeNumber,
                      title: '$animeTitle'
                  });
              }
              
              // Auto-hide loading after 10 seconds
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
  
  // Generate English player HTML (MegaPlay with proper setup)
  static Future<String> generateEnglishPlayerHTML(String episodeId, int episodeNumber, String animeTitle, String language) async {
    try {
      // Generate complete MegaPlay HTML with all required scripts and referrer
      return generateWorkingMegaPlayHTML(
        episodeId: episodeId,
        episodeNumber: episodeNumber,
        animeTitle: animeTitle,
        language: language,
      );
    } catch (e) {
      return generateErrorHTML('Failed to load English episode: $e');
    }
  }
  
  // Generate working MegaPlay HTML (from our successful tests)
  static String generateWorkingMegaPlayHTML({
    required String episodeId,
    required int episodeNumber,
    required String animeTitle,
    required String language,
  }) {
    final cid = _generateCid(episodeId);
    
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
                -webkit-touch-callout: none;
                -webkit-user-select: none;
                -khtml-user-select: none;
                -moz-user-select: none;
                -ms-user-select: none;
                user-select: none;
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
            
            /* Prevent stuck issues */
            video {
                pointer-events: auto !important;
            }
            
            .jw-media {
                pointer-events: auto !important;
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
                cid: '$cid',
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
  
  // Get Hindi stream URL
  static Future<String?> getHindiStreamUrl(String animeId, int episodeNumber) async {
    final url = '${AppConfig.animeApiBaseUrl}/hindiv2.php?action=playep&id=$animeId&ep=$episodeNumber&token=${AppConfig.apiToken}';
    
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
