import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'controller/video_player_controller.dart';
import 'widgets/seekbar.dart';
import 'widgets/subtitle_selector.dart';
import 'widgets/audio_track_selector.dart';
import 'widgets/brightness_gesture.dart';
import 'widgets/volume_gesture.dart';
import 'widgets/quality_selector.dart';
import 'widgets/pip_button.dart';
import 'widgets/custom_buffering_loader.dart';
import 'video_player_page.dart';

class ResponsiveVideoPlayerPage extends StatefulWidget {
  final String videoUrl;
  final String? posterUrl;
  final String? title;
  final String subjectId;
  final String detailPath;
  final int season;
  final int episode;
  final List<String> availableQualities;
  final List<Map<String, dynamic>> recommendations;

  const ResponsiveVideoPlayerPage({
    Key? key,
    required this.videoUrl,
    required this.subjectId,
    required this.detailPath,
    required this.season,
    required this.episode,
    this.posterUrl,
    this.title,
    this.availableQualities = const ['360p', '480p', '720p', '1080p'],
    this.recommendations = const [],
  }) : super(key: key);

  @override
  State<ResponsiveVideoPlayerPage> createState() => _ResponsiveVideoPlayerPageState();
}

class _ResponsiveVideoPlayerPageState extends State<ResponsiveVideoPlayerPage> {
  late VideoPlayerController _controller;

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
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          videoUrl: widget.videoUrl,
          subjectId: widget.subjectId,
          detailPath: widget.detailPath,
          season: widget.season,
          episode: widget.episode,
          posterUrl: widget.posterUrl,
          title: widget.title,
          availableQualities: widget.availableQualities,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // Remove AppBar height
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVideoPlayer(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildTitle(),
                  const SizedBox(height: 12),
                  _buildRatingAndGenres(),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildSeasonSelection(),
                  const SizedBox(height: 24),
                  _buildRecommendations(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.25, // 25% height
      child: Container(
        color: Colors.black,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: Video(
                    controller: _controller.videoController,
                    controls: NoVideoControls,
                  ),
                ),
                // Tap detector BEHIND controls
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _controller.toggleControls,
                    behavior: HitTestBehavior.translucent,
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // No gestures in responsive mode (only in fullscreen)
                Center(child: BufferingLoader(isVisible: _controller.isBuffering)),
                // Controls ON TOP
                if (_controller.showControls)
                  Positioned.fill(
                    child: _buildControls(),
                  ),
              ],
            );
          },
        ),
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
          _buildTopBar(),
          const SizedBox.shrink(), // Empty center
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          if (widget.title != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title!,
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
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Seekbar(
            player: _controller.player,
            onSeek: _controller.startHideTimer,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Previous | Play/Pause | Next
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.skip_previous,
                      color: widget.episode > 1 ? Colors.white : Colors.grey,
                      size: 24,
                    ),
                    onPressed: widget.episode > 1 ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResponsiveVideoPlayerPage(
                            videoUrl: '',
                            subjectId: widget.subjectId,
                            detailPath: widget.detailPath,
                            season: widget.season,
                            episode: widget.episode - 1,
                            title: widget.title,
                            posterUrl: widget.posterUrl,
                            availableQualities: widget.availableQualities,
                            recommendations: widget.recommendations,
                          ),
                        ),
                      );
                    } : null,
                  ),
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, child) {
                      final isPlaying = _controller.player.state.playing;
                      return IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () {
                          _controller.player.playOrPause();
                          _controller.startHideTimer();
                        },
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResponsiveVideoPlayerPage(
                            videoUrl: '',
                            subjectId: widget.subjectId,
                            detailPath: widget.detailPath,
                            season: widget.season,
                            episode: widget.episode + 1,
                            title: widget.title,
                            posterUrl: widget.posterUrl,
                            availableQualities: widget.availableQualities,
                            recommendations: widget.recommendations,
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
                  PipButton(
                    onTap: _controller.startHideTimer,
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white, size: 24),
                    onPressed: _openFullscreen,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        widget.title ?? 'Video',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRatingAndGenres() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFFFC107), size: 20),
          const SizedBox(width: 4),
          const Text(
            '8.5',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Action, Drama, Thriller',
            style: TextStyle(
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      height: 48,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _buildPillButton(Icons.share, 'Share'),
          const SizedBox(width: 12),
          _buildPillButton(Icons.chat_bubble_outline, 'Feedback'),
          const SizedBox(width: 12),
          _buildPillButton(Icons.file_download, 'Download'),
          const SizedBox(width: 12),
          _buildPillButton(Icons.folder_open, 'View Downloads'),
        ],
      ),
    );
  }

  Widget _buildPillButton(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "If current season is not working, try a different one.",
            style: TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Seasons : ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final isSelected = index == widget.season - 1;
                      return GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF2D75).withOpacity(0.2)
                                : const Color(0xFF141414),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF2D75)
                                  : Colors.grey.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            'Season ${index + 1}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'You May Also Like',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.5,
            ),
            itemCount: widget.recommendations.length,
            itemBuilder: (context, index) {
              final rec = widget.recommendations[index];
              return _buildMovieCard(
                rec['imageUrl'] ?? '',
                rec['rating'] ?? 0.0,
                rec['title'] ?? '',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovieCard(String imageUrl, double rating, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.broken_image, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFC107), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
