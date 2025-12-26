import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import 'dart:async';
import '../handler/player_handler.dart';
import '../../errors/loading_error.dart';
import '../../errors/no_internet.dart';
import '../../../components/auto-rotation.dart';

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
  late TextEditingController _searchController;
  
  bool isLoading = true;
  bool hasError = false;
  bool isLoadingEpisode = false;
  bool isVideoLoading = true;
  bool isLandscape = false;
  String? errorMessage;
  List<Map<String, dynamic>> episodes = [];
  List<Map<String, dynamic>> filteredEpisodes = [];
  int currentEpisode = 1;
  String? detectedApiType;
  String selectedLanguage = 'sub'; // 'sub' or 'dub'
  bool hasSubAvailable = false;
  bool hasDubAvailable = false;
  DateTime lastEpisodeSwitchTime = DateTime.now().subtract(Duration(seconds: 5));
  Timer? _videoLoadingTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _setupAnimations();
    _setupStatusBar();
    _setupOrientationListener();
    PlayerHandler.resetDetection();
    _initializePlayer();
    _loadEpisodesWithDetection();
  }

  void _setupOrientationListener() {
    // Listen for orientation changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
      });
    });
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
    // Proper fullscreen without black layout
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
    
    // Enable auto-rotation for video player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _searchController.dispose();
    _videoLoadingTimer?.cancel();
    
    // Dispose auto-rotation reminder
    AutoRotationReminder.dispose();
    
    // Reset to portrait mode when leaving player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    // Reset system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    // Method kept for potential future use
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(seconds: 3),
        ),
      );
    }
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
            setState(() {
              isVideoLoading = true;
            });
            
            // Start video loading timeout - increased for better UX
            _videoLoadingTimer?.cancel();
            _videoLoadingTimer = Timer(Duration(seconds: 60), () {
              if (isVideoLoading) {
                // Silent handling - no snackbar
                setState(() {
                  isVideoLoading = false;
                });
              }
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isVideoLoading = false;
            });
            _videoLoadingTimer?.cancel();
            
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
            return NavigationDecision.prevent;
          },
          onWebResourceError: (WebResourceError error) {
            // Handle errors silently - no snackbar/toast
            if (error.errorCode == -2 || error.errorCode == -6) { // Network or connection errors
              // Silent handling - just log the error
            }
            setState(() {
              isVideoLoading = false;
            });
            _videoLoadingTimer?.cancel();
          },
          onHttpError: (HttpResponseError error) {
            // Silent handling - no snackbar
            final statusCode = error.response?.statusCode ?? 0;
            setState(() {
              isVideoLoading = false;
            });
            _videoLoadingTimer?.cancel();
          },
        ),
      )
      ..addJavaScriptChannel(
        'playerReady',
        onMessageReceived: (JavaScriptMessage message) {
          // Video ready - no toast needed
        },
      );
  }

  Future<void> _checkAvailableLanguages() async {
    if (detectedApiType == 'english' && episodes.isNotEmpty) {
      final episode = episodes.firstWhere(
        (ep) => ep['episode_number'] == currentEpisode,
        orElse: () => episodes.first,
      );
      
      final result = await PlayerHandler.getAvailableLanguages(widget.animeId, episode['episode_id']);
      
      setState(() {
        hasSubAvailable = result['hasSub'] ?? false;
        hasDubAvailable = result['hasDub'] ?? false;
        
        // Set default language to available one
        if (!hasSubAvailable && hasDubAvailable) {
          selectedLanguage = 'dub';
        } else if (hasSubAvailable && !hasDubAvailable) {
          selectedLanguage = 'sub';
        }
      });
    }
  }

  void _toggleFullscreen() {
    if (isLandscape) {
      // Exit fullscreen - go to portrait
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      // Enter fullscreen - go to landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  void _filterEpisodes(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredEpisodes = episodes;
      } else {
        filteredEpisodes = episodes.where((episode) {
          final episodeNumber = episode['episode_number'].toString();
          return episodeNumber.contains(query);
        }).toList();
      }
    });
  }

  void _switchLanguage(String language) {
    if (detectedApiType == 'english' && selectedLanguage != language) {
      setState(() {
        selectedLanguage = language;
      });
      // Reload current episode with new language preference
      _loadEpisode(currentEpisode);
    }
  }

  Future<void> _loadEpisodesWithDetection() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = null;
      });

      final result = await PlayerHandler.getEpisodesWithDetection(widget.animeId)
          .timeout(Duration(seconds: 30));
      
      if (result['success']) {
        setState(() {
          episodes = List<Map<String, dynamic>>.from(result['episodes']);
          filteredEpisodes = episodes; // Initialize filtered list
          detectedApiType = result['apiType'];
          isLoading = false;
        });
        
        if (episodes.isNotEmpty) {
          await _loadEpisode(episodes.first['episode_number']);
          await _checkAvailableLanguages();
          
          // Show auto-rotation reminder after 5 seconds
          AutoRotationReminder.checkAndShow(context);
        } else {
          setState(() {
            hasError = true;
            errorMessage = 'No episodes found for this anime';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          errorMessage = 'Failed to load episodes. Please check your connection.';
          isLoading = false;
        });
      }
    } on SocketException {
      setState(() {
        hasError = true;
        errorMessage = 'No internet connection. Please check your network.';
        isLoading = false;
      });
    } on TimeoutException {
      setState(() {
        hasError = true;
        errorMessage = 'Request timed out. Server might be slow or down.';
        isLoading = false;
      });
    } on HttpException {
      setState(() {
        hasError = true;
        errorMessage = 'Server error. Please try again later.';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = 'Something went wrong. Please try again.';
        isLoading = false;
      });
    }
  }

  Future<void> _loadEpisode(int episodeNumber) async {
    // Prevent double loading
    if (isLoadingEpisode) {
      return;
    }
    
    // Check cooldown period (like Android)
    final now = DateTime.now();
    if (now.difference(lastEpisodeSwitchTime).inSeconds < 3) {
      return;
    }
    
    try {
      setState(() {
        isLoadingEpisode = true;
        lastEpisodeSwitchTime = now;
      });
      
      setState(() {
        currentEpisode = episodeNumber;
      });

      final episode = episodes.firstWhere(
        (ep) => ep['episode_number'] == episodeNumber,
        orElse: () => episodes.isNotEmpty ? episodes.first : {},
      );

      if (episode.isEmpty) {
        throw Exception('Episode not found');
      }

      final streamUrl = await PlayerHandler.getStreamUrl(
        widget.animeId, 
        episode['episode_id'],
        preferredLanguage: selectedLanguage,
      ).timeout(Duration(seconds: 30));

      if (streamUrl == null) {
        throw Exception('No stream URL found for this episode');
      }

      // Use native app approach - localhost server with iframe
      await _startLocalhostServer(streamUrl);
      
      // Check available languages for this episode
      if (detectedApiType == 'english') {
        await _checkAvailableLanguages();
      }
      
    } on SocketException {
      // Silent handling - no snackbar
    } on TimeoutException {
      // Silent handling - no snackbar  
    } on HttpException catch (e) {
      // Silent handling - no snackbar
    } catch (e) {
      // Silent handling - no snackbar
    } finally {
      setState(() {
        isLoadingEpisode = false;
      });
    }
  }

  Future<void> _startLocalhostServer(String streamUrl) async {
    try {
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
                    -webkit-user-select: none;
                    -moz-user-select: none;
                    -ms-user-select: none;
                    user-select: none;
                    -webkit-touch-callout: none;
                    -webkit-tap-highlight-color: transparent;
                }
                
                html, body {
                    overscroll-behavior: none;
                    -webkit-overscroll-behavior: none;
                    overflow: hidden;
                    background: #000;
                }
                
                body {
                    background: #000;
                    overflow: hidden;
                }
                
                #video-container {
                    width: 100vw;
                    height: 100vh;
                    position: relative;
                    -webkit-user-select: none;
                    -moz-user-select: none;
                    user-select: none;
                }
                
                iframe {
                    width: 100%;
                    height: 100%;
                    border: none;
                    background: #000;
                    -webkit-user-select: none;
                    -moz-user-select: none;
                    user-select: none;
                    pointer-events: auto;
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
                // Disable context menu, text selection, and overscroll
                document.addEventListener('contextmenu', function(e) {
                    e.preventDefault();
                    return false;
                });
                
                document.addEventListener('selectstart', function(e) {
                    e.preventDefault();
                    return false;
                });
                
                document.addEventListener('dragstart', function(e) {
                    e.preventDefault();
                    return false;
                });
                
                // Disable overscroll bounce
                document.addEventListener('touchmove', function(e) {
                    e.preventDefault();
                }, { passive: false });
                
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
      
    } catch (e) {
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
    // Update landscape state
    isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    if (hasError) {
      // Show specific error screen based on error type
      if (errorMessage?.contains('internet') == true || errorMessage?.contains('network') == true) {
        return NoInternetScreen(
          onRetry: () {
            setState(() {
              hasError = false;
              errorMessage = null;
            });
            _loadEpisodesWithDetection();
          },
        );
      } else {
        return LoadingErrorScreen(
          errorMessage: errorMessage ?? 'Something went wrong',
          onRetry: () {
            setState(() {
              hasError = false;
              errorMessage = null;
            });
            _loadEpisodesWithDetection();
          },
        );
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: (isLandscape || isLoading) ? null : _buildAppBar(),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Color(0xFF0A0A0A),
              ],
            ),
          ),
          child: isLoading 
            ? _buildLoadingScreen()
            : isLandscape 
              ? _buildLandscapeLayout()
              : _buildPortraitLayout(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildLandscapeLayout() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Full screen video player
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                ),
                child: WebViewWidget(controller: _controller),
              ),
              
              // Episode loading indicator for landscape
              if (isLoadingEpisode || isVideoLoading)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/animations/loading.json',
                          width: 80,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 16),
                        Text(
                          isLoadingEpisode ? 'Loading Episode...' : 'Loading Video...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          // Exit fullscreen button - small, no background
          Positioned(
            top: 15,
            left: 15,
            child: GestureDetector(
              onTap: () {
                // Exit fullscreen - go back to portrait
                SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                ]);
              },
              child: Container(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.fullscreen_exit,
                  color: Colors.white.withOpacity(0.8),
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Video Player Section (30%)
          Container(
            height: MediaQuery.of(context).size.height * 0.30,
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
            child: Stack(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                      child: WebViewWidget(controller: _controller),
                    ),
                    
                    // Episode loading indicator
                    if (isLoadingEpisode || isVideoLoading)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Lottie.asset(
                                'assets/animations/loading.json',
                                width: 80,
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                              SizedBox(height: 16),
                              Text(
                                isLoadingEpisode ? 'Loading Episode...' : 'Loading Video...',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Fullscreen button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: _toggleFullscreen,
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Icon(
                        Icons.fullscreen,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Episodes Section (55%)
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
        child: Lottie.asset(
          'assets/animations/loading.json',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildEpisodeHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Title and episode count row
          Row(
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
          
          SizedBox(height: 16),
          
          // Search box
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filterEpisodes,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search episode number...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.5),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Sub/Dub buttons for English anime - only show available languages
          if (detectedApiType == 'english' && (hasSubAvailable || hasDubAvailable)) ...[
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchLanguage('sub'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedLanguage == 'sub' 
                          ? Color(0xFFFF8C00).withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedLanguage == 'sub' 
                            ? Color(0xFFFF8C00)
                            : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.subtitles,
                            color: selectedLanguage == 'sub' 
                              ? Color(0xFFFF8C00)
                              : Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'SUB',
                            style: TextStyle(
                              color: selectedLanguage == 'sub' 
                                ? Color(0xFFFF8C00)
                                : Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _switchLanguage('dub'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedLanguage == 'dub' 
                          ? Color(0xFFFF8C00).withOpacity(0.2)
                          : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selectedLanguage == 'dub' 
                            ? Color(0xFFFF8C00)
                            : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.record_voice_over,
                            color: selectedLanguage == 'dub' 
                              ? Color(0xFFFF8C00)
                              : Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'DUB',
                            style: TextStyle(
                              color: selectedLanguage == 'dub' 
                                ? Color(0xFFFF8C00)
                                : Colors.white.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEpisodeList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      physics: BouncingScrollPhysics(),
      itemCount: filteredEpisodes.length,
      itemBuilder: (context, index) {
        final episode = filteredEpisodes[index];
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
                          Row(
                            children: [
                              Text(
                                'Episode $episodeNum',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                              if (detectedApiType == 'english') ...[
                                SizedBox(width: 8),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF8C00).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    selectedLanguage.toUpperCase(),
                                    style: TextStyle(
                                      color: Color(0xFFFF8C00),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
