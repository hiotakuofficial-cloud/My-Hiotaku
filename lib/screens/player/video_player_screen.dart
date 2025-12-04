import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'handler/player_handler.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String animeId;
  final String animeTitle;
  final bool isHindi;
  final int initialEpisode;

  const VideoPlayerScreen({
    Key? key,
    required this.animeId,
    required this.animeTitle,
    required this.isHindi,
    this.initialEpisode = 1,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late WebViewController _controller;
  List<Map<String, dynamic>> episodes = [];
  int currentEpisodeNumber = 1;
  String currentLanguage = 'sub';
  bool isLoading = true;
  bool hasError = false;
  bool isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    currentEpisodeNumber = widget.initialEpisode;
    currentLanguage = widget.isHindi ? 'hindi' : 'sub';
    _initializePlayer();
    _loadEpisodes();
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
              isPlayerReady = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
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
          print('🎬 Player ready: ${message.message}');
          setState(() {
            isPlayerReady = true;
            isLoading = false;
            hasError = false;
          });
        },
      );
  }

  Future<void> _loadEpisodes() async {
    try {
      final episodeList = await PlayerHandler.getEpisodes(widget.animeId, widget.isHindi);
      setState(() {
        episodes = episodeList;
      });
      
      // Load initial episode
      await _loadEpisode(currentEpisodeNumber);
    } catch (e) {
      print('❌ Error loading episodes: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _loadEpisode(int episodeNumber) async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        isPlayerReady = false;
        currentEpisodeNumber = episodeNumber;
      });

      final episode = PlayerHandler.getEpisodeByNumber(episodes, episodeNumber);
      if (episode == null) {
        throw Exception('Episode not found');
      }

      final episodeId = episode['episode_id'].toString();
      
      final html = await PlayerHandler.generatePlayerHTML(
        animeId: widget.animeId,
        episodeId: episodeId,
        episodeNumber: episodeNumber,
        animeTitle: widget.animeTitle,
        isHindi: widget.isHindi,
        language: currentLanguage,
      );

      await _controller.loadHtmlString(html);
    } catch (e) {
      print('❌ Error loading episode: $e');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  void _changeLanguage(String language) {
    if (currentLanguage != language) {
      setState(() {
        currentLanguage = language;
      });
      _loadEpisode(currentEpisodeNumber);
    }
  }

  void _nextEpisode() {
    final nextEpisode = PlayerHandler.getNextEpisode(episodes, currentEpisodeNumber);
    if (nextEpisode != null) {
      _loadEpisode(nextEpisode['episode_number']);
    }
  }

  void _previousEpisode() {
    final prevEpisode = PlayerHandler.getPreviousEpisode(episodes, currentEpisodeNumber);
    if (prevEpisode != null) {
      _loadEpisode(prevEpisode['episode_number']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Video Player Section
            Container(
              height: MediaQuery.of(context).size.height * 0.3,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                children: [
                  // WebView Player
                  if (!hasError)
                    WebViewWidget(controller: _controller),
                  
                  // Loading Indicator
                  if (isLoading)
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.orange),
                            SizedBox(height: 16),
                            Text(
                              'Loading ${widget.isHindi ? 'Hindi' : 'English'} Episode $currentEpisodeNumber...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Error State
                  if (hasError)
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load episode',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _loadEpisode(currentEpisodeNumber),
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Back Button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Controls Section
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[900],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Episode Info
                  Text(
                    PlayerHandler.generateEpisodeTitle(
                      widget.animeTitle,
                      currentEpisodeNumber,
                      episodes.isNotEmpty ? episodes.firstWhere(
                        (ep) => ep['episode_number'] == currentEpisodeNumber,
                        orElse: () => {'title': null},
                      )['title'] : null,
                    ),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Language and Episode Controls
                  Row(
                    children: [
                      // Language Selection (only for English)
                      if (!widget.isHindi) ...[
                        _buildLanguageButton('SUB', 'sub'),
                        SizedBox(width: 8),
                        _buildLanguageButton('DUB', 'dub'),
                        SizedBox(width: 16),
                      ],
                      
                      // Episode Navigation
                      IconButton(
                        onPressed: PlayerHandler.getPreviousEpisode(episodes, currentEpisodeNumber) != null
                            ? _previousEpisode
                            : null,
                        icon: Icon(Icons.skip_previous, color: Colors.white),
                      ),
                      
                      Text(
                        'Episode $currentEpisodeNumber',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      
                      IconButton(
                        onPressed: PlayerHandler.getNextEpisode(episodes, currentEpisodeNumber) != null
                            ? _nextEpisode
                            : null,
                        icon: Icon(Icons.skip_next, color: Colors.white),
                      ),
                      
                      Spacer(),
                      
                      // Player Status
                      if (isPlayerReady)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.isHindi ? '🇮🇳 Hindi' : '🌐 ${currentLanguage.toUpperCase()}',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Episodes List
            Expanded(
              child: Container(
                color: Colors.black,
                child: episodes.isEmpty
                    ? Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    : ListView.builder(
                        itemCount: episodes.length,
                        itemBuilder: (context, index) {
                          final episode = episodes[index];
                          final episodeNumber = episode['episode_number'];
                          final isCurrentEpisode = episodeNumber == currentEpisodeNumber;
                          
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCurrentEpisode ? Colors.orange : Colors.grey[800],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isCurrentEpisode ? Colors.white : Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    episodeNumber.toString(),
                                    style: TextStyle(
                                      color: isCurrentEpisode ? Colors.orange : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                episode['title'] ?? 'Episode $episodeNumber',
                                style: TextStyle(
                                  color: isCurrentEpisode ? Colors.black : Colors.white,
                                  fontWeight: isCurrentEpisode ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: isCurrentEpisode
                                  ? Text(
                                      'Currently Playing',
                                      style: TextStyle(color: Colors.black54),
                                    )
                                  : null,
                              trailing: isCurrentEpisode
                                  ? Icon(Icons.play_arrow, color: Colors.black)
                                  : Icon(Icons.play_arrow_outlined, color: Colors.white54),
                              onTap: () {
                                if (!isCurrentEpisode) {
                                  _loadEpisode(episodeNumber);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(String label, String language) {
    final isSelected = currentLanguage == language;
    return GestureDetector(
      onTap: () => _changeLanguage(language),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.transparent,
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
