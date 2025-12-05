import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import '../handler/player_handler.dart';
import '../../errors/loading_error.dart';

// Platform-specific imports
import 'dart:io' if (dart.library.html) 'dart:html' as io;

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
  String? errorMessage;
  List<Map<String, dynamic>> episodes = [];
  int currentEpisode = 1;
  String? detectedApiType;
  dynamic _serverProcess; // Use dynamic instead of Process
  int serverPort = 8000;

  @override
  void initState() {
    super.initState();
    PlayerHandler.resetDetection(); // Reset for new anime
    _initializePlayer();
    _loadEpisodesWithDetection();
  }

  @override
  void dispose() {
    _stopLocalServer();
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
            // Don't show loading for video player area
          },
          onPageFinished: (String url) {
            // Video loaded
          },
          onWebResourceError: (WebResourceError error) {
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
        
        // Auto-play first episode
        if (episodes.isNotEmpty) {
          await _loadEpisode(episodes.first['episode_number']);
        }
      } else {
        // Both APIs failed - show error
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
    try {
      _showToast('🎬 Loading Episode $episodeNumber...');
      
      setState(() {
        currentEpisode = episodeNumber;
      });

      // Find episode in list
      final episode = episodes.firstWhere(
        (ep) => ep['episode_number'] == episodeNumber,
        orElse: () => episodes.isNotEmpty ? episodes.first : {},
      );

      if (episode.isEmpty) {
        _showToast('❌ Episode $episodeNumber not found', isError: true);
        return;
      }

      // Get stream URL using detected API
      final streamUrl = await PlayerHandler.getStreamUrl(widget.animeId, episode['episode_id']);

      if (streamUrl == null) {
        _showToast('❌ No stream URL found', isError: true);
        return;
      }

      // Try localhost server first, fallback to direct loading
      await _startLocalServerAndLoadPlayer(streamUrl, episodeNumber);
      
    } catch (e) {
      _showToast('❌ Episode loading failed: $e', isError: true);
    }
  }

  Future<void> _loadPlayerDirectly(String streamUrl, int episodeNumber) async {
    try {
      _showToast('🎬 Loading video player...');
      
      // Generate HTML content
      final htmlContent = await _generateDynamicHTML(streamUrl, episodeNumber);
      
      // Load HTML directly in WebView
      await _controller.loadHtmlString(htmlContent);
      
      _showToast('✅ Player loaded successfully');
      
    } catch (e) {
      _showToast('❌ Player loading failed: $e', isError: true);
    }
  }

  Future<void> _startLocalServerAndLoadPlayer(String streamUrl, int episodeNumber) async {
    try {
      // Only try server on non-web platforms
      if (!kIsWeb && io.Platform.isAndroid || io.Platform.isIOS) {
        await _tryLocalServer(streamUrl, episodeNumber);
      } else {
        // Fallback to direct loading
        await _loadPlayerDirectly(streamUrl, episodeNumber);
      }
    } catch (e) {
      _showToast('⚠️ Server failed, using direct mode', isError: false);
      await _loadPlayerDirectly(streamUrl, episodeNumber);
    }
  }

  Future<void> _tryLocalServer(String streamUrl, int episodeNumber) async {
    try {
      _showToast('🚀 Starting localhost server...');
      
      // Stop existing server
      await _stopLocalServer();
      
      // Find available port
      serverPort = await _findAvailablePort();
      
      // Create dynamic HTML content
      final htmlContent = await _generateDynamicHTML(streamUrl, episodeNumber);
      
      // Write HTML to temp file
      final htmlPath = '/tmp/player_${DateTime.now().millisecondsSinceEpoch}.html';
      await io.File(htmlPath).writeAsString(htmlContent);
      
      // Start HTTP server
      _serverProcess = await io.Process.start(
        'python3', 
        ['-m', 'http.server', serverPort.toString()], 
        workingDirectory: '/tmp'
      );
      
      // Wait for server to start
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Load player in WebView
      final playerUrl = 'http://localhost:$serverPort/player_${DateTime.now().millisecondsSinceEpoch}.html';
      await _controller.loadRequest(Uri.parse(playerUrl));
      
      _showToast('✅ Localhost server running on port $serverPort');
      
    } catch (e) {
      throw Exception('Server start failed: $e');
    }
  }

  Future<int> _findAvailablePort() async {
    for (int port = 8000; port <= 8010; port++) {
      try {
        final socket = await io.ServerSocket.bind('localhost', port);
        await socket.close();
        return port;
      } catch (e) {
        continue; // Port is busy, try next
      }
    }
    return 8000; // Fallback
  }

  Future<void> _stopLocalServer() async {
    if (_serverProcess != null) {
      try {
        _serverProcess.kill();
        _serverProcess = null;
      } catch (e) {
        print('Error stopping server: $e');
      }
    }
  }

  Future<void> _loadPlayerDirectly(String streamUrl, int episodeNumber) async {
    try {
      _showToast('🎬 Loading video player directly...');
      
      // Generate HTML content
      final htmlContent = await _generateDynamicHTML(streamUrl, episodeNumber);
      
      // Load HTML directly in WebView
      await _controller.loadHtmlString(htmlContent);
      
      _showToast('✅ Player loaded (direct mode)');
      
    } catch (e) {
      _showToast('❌ Player loading failed: $e', isError: true);
    }
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
                      // Header
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
                      
                      // Episode List
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
