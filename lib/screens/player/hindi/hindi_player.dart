import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../handler/player_handler.dart';

class HindiPlayerScreen extends StatefulWidget {
  final String animeId;
  final String animeTitle;
  final String initialEpisode;

  const HindiPlayerScreen({
    Key? key,
    required this.animeId,
    required this.animeTitle,
    required this.initialEpisode,
  }) : super(key: key);

  @override
  State<HindiPlayerScreen> createState() => _HindiPlayerScreenState();
}

class _HindiPlayerScreenState extends State<HindiPlayerScreen> {
  late WebViewController _controller;
  bool isLoading = true;
  bool hasError = false;
  List<Map<String, dynamic>> episodes = [];
  String currentEpisode = '';

  @override
  void initState() {
    super.initState();
    currentEpisode = widget.initialEpisode;
    _initializePlayer();
    _loadEpisodes();
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
      final episodeList = await PlayerHandler.getHindiEpisodes(widget.animeId);
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

  Future<void> _loadEpisode(String episodeNumber) async {
    try {
      _showToast('🎬 Loading Episode $episodeNumber...');
      
      setState(() {
        isLoading = true;
        hasError = false;
        currentEpisode = episodeNumber;
      });

      final streamUrl = await PlayerHandler.getHindiStreamUrl(widget.animeId, episodeNumber);
      
      if (streamUrl == null) {
        _showToast('❌ No stream URL found', isError: true);
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      final html = _generatePlayerHTML(streamUrl, episodeNumber);
      await _controller.loadHtmlString(html);
      
    } catch (e) {
      _showToast('❌ Episode loading failed: $e', isError: true);
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  String _generatePlayerHTML(String streamUrl, String episodeNumber) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${widget.animeTitle} - Episode $episodeNumber (Hindi)</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
                background: #000; 
                overflow: hidden;
                font-family: Arial, sans-serif;
            }
            iframe { 
                width: 100vw; 
                height: 100vh; 
                border: none;
                pointer-events: auto;
            }
            .debug {
                position: absolute;
                top: 10px;
                left: 10px;
                background: rgba(0,0,0,0.8);
                color: white;
                padding: 10px;
                border-radius: 5px;
                font-size: 12px;
                z-index: 1000;
                max-width: 300px;
            }
            .loading {
                position: absolute;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                color: white;
                text-align: center;
                z-index: 999;
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
        <div class="debug" id="debug">
            🇮🇳 Hindi Player<br>
            Anime: ${widget.animeTitle}<br>
            Episode: $episodeNumber<br>
            Status: Loading...
        </div>
        
        <div class="loading" id="loading">
            <div class="spinner"></div>
            <p>Loading Hindi Episode $episodeNumber...</p>
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
            console.log("🇮🇳 Hindi Player Starting");
            console.log("📺 ${widget.animeTitle} - Episode $episodeNumber");
            console.log("🌐 Stream: $streamUrl");
            
            const debug = document.getElementById('debug');
            const loading = document.getElementById('loading');
            const iframe = document.getElementById('videoFrame');
            
            iframe.onload = function() {
                loading.style.display = 'none';
                debug.innerHTML = \`
                    🇮🇳 Hindi Player<br>
                    Anime: ${widget.animeTitle}<br>
                    Episode: $episodeNumber<br>
                    Status: ✅ Ready
                \`;
                console.log("✅ Hindi player ready");
            };
            
            iframe.onerror = function() {
                loading.innerHTML = '<p style="color: red;">❌ Failed to load</p>';
                debug.innerHTML = \`
                    🇮🇳 Hindi Player<br>
                    Anime: ${widget.animeTitle}<br>
                    Episode: $episodeNumber<br>
                    Status: ❌ Error
                \`;
            };
            
            // Hide debug after 30 seconds
            setTimeout(() => debug.style.display = 'none', 30000);
            
            // Notify Flutter
            if (window.flutter_inappwebview) {
                window.flutter_inappwebview.callHandler('playerReady', {
                    type: 'hindi',
                    episode: '$episodeNumber',
                    title: '${widget.animeTitle}'
                });
            }
        </script>
    </body>
    </html>
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${widget.animeTitle} - Episode $currentEpisode',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: _showEpisodeList,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (!hasError)
            WebViewWidget(controller: _controller),
          
          if (hasError)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load episode',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.orange),
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
              const Text(
                'Episodes',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    final episode = episodes[index];
                    final episodeNum = episode['episode'];
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
                          episodeNum,
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
}
