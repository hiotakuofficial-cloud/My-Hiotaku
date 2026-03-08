import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:async';
import '../../../../services/moviebox_service.dart';
import 'widgets/play_pause_button.dart';
import 'widgets/seekbar.dart';
import 'widgets/subtitle_selector.dart';
import 'widgets/audio_track_selector.dart';
import 'widgets/fullscreen_button.dart';
import 'widgets/brightness_gesture.dart';
import 'widgets/volume_gesture.dart';
import 'widgets/quality_selector.dart';
import 'widgets/buffer_indicator.dart';
import 'widgets/pip_button.dart';

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String? posterUrl;
  final String? title;
  final String subjectId;
  final String detailPath;
  final int season;
  final int episode;
  final List<String> availableQualities;

  const VideoPlayerPage({
    Key? key,
    required this.videoUrl,
    required this.subjectId,
    required this.detailPath,
    required this.season,
    required this.episode,
    this.posterUrl,
    this.title,
    this.availableQualities = const ['360p', '480p', '720p', '1080p'],
  }) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late Player _player;
  late VideoController _controller;
  bool _showControls = false; // Start hidden
  bool _isFullscreen = false;
  bool _isBuffering = true; // Start with loading
  bool _isInitialized = false;
  Timer? _hideTimer;
  String _currentVideoUrl = '';

  @override
  void initState() {
    super.initState();
    _currentVideoUrl = widget.videoUrl;
    _player = Player();
    _controller = VideoController(_player);
    _initPlayer();
  }

  Future<void> _changeAudioTrack(String newSubjectId, String newDetailPath, String language) async {
    setState(() => _isBuffering = true);
    
    try {
      final playData = await MovieBoxService.getPlayUrls(
        id: newSubjectId,
        path: newDetailPath,
        season: widget.season,
        episode: widget.episode,
      );
      
      final streams = playData['data']?['streams'] as List? ?? [];
      if (streams.isEmpty) {
        setState(() => _isBuffering = false);
        return;
      }
      
      // Get 720p or first available
      final stream = streams.firstWhere(
        (s) => s['resolutions'] == '720',
        orElse: () => streams.first,
      );
      
      final newUrl = stream['url'] as String? ?? '';
      if (newUrl.isNotEmpty) {
        final currentPosition = _player.state.position;
        
        await _player.open(
          Media(
            newUrl,
            httpHeaders: {
              'Referer': 'https://themoviebox.org/',
              'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36',
            },
          ),
        );
        
        await _player.seek(currentPosition);
        await _player.play();
        
        setState(() {
          _currentVideoUrl = newUrl;
          _isBuffering = false;
        });
      }
    } catch (e) {
      setState(() => _isBuffering = false);
      debugPrint('Audio track change error: $e');
    }
  }

  Future<void> _changeQuality(String quality) async {
    setState(() => _isBuffering = true);
    
    try {
      final playData = await MovieBoxService.getPlayUrls(
        id: widget.subjectId,
        path: widget.detailPath,
        season: widget.season,
        episode: widget.episode,
      );
      
      final streams = playData['data']?['streams'] as List? ?? [];
      final stream = streams.firstWhere(
        (s) => s['resolutions'] == quality.replaceAll('p', ''),
        orElse: () => streams.first,
      );
      
      final newUrl = stream['url'] as String? ?? '';
      if (newUrl.isNotEmpty) {
        final currentPosition = _player.state.position;
        
        await _player.open(
          Media(
            newUrl,
            httpHeaders: {
              'Referer': 'https://themoviebox.org/',
              'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36',
            },
          ),
        );
        
        await _player.seek(currentPosition);
        await _player.play();
        
        setState(() {
          _currentVideoUrl = newUrl;
          _isBuffering = false;
        });
      }
    } catch (e) {
      setState(() => _isBuffering = false);
      debugPrint('Quality change error: $e');
    }
  }

  Future<void> _initPlayer() async {
    try {
      await _player.open(
        Media(
          _currentVideoUrl,
          httpHeaders: {
            'Referer': 'https://themoviebox.org/',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36',
          },
        ),
      );
      
      // Wait for video to be ready
      await _player.play();
      
      setState(() {
        _isInitialized = true;
        _isBuffering = false;
        _showControls = true; // Show controls after video loads
      });
      
      _startHideTimer();
    } catch (e) {
      setState(() => _isBuffering = false);
      debugPrint('Player init error: $e');
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _player.state.playing) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) _startHideTimer();
  }

  void _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _player.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Surface
          Center(child: Video(controller: _controller)),

          // Brightness Gesture (Left Side) - Only in fullscreen
          if (_isFullscreen)
            BrightnessGesture(showControls: _showControls),

          // Volume Gesture (Right Side) - Only in fullscreen
          if (_isFullscreen)
            VolumeGesture(showControls: _showControls),

          // Tap to Toggle Controls
          GestureDetector(
            onTap: _toggleControls,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),

          // Buffer Indicator
          if (_isBuffering)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE5003C),
                strokeWidth: 3,
              ),
            ),
          
          BufferIndicator(player: _player),

          // Controls Overlay
          if (_showControls)
            _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Bar
          _buildTopBar(),

          // Center Play/Pause
          PlayPauseButton(
            player: _player,
            onTap: _startHideTimer,
          ),

          // Bottom Controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            if (widget.title != null) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'MazzardH',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const Spacer(),
            // Subtitle Selector
            SubtitleSelector(
              subjectId: widget.subjectId,
              detailPath: widget.subjectId,
              onSubtitleSelect: (url, lang) {
                _player.setSubtitleTrack(SubtitleTrack.uri(url));
              },
              onTap: _startHideTimer,
            ),
            const SizedBox(width: 8),
            // Audio Track Selector
            AudioTrackSelector(
              subjectId: widget.subjectId,
              detailPath: widget.detailPath,
              onAudioSelect: _changeAudioTrack,
              onTap: _startHideTimer,
            ),
            const SizedBox(width: 8),
            // Quality Selector
            QualitySelector(
              availableQualities: widget.availableQualities,
              onQualityChange: _changeQuality,
              onTap: _startHideTimer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Seekbar
          Seekbar(
            player: _player,
            onSeek: _startHideTimer,
          ),
          const SizedBox(height: 8),
          // Bottom Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // PiP Button
              PipButton(
                player: _player,
                onTap: _startHideTimer,
              ),
              const SizedBox(width: 16),
              // Fullscreen Button
              FullscreenButton(
                isFullscreen: _isFullscreen,
                onToggle: _toggleFullscreen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
