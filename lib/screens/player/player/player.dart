import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import '../handler/player_handler.dart';

class PlayerScreen extends StatefulWidget {
  final String animeId;
  final String animeTitle;
  final int initialEpisode;
  final bool isHindi;

  const PlayerScreen({
    Key? key,
    required this.animeId,
    required this.animeTitle,
    required this.initialEpisode,
    required this.isHindi,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late WebViewController _controller;
  bool isLoading = true;
  bool hasError = false;
  List<Map<String, dynamic>> episodes = [];
  int currentEpisode = 1;
  Process? _serverProcess;

  @override
  void initState() {
    super.initState();
    currentEpisode = widget.initialEpisode;
    _initializePlayer();
    _loadEpisodes();
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
            setState(() {
              isLoading = true;
              hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            _showToast('❌ Player error: ${error.description}', isError: true);
            setState(() {
              isLoading = false;
              hasError = true;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'playerReady',
        onMessageReceived: (JavaScriptMessage message) {
          _showToast('🎉 Player Ready!');
          setState(() {
            isLoading = false;
            hasError = false;
          });
        },
      );
  }

  Future<void> _loadEpisodes() async {
    try {
      _showToast('📺 Loading ${widget.isHindi ? 'Hindi' : 'English'} episodes...');
      
      final episodeList = await PlayerHandler.getEpisodes(
        animeId: widget.animeId,
        isHindi: widget.isHindi,
      );
      
      setState(() {
        episodes = episodeList;
      });
      
      if (episodeList.isNotEmpty) {
        await _loadEpisode(currentEpisode);
      } else {
        _showToast('❌ No episodes found', isError: true);
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      _showToast('❌ Failed to load episodes: $e', isError: true);
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _loadEpisode(int episodeNumber) async {
    try {
      _showToast('🎬 Loading Episode $episodeNumber...');
      
      setState(() {
        isLoading = true;
        hasError = false;
        currentEpisode = episodeNumber;
      });

      // Find episode in list
      final episode = episodes.firstWhere(
        (ep) => ep['episode_number'] == episodeNumber,
        orElse: () => episodes.isNotEmpty ? episodes.first : {},
      );

      if (episode.isEmpty) {
        _showToast('❌ Episode $episodeNumber not found', isError: true);
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      // Get stream URL
      final streamUrl = await PlayerHandler.getStreamUrl(
        animeId: widget.animeId,
        episodeId: episode['episode_id'],
        isHindi: widget.isHindi,
      );

      if (streamUrl == null) {
        _showToast('❌ No stream URL found', isError: true);
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      // Start local server and load player
      await _startLocalServerAndLoadPlayer(streamUrl, episodeNumber);
      
    } catch (e) {
      _showToast('❌ Episode loading failed: $e', isError: true);
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _startLocalServerAndLoadPlayer(String streamUrl, int episodeNumber) async {
    try {
      _showToast('🚀 Starting local server...');
      
      // Stop existing server
      await _stopLocalServer();
      
      // Create dynamic HTML content
      final htmlContent = await _generateDynamicHTML(streamUrl, episodeNumber);
      
      // Write HTML to assets directory (in a real app, you'd use a temp directory)
      final htmlPath = '/tmp/player_${DateTime.now().millisecondsSinceEpoch}.html';
      await File(htmlPath).writeAsString(htmlContent);
      
      // Start simple HTTP server
      _serverProcess = await Process.start('python3', ['-m', 'http.server', '8001'], workingDirectory: '/tmp');
      
      // Wait a moment for server to start
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Load player in WebView
      final playerUrl = 'http://localhost:8001/player_${DateTime.now().millisecondsSinceEpoch}.html';
      await _controller.loadRequest(Uri.parse(playerUrl));
      
      _showToast('✅ Player loaded on localhost:8001');
      
    } catch (e) {
      _showToast('❌ Server start failed: $e', isError: true);
      // Fallback: Load HTML directly
      final htmlContent = await _generateDynamicHTML(streamUrl, episodeNumber);
      await _controller.loadHtmlString(htmlContent);
    }
  }

  Future<String> _generateDynamicHTML(String streamUrl, int episodeNumber) async {
    // Read template HTML
    const templatePath = 'lib/screens/player/assets/play.html';
    String template;
    
    try {
      template = await File(templatePath).readAsString();
    } catch (e) {
      // Fallback template if file not found
      template = '''
      <!DOCTYPE html>
      <html><head><title>Player</title><style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      body { background: #000; overflow: hidden; }
      iframe { width: 100vw; height: 100vh; border: none; }
      </style></head><body>
      <iframe src="{{STREAM_URL}}" allowfullscreen></iframe>
      </body></html>
      ''';
    }
    
    // Replace placeholders
    final playerData = PlayerHandler.generatePlayerData(
      animeTitle: widget.animeTitle,
      episodeNumber: episodeNumber,
      streamUrl: streamUrl,
      isHindi: widget.isHindi,
    );
    
    return template
        .replaceAll('{{TITLE}}', playerData['title'])
        .replaceAll('{{EPISODE}}', playerData['episode'].toString())
        .replaceAll('{{LANGUAGE}}', playerData['language'])
        .replaceAll('{{TYPE}}', playerData['type'])
        .replaceAll('{{TYPE_EMOJI}}', widget.isHindi ? '🇮🇳' : '🌐')
        .replaceAll('{{STREAM_URL}}', playerData['streamUrl'])
        .replaceAll('{{STREAM_URL_SHORT}}', playerData['streamUrl'].substring(0, 50));
  }

  Future<void> _stopLocalServer() async {
    if (_serverProcess != null) {
      _serverProcess!.kill();
      _serverProcess = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${widget.animeTitle} - Episode $currentEpisode (${widget.isHindi ? 'Hindi' : 'English'})',
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showEpisodeList,
          ),
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _showLanguageOptions,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!hasError)
            WebViewWidget(controller: _controller),
          
          if (hasError)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load episode',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadEpisode(currentEpisode),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          
          if (isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Loading player...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showEpisodeList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Episodes (${widget.isHindi ? 'Hindi' : 'English'})',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final episode = episodes[index];
                    final episodeNum = episode['episode_number'];
                    final isSelected = episodeNum == currentEpisode;
                    
                    return ListTile(
                      title: Text(
                        episode['title'],
                        style: TextStyle(
                          color: isSelected ? Colors.orange : Colors.white,
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? Colors.orange : Colors.grey,
                        child: Text(
                          episodeNum.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _loadEpisode(episodeNum);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Language',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
                title: const Text('Hindi', style: TextStyle(color: Colors.white)),
                trailing: widget.isHindi ? const Icon(Icons.check, color: Colors.orange) : null,
                onTap: () {
                  Navigator.pop(context);
                  if (!widget.isHindi) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          animeId: widget.animeId,
                          animeTitle: widget.animeTitle,
                          initialEpisode: currentEpisode,
                          isHindi: true,
                        ),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Text('🌐', style: TextStyle(fontSize: 24)),
                title: const Text('English', style: TextStyle(color: Colors.white)),
                trailing: !widget.isHindi ? const Icon(Icons.check, color: Colors.orange) : null,
                onTap: () {
                  Navigator.pop(context);
                  if (widget.isHindi) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerScreen(
                          animeId: widget.animeId,
                          animeTitle: widget.animeTitle,
                          initialEpisode: currentEpisode,
                          isHindi: false,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
