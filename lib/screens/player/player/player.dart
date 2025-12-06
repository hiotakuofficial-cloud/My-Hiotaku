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

class _PlayerScreenState extends State<PlayerScreen> with TickerProviderStateMixin {
  late WebViewController _controller;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
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
    _setupAnimations();
    _setupStatusBar();
    PlayerHandler.resetDetection();
    _initializePlayer();
    _loadEpisodesWithDetection();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  void _setupStatusBar() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
            // Auto-play video like Android + Enable fullscreen
            Future.delayed(Duration(seconds: 2), () {
              _controller.runJavaScript('''
                document.querySelector('video')?.play();
                
                // Enable fullscreen support
                document.addEventListener('fullscreenchange', function() {
                  if (document.fullscreenElement) {
                    // Hide Flutter UI when video goes fullscreen
                    document.body.style.background = '#000';
                    document.body.style.margin = '0';
                    document.body.style.padding = '0';
                  }
                });
                
                // Handle fullscreen requests
                const video = document.querySelector('video');
                if (video) {
                  video.addEventListener('click', function() {
                    if (video.requestFullscreen) {
                      video.requestFullscreen();
                    } else if (video.webkitRequestFullscreen) {
                      video.webkitRequestFullscreen();
                    }
                  });
                }
              ''');
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            
            // Allow localhost URLs
            if (request.url.startsWith('http://localhost:')) {
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
            
            // Block ALL other redirects (like Android with no shouldOverrideUrlLoading)
            print('Blocked redirect to: ${request.url}');
            return NavigationDecision.prevent;
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
                
                /* Fullscreen styles */
                iframe:-webkit-full-screen {
                    width: 100vw !important;
                    height: 100vh !important;
                }
                
                iframe:-moz-full-screen {
                    width: 100vw !important;
                    height: 100vh !important;
                }
                
                iframe:fullscreen {
                    width: 100vw !important;
                    height: 100vh !important;
                }
            </style>
        </head>
        <body>
            <div id="video-container">
                <iframe id="video-frame" 
                        src="$streamUrl" 
                        allowfullscreen 
                        webkitallowfullscreen 
                        mozallowfullscreen
                        allow="autoplay; fullscreen; picture-in-picture; accelerometer; gyroscope">
                </iframe>
            </div>
            
            <script>
                // Enhanced fullscreen support
                const iframe = document.getElementById('video-frame');
                
                // Listen for fullscreen events
                document.addEventListener('fullscreenchange', handleFullscreen);
                document.addEventListener('webkitfullscreenchange', handleFullscreen);
                document.addEventListener('mozfullscreenchange', handleFullscreen);
                
                function handleFullscreen() {
                    if (document.fullscreenElement || document.webkitFullscreenElement || document.mozFullScreenElement) {
                        // Fullscreen mode
                        document.body.style.background = '#000';
                        iframe.style.position = 'fixed';
                        iframe.style.top = '0';
                        iframe.style.left = '0';
                        iframe.style.zIndex = '9999';
                    } else {
                        // Exit fullscreen
                        iframe.style.position = 'relative';
                        iframe.style.zIndex = 'auto';
                    }
                }
                
                console.log('Video player loaded with fullscreen support');
            </script>
        </body>
        </html>
        ''';
        
        // Add proper HTTP headers like Android
        response.headers.contentType = ContentType.html;
        response.headers.add('Cache-Control', 'no-cache');
        response.headers.add('Access-Control-Allow-Origin', '*');
        response.headers.add('Feature-Policy', 'fullscreen *');
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            widget.animeTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.all(8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFFF8C00).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFFF8C00).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  detectedApiType == 'hindi' ? Icons.language : Icons.subtitles,
                  color: Color(0xFFFF8C00),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  detectedApiType == 'hindi' ? 'Hindi' : 'English',
                  style: TextStyle(
                    color: Color(0xFFFF8C00),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading 
        ? _buildLoadingScreen()
        : FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Video Player Section (40%)
                Container(
                  height: MediaQuery.of(context).size.height * 0.4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: WebViewWidget(controller: _controller),
                  ),
                ),
                
                // Episodes Section (60%)
                Expanded(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF0A0A0A),
                            Color(0xFF1A1A1A),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildEpisodeHeader(),
                          Expanded(child: _buildEpisodeList()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Color(0xFF1A1A1A),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: CircularProgressIndicator(
                color: Color(0xFFFF8C00),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Loading Episodes...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Auto-detecting best quality',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodeHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFFF8C00).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFFF8C00).withOpacity(0.2)),
            ),
            child: Icon(
              Icons.playlist_play_rounded,
              color: Color(0xFFFF8C00),
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Episodes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${episodes.length} episodes available',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              'EP $currentEpisode',
              style: TextStyle(
                color: Color(0xFFFF8C00),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      physics: BouncingScrollPhysics(),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final episodeNum = episode['episode_number'];
        final isSelected = episodeNum == currentEpisode;
        
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    Color(0xFFFF8C00).withOpacity(0.1),
                    Color(0xFFFF8C00).withOpacity(0.05),
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.03),
                    Colors.white.withOpacity(0.01),
                  ],
                ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                ? Color(0xFFFF8C00).withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _loadEpisode(episodeNum),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isSelected 
                          ? LinearGradient(
                              colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: isLoadingEpisode && isSelected
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              episodeNum.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            episode['title'],
                            style: TextStyle(
                              color: isSelected ? Color(0xFFFF8C00) : Colors.white,
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Episode $episodeNum',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF8C00).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Color(0xFFFF8C00),
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
