import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'controller/video_player_controller.dart';
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
          body: Stack(
            children: [
              // Video Surface
              Center(child: Video(controller: _controller.videoController)),

              // Tap to Toggle Controls (Behind gestures)
              GestureDetector(
                onTap: _controller.toggleControls,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),

              // Brightness Gesture (Left Side) - Only in fullscreen
              if (_isFullscreen)
                BrightnessGesture(showControls: _controller.showControls),

              // Volume Gesture (Right Side) - Only in fullscreen
              if (_isFullscreen)
                VolumeGesture(showControls: _controller.showControls),

              // Buffer Indicator
              Center(
                child: BufferingLoader(
                  isVisible: _controller.isBuffering,
                ),
              ),
              
              BufferIndicator(player: _controller.player),

              // Controls Overlay
              if (_controller.showControls)
                _buildControls(),
            ],
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

          // Center Play/Pause
          PlayPauseButton(
            player: _controller.player,
            onTap: _controller.startHideTimer,
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
              detailPath: widget.detailPath,
              season: widget.season,
              episode: widget.episode,
              onSubtitleSelect: _controller.setSubtitle,
              onTap: _controller.startHideTimer,
            ),
            const SizedBox(width: 8),
            // Audio Track Selector
            AudioTrackSelector(
              subjectId: widget.subjectId,
              detailPath: widget.detailPath,
              onAudioSelect: (id, path, lang) => _controller.changeAudioTrack(id, path),
              onTap: _controller.startHideTimer,
            ),
            const SizedBox(width: 8),
            // Quality Selector
            QualitySelector(
              availableQualities: widget.availableQualities,
              onQualityChange: _controller.changeQuality,
              onTap: _controller.startHideTimer,
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
            player: _controller.player,
            onSeek: _controller.startHideTimer,
          ),
          const SizedBox(height: 8),
          // Bottom Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
    );
  }
}
