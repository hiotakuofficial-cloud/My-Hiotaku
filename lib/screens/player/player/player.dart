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
  String? errorMessage;
  List<Map<String, dynamic>> episodes = [];
  int currentEpisode = 1;
  String? detectedApiType;

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
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36')
      ..enableZoom(false)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
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
    try {
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

      // Load stream URL directly in WebView
      await _controller.loadRequest(Uri.parse(streamUrl));
      _showToast('✅ Episode $episodeNumber loaded');
      
    } catch (e) {
      _showToast('❌ Episode loading failed: $e', isError: true);
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
