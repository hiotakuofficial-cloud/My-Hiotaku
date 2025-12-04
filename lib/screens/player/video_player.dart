import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String episodeId;
  final String animeTitle;
  final int episodeNumber;
  final String language;

  const VideoPlayerScreen({
    Key? key,
    required this.episodeId,
    required this.animeTitle,
    required this.episodeNumber,
    this.language = 'sub',
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late WebViewController _controller;
  bool isLoading = true;
  bool hasError = false;
  String currentServer = 's-2';
  
  // Server fallback list
  final List<String> servers = ['s-2', 's-4'];
  final List<String> domains = [
    'https://megaplay.buzz',
    'https://vidwish.live',
  ];
  
  int currentServerIndex = 0;
  int currentDomainIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializePlayer();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _initializePlayer() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/91.0.4472.120 Mobile Safari/537.36')
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
            setState(() {
              hasError = true;
              isLoading = false;
            });
            _tryNextServer();
          },
        ),
      )
      ..loadHtmlString(_buildIframeHtml());
  }

  String _buildIframeHtml() {
    final streamUrl = _buildStreamUrl();
    return '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Video Player</title>
        <style>
            body { 
                margin: 0; 
                padding: 0; 
                background: #000; 
                overflow: hidden;
            }
            iframe { 
                width: 100vw; 
                height: 100vh; 
                border: none; 
                display: block;
            }
        </style>
    </head>
    <body>
        <iframe src="$streamUrl" 
                allowfullscreen 
                webkitallowfullscreen 
                mozallowfullscreen
                onerror="this.src='${_buildFallbackUrl()}'">
        </iframe>
    </body>
    </html>
    ''';
  }

  String _buildFallbackUrl() {
    final domain = domains[currentDomainIndex];
    final fallbackServer = currentServerIndex < servers.length - 1 
        ? servers[currentServerIndex + 1] 
        : 's-4';
    return '$domain/stream/$fallbackServer/${widget.episodeId}/${widget.language}';
  }

  String _buildStreamUrl() {
    final domain = domains[currentDomainIndex];
    final server = servers[currentServerIndex];
    return '$domain/stream/$server/${widget.episodeId}/${widget.language}';
  }

  void _tryNextServer() {
    if (currentServerIndex < servers.length - 1) {
      currentServerIndex++;
    } else if (currentDomainIndex < domains.length - 1) {
      currentDomainIndex++;
      currentServerIndex = 0;
    } else {
      // All servers failed
      return;
    }
    
    setState(() {
      hasError = false;
      isLoading = true;
    });
    
    _controller.loadRequest(Uri.parse(_buildStreamUrl()));
  }

  void _retry() {
    currentServerIndex = 0;
    currentDomainIndex = 0;
    setState(() {
      hasError = false;
      isLoading = true;
    });
    _controller.loadRequest(Uri.parse(_buildStreamUrl()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // WebView Player
            if (!hasError)
              WebViewWidget(controller: _controller),
            
            // Error State
            if (hasError)
              _buildErrorState(),
            
            // Loading State
            if (isLoading)
              _buildLoadingState(),
            
            // Top Controls
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildTopControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Row(
      children: [
        // Back Button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        SizedBox(width: 16),
        // Title
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.animeTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Episode ${widget.episodeNumber} • ${widget.language.toUpperCase()}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Color(0xFFFF8C00),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Loading Episode ${widget.episodeNumber}...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Server: ${domains[currentDomainIndex].split('//')[1]}/$currentServer',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[300],
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to Load Episode',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Episode ${widget.episodeNumber} is not available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8C00),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
