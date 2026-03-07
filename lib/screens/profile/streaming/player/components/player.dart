import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:async';
import 'last_watch.dart';
import 'options_setting.dart';

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
  Timer? _saveTimer;

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
    
    // Handle quality change
    widget.onQualityChange?.call(_settingsData.currentQuality);
  }

  @override
  void didUpdateWidget(VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
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
    } catch (e) {
      debugPrint('Media Kit error: $e');
    }
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
    _settingsData.removeListener(_onSettingsChanged);
    _settingsData.dispose();
    _player.dispose();
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
          setState(() => _showControls = !_showControls);
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video Surface
              if (_isInitialized)
                Video(
                  controller: _controller,
                  controls: NoVideoControls,
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

  const _TopControls({
    this.title,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              icon: Icons.cast,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            _ControlButton(
              icon: Icons.closed_caption_outlined,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            _ControlButton(
              iconPath: 'assets/player/player_settings.png',
              onTap: onSettingsTap,
            ),
          ],
        ),
      ),
    );
  }
}

// Center Play/Pause Button
class _CenterControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onPlayPause;

  const _CenterControls({
    required this.isPlaying,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPlayPause,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 48,
        ),
      ),
    );
  }
}

// Bottom Controls (Progress, Time, Buttons)
class _BottomControls extends StatelessWidget {
  final Player player;
  final VoidCallback onPlayPause;

  const _BottomControls({
    required this.player,
    required this.onPlayPause,
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
            final duration = durationSnapshot.data?.inSeconds.toDouble() ?? 1.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'MazzardH',
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: position.clamp(0.0, duration),
                          max: duration > 0 ? duration : 1.0,
                          activeColor: const Color(0xFFE5003C),
                          inactiveColor: Colors.white.withOpacity(0.3),
                          onChanged: (value) {
                            player.seek(Duration(seconds: value.toInt()));
                          },
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontFamily: 'MazzardH',
                        ),
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        iconPath: 'assets/player/pip.png',
                        onTap: () {},
                      ),
                      const SizedBox(width: 16),
                      _ControlButton(
                        iconPath: 'assets/player/fullscreen.png',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),

                // Control Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: StreamBuilder<bool>(
                    stream: player.stream.playing,
                    builder: (context, snapshot) {
                      final isPlaying = snapshot.data ?? false;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _ControlButton(
                                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                                onTap: onPlayPause,
                              ),
                              const SizedBox(width: 16),
                              _ControlButton(
                                icon: Icons.skip_next,
                                onTap: () {},
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _ControlButton(
                                iconPath: 'assets/player/subtitles.png',
                                onTap: () {},
                              ),
                              const SizedBox(width: 16),
                              _ControlButton(
                                iconPath: 'assets/player/aspect_ratio.png',
                                onTap: () {},
                              ),
                            ],
                          ),
                        ],
                      );
                    },
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
