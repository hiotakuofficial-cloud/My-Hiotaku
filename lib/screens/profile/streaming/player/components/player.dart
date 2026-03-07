import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class VideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? posterUrl;
  final VoidCallback? onVideoEnd;

  const VideoPlayer({
    Key? key,
    required this.videoUrl,
    this.posterUrl,
    this.onVideoEnd,
  }) : super(key: key);

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late final Player _player;
  late final VideoController _controller;
  bool _showControls = true;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _initializePlayer();
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
          widget.onVideoEnd?.call();
        }
      });

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Media Kit error: $e');
    }
  }

  @override
  void dispose() {
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
                      _TopControls(),

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
    );
  }
}

// Top Controls (Back, Title, Settings)
class _TopControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ControlButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            _ControlButton(
              icon: Icons.cast,
              onTap: () {},
            ),
            const SizedBox(width: 12),
            _ControlButton(
              iconPath: 'assets/player/player_settings.png',
              onTap: () {},
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
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: iconPath != null
            ? Image.asset(
                iconPath!,
                width: 24,
                height: 24,
                color: Colors.white,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 24,
                ),
              )
            : Icon(
                icon ?? Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
      ),
    );
  }
}
