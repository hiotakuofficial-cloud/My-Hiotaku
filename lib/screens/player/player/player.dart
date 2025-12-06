import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../handler/player_handler.dart';
import '../../errors/loading_error.dart';

class PlayerScreen extends StatefulWidget {
  final String animeId;
  final String animeTitle;

  const PlayerScreen({
    Key? key,
    required this.animeId,
    required this.animeTitle,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late WebViewController _controller;
  bool isLoading = true;
  bool hasError = false;
  bool isLoadingEpisode = false;
  String? errorMessage;
  List<Map<String, dynamic>> episodes = [];
  int currentEpisode = 1;
  String? detectedApiType;
  DateTime lastEpisodeSwitchTime = DateTime.now().subtract(Duration(seconds: 5));

  @override
  void initState() {
    super.initState();
    PlayerHandler.resetDetection();
    _initializePlayer();
    _loadEpisodesWithDetection();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : Colors.green,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  void _initializePlayer() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
      ..enableZoom(false)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started: $url');
          },
          onPageFinished: (String url) {
            print('Page finished: $url');
            // Auto-play video like Android
            Future.delayed(Duration(seconds: 2), () {
              _controller.runJavaScript("document.querySelector('video')?.play();");
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            
            // Allow localhost URLs
            if (request.url.startsWith('http://localhost:')) {
              return NavigationDecision.navigate;
            }
            
            // Allow ads to load (like Android WebView)
            if (request.url.contains('googleads') || 
                request.url.contains('doubleclick') ||
                request.url.contains('googlesyndication') ||
                request.url.contains('adsystem')) {
              return NavigationDecision.navigate;
            }
            
            // Allow the original stream domain
            if (request.url.contains('v1-w3sc.onrender.com') || 
                request.url.contains('streamtape.com') ||
                request.url.contains('doodstream.com') ||
                request.url.contains('mixdrop.co') ||
                request.url.contains('upstream.to') ||
                request.url.contains('mp4upload.com')) {
              return NavigationDecision.navigate;
            }
            
            // Only block final search redirects
            if (request.url.contains('google.com/search') ||
                request.url.contains('bing.com/search')) {
              print('Blocked search redirect to: ${request.url}');
              return NavigationDecision.prevent;
            }
            
            // Allow everything else (like Android)
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            _showToast('❌ Player error: ${error.description}', isError: true);
          },
        ),
      )
      ..addJavaScriptChannel(
        'playerReady',
        onMessageReceived: (JavaScriptMessage message) {
          _showToast('🎉 Video Ready!');
        },
      );
  }

  Future<void> _loadEpisodesWithDetection() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });

      final result = await PlayerHandler.getEpisodesWithDetection(widget.animeId);
      
      if (result['success']) {
        setState(() {
          episodes = List<Map<String, dynamic>>.from(result['episodes']);
          detectedApiType = result['apiType'];
          isLoading = false;
        });
        
        if (episodes.isNotEmpty) {
          await _loadEpisode(episodes.first['episode_number']);
        }
      } else {
        setState(() {
          hasError = true;
          errorMessage = result['error'] ?? 'Failed to load episodes';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadEpisode(int episodeNumber) async {
    // Prevent double loading
    if (isLoadingEpisode) {
      print('Episode already loading, skipping...');
      return;
    }
    
    // Check cooldown period (like Android)
    final now = DateTime.now();
    if (now.difference(lastEpisodeSwitchTime).inSeconds < 3) {
      print('Episode switch cooldown active, skipping...');
      return;
    }
    
    try {
      setState(() {
        isLoadingEpisode = true;
        lastEpisodeSwitchTime = now;
      });
      
      _showToast('🎬 Loading Episode $episodeNumber...');
      
      setState(() {
        currentEpisode = episodeNumber;
      });

      final episode = episodes.firstWhere(
        (ep) => ep['episode_number'] == episodeNumber,
        orElse: () => episodes.isNotEmpty ? episodes.first : {},
      );

      if (episode.isEmpty) {
        _showToast('❌ Episode $episodeNumber not found', isError: true);
        return;
      }

      final streamUrl = await PlayerHandler.getStreamUrl(widget.animeId, episode['episode_id']);

      if (streamUrl == null) {
        _showToast('❌ No stream URL found', isError: true);
        return;
      }

      // Use native app approach - localhost server with iframe
      await _startLocalhostServer(streamUrl);
      
    } catch (e) {
      _showToast('❌ Episode loading failed: $e', isError: true);
    } finally {
      setState(() {
        isLoadingEpisode = false;
      });
    }
  }

  Future<void> _startLocalhostServer(String streamUrl) async {
    try {
      _showToast('🚀 Starting localhost server...');
      
      // Stop existing server
      await _stopLocalServer();
      
      // Find available port
      int port = await _findAvailablePort();
      
      // Start HTTP server
      final server = await HttpServer.bind('localhost', port);
      
      server.listen((HttpRequest request) {
        final response = request.response;
        
        // Generate HTML that embeds video in iframe (like Android)
        final htmlContent = '''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
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
                
                #video-container {
                    width: 100vw;
                    height: 100vh;
                    position: relative;
                }
                
                iframe {
                    width: 100%;
                    height: 100%;
                    border: none;
                    background: #000;
                }
            </style>
        </head>
        <body>
            <div id="video-container">
                <iframe id="video-frame" src="$streamUrl" allowfullscreen allow="autoplay; fullscreen; picture-in-picture"></iframe>
            </div>
            
            <script>
                console.log('Video player loaded with URL: $streamUrl');
            </script>
        </body>
        </html>
        ''';
        
        // Add proper HTTP headers like Android
        response.headers.contentType = ContentType.html;
        response.headers.add('Cache-Control', 'no-cache');
        response.headers.add('Access-Control-Allow-Origin', '*');
        response.write(htmlContent);
        response.close();
      });
      
      // Load localhost URL in WebView (exactly like Android)
      await _controller.loadRequest(Uri.parse('http://localhost:$port'));
      
      _showToast('✅ Localhost server running on port $port');
      
    } catch (e) {
      _showToast('❌ Server failed: $e', isError: true);
      // Fallback to direct URL
      await _controller.loadRequest(Uri.parse(streamUrl));
    }
  }

  Future<int> _findAvailablePort() async {
    for (int port = 8080; port <= 8090; port++) {
      try {
        final socket = await ServerSocket.bind('localhost', port);
        await socket.close();
        return port;
      } catch (e) {
        continue;
      }
    }
    return 8080;
  }

  Future<void> _stopLocalServer() async {
    // Server cleanup will be handled by HttpServer
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return LoadingErrorScreen(
        errorMessage: errorMessage ?? 'We\'re having trouble loading episodes',
        onRetry: () {
          Navigator.pop(context);
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${widget.animeTitle} (${detectedApiType == 'hindi' ? '🇮🇳 Hindi' : '🌐 English'})',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Auto-detecting API and loading episodes...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          )
        : Column(
            children: [
              // 30% Video Player
              Container(
                height: MediaQuery.of(context).size.height * 0.3,
                width: double.infinity,
                color: Colors.black,
                child: WebViewWidget(controller: _controller),
              ),
              
              // 70% Episode List
              Expanded(
                child: Container(
                  color: Colors.grey[900],
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              detectedApiType == 'hindi' ? Icons.language : Icons.subtitles,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Episodes (${detectedApiType == 'hindi' ? 'Hindi' : 'English'})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${episodes.length} episodes',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: ListView.builder(
                          itemCount: episodes.length,
                          itemBuilder: (context, index) {
                            final episode = episodes[index];
                            final episodeNum = episode['episode_number'];
                            final isSelected = episodeNum == currentEpisode;
                            
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.orange.withOpacity(0.2) : Colors.grey[800],
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected ? Border.all(color: Colors.orange, width: 2) : null,
                              ),
                              child: ListTile(
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.orange : Colors.grey[600],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Center(
                                    child: Text(
                                      episodeNum.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  episode['title'],
                                  style: TextStyle(
                                    color: isSelected ? Colors.orange : Colors.white,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: isSelected 
                                  ? const Icon(Icons.play_arrow, color: Colors.orange)
                                  : null,
                                onTap: () => _loadEpisode(episodeNum),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
