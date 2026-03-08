import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:async';
import 'last_watch.dart';
import 'options_setting.dart';
import '../../../../../services/moviebox_service.dart';

class VideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? posterUrl;
  final String? title;
  final String subjectId;
  final int season;
  final int episode;
  final VoidCallback? onVideoEnd;
  final Function(String quality)? onQualityChange;
  final Function(String speed)? onSpeedChange;

  const VideoPlayer({
    Key? key,
    required this.videoUrl,
    required this.subjectId,
    required this.season,
    required this.episode,
    this.posterUrl,
    this.title,
    this.onVideoEnd,
    this.onQualityChange,
    this.onSpeedChange,
  }) : super(key: key);

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late final Player _player;
  late final VideoController _controller;
  late final SettingsData _settingsData;
  bool _showControls = true;
  bool _isInitialized = false;
  bool _isFullscreen = false;
  bool _subtitlesEnabled = false;
  List<Map<String, dynamic>> _availableSubtitles = [];
  Timer? _saveTimer;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _settingsData = SettingsData(
      initialSpeed: '1.0x',
      initialQuality: '720p',
      initialLanguage: 'English',
    );
    _settingsData.addListener(_onSettingsChanged);
    _initializePlayer();
    _startSaveTimer();
  }

  void _onSettingsChanged() {
    // Handle speed change
    final speed = double.tryParse(_settingsData.currentSpeed.replaceAll('x', '')) ?? 1.0;
    _player.setRate(speed);
    widget.onSpeedChange?.call(_settingsData.currentSpeed);
    
    // Handle quality change - notify parent to switch video URL
    widget.onQualityChange?.call(_settingsData.currentQuality);
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _player.state.playing) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);
    
    if (_isFullscreen) {
      // Enter fullscreen
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      
      // Get video aspect ratio
      final videoWidth = _controller.player.state.width ?? 16;
      final videoHeight = _controller.player.state.height ?? 9;
      final aspectRatio = videoWidth / videoHeight;
      
      // Set orientation based on video aspect ratio
      if (aspectRatio > 1) {
        // Horizontal video
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        // Vertical video
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);
      }
    } else {
      // Exit fullscreen
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
  }

  @override
  void didUpdateWidget(VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload video if URL changes (quality/episode switch)
    if (oldWidget.videoUrl != widget.videoUrl && widget.videoUrl.isNotEmpty) {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    if (widget.videoUrl.isEmpty) return;

    setState(() => _isInitialized = false);

    try {
      await _player.open(
        Media(
          widget.videoUrl,
          httpHeaders: {
            'Referer': 'https://themoviebox.org/',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
          },
        ),
      );

      _player.stream.completed.listen((completed) {
        if (completed) {
          LastWatchHandler.clearPosition(
            subjectId: widget.subjectId,
            season: widget.season,
            episode: widget.episode,
          );
          widget.onVideoEnd?.call();
        }
      });

      setState(() => _isInitialized = true);

      // Check for saved position and auto-resume
      final savedPosition = await LastWatchHandler.getPosition(
        subjectId: widget.subjectId,
        season: widget.season,
        episode: widget.episode,
      );

      if (savedPosition != null && savedPosition > 5) {
        await _player.seek(Duration(seconds: savedPosition));
      }
      
      // Auto-play
      await _player.play();
      
      // Load subtitles
      _loadSubtitles();
      
      // Start auto-hide timer
      _showControlsTemporarily();
    } catch (e) {
      debugPrint('Media Kit error: $e');
    }
  }

  Future<void> _loadSubtitles() async {
    try {
      final captions = await MovieBoxService.getCaptions(
        id: widget.subjectId,
        subjectId: widget.subjectId,
        path: widget.subjectId,
      );
      
      final subtitles = captions['data']?['subtitles'] as List? ?? [];
      setState(() {
        _availableSubtitles = subtitles.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Subtitle load error: $e');
    }
  }

  void _toggleSubtitles() {
    setState(() => _subtitlesEnabled = !_subtitlesEnabled);
    // TODO: Apply subtitle track to player
    _showControlsTemporarily();
  }

  void _togglePiP() async {
    // TODO: Implement PiP mode
    _showControlsTemporarily();
  }

  void _startSaveTimer() {
    _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isInitialized && _player.state.playing) {
        final position = _player.state.position.inSeconds;
        LastWatchHandler.savePosition(
          subjectId: widget.subjectId,
          season: widget.season,
          episode: widget.episode,
          positionSeconds: position,
        );
      }
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _hideControlsTimer?.cancel();
    _settingsData.removeListener(_onSettingsChanged);
    _settingsData.dispose();
    _player.dispose();
    // Reset orientation on dispose
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  void _togglePlayPause() {
    _player.playOrPause();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: () {
          if (_showControls) {
            setState(() => _showControls = false);
            _hideControlsTimer?.cancel();
          } else {
            _showControlsTemporarily();
          }
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Surface
              if (_isInitialized)
                SizedBox.expand(
                  child: Video(
                    controller: _controller,
                    controls: NoVideoControls,
                  ),
                )
              else if (widget.posterUrl != null)
                Image.network(
                  widget.posterUrl!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              else
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE5003C)),
                ),

              // Overlay
              if (_showControls && _isInitialized)
                Container(
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
                ),

              // Controls
              if (_showControls && _isInitialized)
                StreamBuilder<bool>(
                  stream: _player.stream.playing,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Controls
                        _TopControls(
                          title: widget.title,
                          onSettingsTap: () => VideoSettingsDialog.show(context, _settingsData),
                          onSubtitleTap: _toggleSubtitles,
                        ),

                        // Center Play/Pause
                        _CenterControls(
                          isPlaying: isPlaying,
                          onPlayPause: _togglePlayPause,
                        ),

                        // Bottom Controls
                        _BottomControls(
                          player: _player,
                          onPlayPause: _togglePlayPause,
                          isFullscreen: _isFullscreen,
                          onFullscreenToggle: _toggleFullscreen,
                          onPiPToggle: _togglePiP,
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Top Controls (Back, Title, Settings)
class _TopControls extends StatelessWidget {
  final String? title;
  final VoidCallback onSettingsTap;
  final VoidCallback onSubtitleTap;

  const _TopControls({
    this.title,
    required this.onSettingsTap,
    required this.onSubtitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ControlButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.pop(context),
          ),
            if (title != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'MazzardH',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const Spacer(),
            _ControlButton(
              icon: Icons.closed_caption_outlined,
              onTap: onSubtitleTap,
            ),
            const SizedBox(width: 12),
            _ControlButton(
              iconPath: 'assets/player/player_settings.png',
              onTap: onSettingsTap,
            ),
          ],
        ),
      );
  }
}

// Center Play/Pause Button
class _CenterControls extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const _CenterControls({
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  State<_CenterControls> createState() => _CenterControlsState();
}

class _CenterControlsState extends State<_CenterControls> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    _animController.forward().then((_) {
      _animController.reverse();
    });
    widget.onPlayPause();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Icon(
          widget.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }
}

// Bottom Controls (Progress, Time, Buttons)
class _BottomControls extends StatelessWidget {
  final Player player;
  final VoidCallback onPlayPause;
  final bool isFullscreen;
  final VoidCallback onFullscreenToggle;
  final VoidCallback onPiPToggle;

  const _BottomControls({
    required this.player,
    required this.onPlayPause,
    required this.isFullscreen,
    required this.onFullscreenToggle,
    required this.onPiPToggle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.stream.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: player.stream.duration,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data?.inSeconds.toDouble() ?? 0.0;
            final duration = durationSnapshot.data?.inSeconds.toDouble() ?? 0.0;
            
            // Don't show controls if duration not loaded yet
            if (duration < 1) {
              return const SizedBox.shrink();
            }
            
            final remaining = duration > position ? duration - position : 0.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time Labels
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'MazzardH',
                        ),
                      ),
                      Text(
                        '-${_formatDuration(remaining)}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'MazzardH',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: const Color(0xFFE5003C),
                            inactiveTrackColor: Colors.white.withOpacity(0.2),
                            thumbColor: const Color(0xFFE5003C),
                            overlayColor: const Color(0xFFE5003C).withOpacity(0.3),
                          ),
                          child: Slider(
                            value: duration > 0 ? position.clamp(0.0, duration) : 0.0,
                            max: duration > 0 ? duration : 1.0,
                            onChanged: (value) {
                              player.seek(Duration(seconds: value.toInt()));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        iconPath: 'assets/player/pip.png',
                        onTap: onPiPToggle,
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: onFullscreenToggle,
                        child: Image.asset(
                          'assets/player/fullscreen.png',
                          width: 20,
                          height: 20,
                          color: isFullscreen ? const Color(0xFFE5003C) : Colors.white,
                          errorBuilder: (_, __, ___) => Icon(
                            isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                            color: isFullscreen ? const Color(0xFFE5003C) : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(double seconds) {
    final int min = (seconds / 60).floor();
    final int sec = (seconds % 60).floor();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}

// Control Button Widget
class _ControlButton extends StatelessWidget {
  final IconData? icon;
  final String? iconPath;
  final VoidCallback onTap;

  const _ControlButton({
    this.icon,
    this.iconPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: iconPath != null
          ? Image.asset(
              iconPath!,
              width: 20,
              height: 20,
              color: Colors.white,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.settings,
                color: Colors.white,
                size: 20,
              ),
            )
          : Icon(
              icon ?? Icons.play_arrow,
              color: Colors.white,
              size: 20,
            ),
    );
  }
}
