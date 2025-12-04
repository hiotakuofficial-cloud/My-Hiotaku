import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'handler/player_handler.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String episodeId;
  final String animeTitle;
  final int episodeNumber;
  final String language;
  final String? episodeTitle;

  const VideoPlayerScreen({
    Key? key,
    required this.episodeId,
    required this.animeTitle,
    required this.episodeNumber,
    this.language = 'sub',
    this.episodeTitle,
  }) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late WebViewController _controller;
  bool isLoading = true;
  bool hasError = false;
  int currentDomainIndex = 0;
  int currentServerIndex = 0;

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
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36')
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
            _handleError();
          },
        ),
      )
      ..addJavaScriptChannel(
        'playerReady',
        onMessageReceived: (JavaScriptMessage message) {
          print('🎬 Player ready: ${message.message}');
          setState(() {
            isLoading = false;
            hasError = false;
          });
        },
      )
      ..loadHtmlString(_generatePlayerHtml());
  }

  String _generatePlayerHtml() {
    return PlayerHandler.generateWorkingMegaPlayHtml(
      episodeId: widget.episodeId,
      animeTitle: widget.animeTitle,
      episodeNumber: widget.episodeNumber,
      language: widget.language,
      server: PlayerHandler.streamServers[currentServerIndex],
      domainIndex: currentDomainIndex,
    );
  }

  void _handleError() {
    if (currentServerIndex < PlayerHandler.streamServers.length - 1) {
      currentServerIndex++;
    } else if (currentDomainIndex < PlayerHandler.streamDomains.length - 1) {
      currentDomainIndex++;
      currentServerIndex = 0;
    } else {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      return;
    }
    
    _retryWithNewServer();
  }

  void _retryWithNewServer() {
    setState(() {
      hasError = false;
      isLoading = true;
    });
    _controller.loadHtmlString(_generatePlayerHtml());
  }

  void _retry() {
    currentServerIndex = 0;
    currentDomainIndex = 0;
    _retryWithNewServer();
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
              'Server: ${PlayerHandler.streamDomains[currentDomainIndex].split('//')[1]}/${PlayerHandler.streamServers[currentServerIndex]}',
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
