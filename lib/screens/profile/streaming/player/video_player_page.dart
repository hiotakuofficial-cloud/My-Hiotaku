import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller/video_player_controller.dart';
import 'widgets/seekbar.dart';
import 'widgets/subtitle_selector.dart';
import 'widgets/audio_track_selector.dart';
import 'widgets/fullscreen_button.dart';
import 'widgets/brightness_gesture.dart';
import 'widgets/volume_gesture.dart';
import 'widgets/quality_selector.dart';
import 'widgets/pip_button.dart';
import 'widgets/custom_buffering_loader.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
  late VideoPlayerController _controller;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController(
      initialVideoUrl: widget.videoUrl,
      subjectId: widget.subjectId,
      detailPath: widget.detailPath,
      season: widget.season,
      episode: widget.episode,
      availableQualities: widget.availableQualities,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
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
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            top: !_isFullscreen,
            bottom: !_isFullscreen,
            left: false,
            right: false,
            child: Stack(
              children: [
                // Video Surface
                Center(
                  child: Video(
                    controller: _controller.videoController,
                    controls: NoVideoControls,
                  ),
                ),

              // Tap to Toggle Controls (Behind gestures)
              GestureDetector(
                onTap: _controller.toggleControls,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),

              // Brightness Gesture (Left Side) - Only in fullscreen and controls hidden
              if (_isFullscreen && !_controller.showControls)
                BrightnessGesture(showControls: _controller.showControls),

              // Volume Gesture (Right Side) - Only in fullscreen and controls hidden
              if (_isFullscreen && !_controller.showControls)
                VolumeGesture(showControls: _controller.showControls),

              // Custom Buffering Animation
              Center(
                child: BufferingLoader(
                  isVisible: _controller.isBuffering,
                ),
              ),

              // Controls Overlay with Fade Animation
              AnimatedOpacity(
                opacity: _controller.showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !_controller.showControls,
                  child: _buildControls(),
                ),
              ),
            ],
          ),
        ),
      );
      },
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

          // Bottom Controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
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
          SubtitleSelector(
            subjectId: widget.subjectId,
            detailPath: widget.detailPath,
            season: widget.season,
            episode: widget.episode,
            onSubtitleSelect: _controller.setSubtitle,
            onTap: _controller.startHideTimer,
          ),
          const SizedBox(width: 8),
          AudioTrackSelector(
            subjectId: widget.subjectId,
            detailPath: widget.detailPath,
            onAudioSelect: (id, path, lang) => _controller.changeAudioTrack(id, path),
            onTap: _controller.startHideTimer,
          ),
          const SizedBox(width: 8),
          QualitySelector(
            availableQualities: widget.availableQualities,
            onQualityChange: _controller.changeQuality,
            onTap: _controller.startHideTimer,
          ),
        ],
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
            player: _controller.player,
            onSeek: _controller.startHideTimer,
          ),
          const SizedBox(height: 8),
          // Bottom Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Previous | Play/Pause | Next
              Row(
                children: [
                  // Previous Episode Button
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous,
                      color: widget.episode > 1 ? Colors.white : Colors.grey,
                      size: 28,
                    ),
                    onPressed: widget.episode > 1 ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerPage(
                            videoUrl: '', // Will be loaded by controller
                            subjectId: widget.subjectId,
                            detailPath: widget.detailPath,
                            season: widget.season,
                            episode: widget.episode - 1,
                            title: widget.title,
                            availableQualities: widget.availableQualities,
                          ),
                        ),
                      );
                    } : null,
                  ),
                  // Play/Pause Button
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, child) {
                      final isPlaying = _controller.player.state.playing;
                      return IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          _controller.player.playOrPause();
                          _controller.startHideTimer();
                        },
                      );
                    },
                  ),
                  // Next Episode Button
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerPage(
                            videoUrl: '', // Will be loaded by controller
                            subjectId: widget.subjectId,
                            detailPath: widget.detailPath,
                            season: widget.season,
                            episode: widget.episode + 1,
                            title: widget.title,
                            availableQualities: widget.availableQualities,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              // Right: PiP | Fullscreen
              Row(
                children: [
                  // PiP Button
                  PipButton(
                    onTap: _controller.startHideTimer,
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
        ],
      ),
    );
  }
}
