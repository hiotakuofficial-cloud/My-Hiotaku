import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../../services/moviebox_service.dart';
import 'controller/video_player_controller.dart';
import 'controller/recommendation_controller.dart';
import 'controller/action_button_controller.dart';
import 'controller/season_episode_controller.dart';
import 'widgets/seekbar.dart';
import 'widgets/subtitle_selector.dart';
import 'widgets/audio_track_selector.dart';
import 'widgets/brightness_gesture.dart';
import 'widgets/volume_gesture.dart';
import 'widgets/quality_selector.dart';
import 'widgets/pip_button.dart';
import 'widgets/custom_buffering_loader.dart';
import 'widgets/season_episode_selector.dart';

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
  final int subjectType; // 1 = Movie, 2 = Series
  final double rating; // IMDb rating
  final String genres; // Comma-separated genres

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
    this.subjectType = 2, // Default to Series
    this.rating = 0.0,
    this.genres = '',
  }) : super(key: key);

  @override
  State<ResponsiveVideoPlayerPage> createState() => _ResponsiveVideoPlayerPageState();
}

class _ResponsiveVideoPlayerPageState extends State<ResponsiveVideoPlayerPage> {
  late VideoPlayerController _controller;
  late RecommendationController _recommendationController;
  late SeasonEpisodeController _seasonEpisodeController;
  bool _isFullscreen = false;
  bool _isLoadingEpisode = false;

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
    
    // Load recommendations in background
    _recommendationController = RecommendationController();
    _recommendationController.loadRecommendations(widget.subjectId);
    
    // Load seasons in background
    _seasonEpisodeController = SeasonEpisodeController();
    _seasonEpisodeController.loadSeasons(widget.subjectId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _recommendationController.dispose();
    _seasonEpisodeController.dispose();
    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
    super.dispose();
  }

  Future<void> _loadEpisode(int season, int episode) async {
    if (_isLoadingEpisode) return;
    
    setState(() => _isLoadingEpisode = true);
    
    try {
      final playData = await MovieBoxService.getPlayUrls(
        id: widget.subjectId,
        path: widget.detailPath,
        season: season,
        episode: episode,
      );

      final streams = playData['data']?['streams'] as List? ?? [];
      if (streams.isEmpty) {
        if (mounted) setState(() => _isLoadingEpisode = false);
        Fluttertoast.showToast(msg: 'No video available');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final savedQuality = prefs.getString('preferred_quality') ?? '720';

      final stream = streams.firstWhere(
        (s) => s['resolutions'] == savedQuality,
        orElse: () => streams.first,
      );

      final videoUrl = stream['url'] as String? ?? '';
      if (videoUrl.isNotEmpty && mounted) {
        // Update video URL in controller
        await _controller.changeVideoUrl(videoUrl, season, episode);
        setState(() => _isLoadingEpisode = false);
      }
    } catch (e) {
      debugPrint('Load episode error: $e');
      if (mounted) {
        setState(() => _isLoadingEpisode = false);
        Fluttertoast.showToast(msg: 'Failed to load episode');
      }
    }
  }

  void _toggleFullscreen() async {
    setState(() => _isFullscreen = !_isFullscreen);
    if (_isFullscreen) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await Future.delayed(const Duration(milliseconds: 100));
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersive,
        overlays: [],
      );
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      extendBodyBehindAppBar: true,
      appBar: _isFullscreen ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      body: _isFullscreen ? _buildFullscreenPlayer() : _buildResponsiveLayout(),
    );
  }

  Widget _buildFullscreenPlayer() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            Center(
              child: Video(
                controller: _controller.videoController,
                controls: NoVideoControls,
              ),
            ),
            // Tap to toggle controls
            Positioned.fill(
              child: GestureDetector(
                onTap: _controller.toggleControls,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            // Gestures only in fullscreen when controls hidden
            if (!_controller.showControls)
              BrightnessGesture(showControls: _controller.showControls),
            if (!_controller.showControls)
              VolumeGesture(showControls: _controller.showControls),
            Center(child: BufferingLoader(isVisible: _controller.isBuffering)),
            // Controls with fade animation
            AnimatedOpacity(
              opacity: _controller.showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_controller.showControls,
                child: _buildControls(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResponsiveLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top), // Status bar spacing
        _buildVideoPlayer(),
        const SizedBox(height: 16),
        _buildActionButtons(), // Fixed below video
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildTitle(),
                const SizedBox(height: 12),
                _buildRatingAndGenres(),
                const SizedBox(height: 24),
                // Only show season selection for series
                if (widget.subjectType == 2) ...[
                  _buildSeasonSelection(),
                  const SizedBox(height: 16),
                  _buildEpisodesSection(),
                  const SizedBox(height: 24),
                ],
                _buildRecommendations(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
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
                // No gestures in responsive mode
                Center(child: BufferingLoader(isVisible: _controller.isBuffering)),
                // Controls with fade animation
                AnimatedOpacity(
                  opacity: _controller.showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_controller.showControls,
                    child: _buildControls(),
                  ),
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
                      color: widget.subjectType == 1 ? Colors.grey.withOpacity(0.3) : (widget.episode > 1 ? Colors.white : Colors.grey),
                      size: 24,
                    ),
                    onPressed: widget.subjectType == 1 ? null : (widget.episode > 1 ? () {
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
                            subjectType: widget.subjectType,
                          ),
                        ),
                      );
                    } : null),
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
                    icon: Icon(
                      Icons.skip_next,
                      color: widget.subjectType == 1 ? Colors.grey.withOpacity(0.3) : Colors.white,
                      size: 24,
                    ),
                    onPressed: widget.subjectType == 1 ? null : () {
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
                            subjectType: widget.subjectType,
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
                    icon: Image.asset(
                      'assets/player/fullscreen.png',
                      width: 20,
                      height: 20,
                      color: _isFullscreen ? const Color(0xFFE5003C) : Colors.white,
                      errorBuilder: (_, __, ___) => Icon(
                        _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                        color: _isFullscreen ? const Color(0xFFE5003C) : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: _toggleFullscreen,
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
    final typeLabel = widget.subjectType == 1 ? 'Movie' : 'Series';
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFFFC107), size: 20),
          const SizedBox(width: 4),
          Text(
            widget.rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '$typeLabel : ${widget.genres}',
              style: TextStyle(
                color: Colors.grey[400],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final typeLabel = widget.subjectType == 1 ? 'Movie' : 'Series';
    
    return SizedBox(
      height: 48,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _buildPillButton(Icons.share, 'Share', () {
            ActionButtonController.share(
              title: widget.title ?? 'Video',
              type: typeLabel,
            );
          }),
          const SizedBox(width: 12),
          _buildPillButton(Icons.chat_bubble_outline, 'Feedback', () {
            ActionButtonController.feedback();
          }),
          const SizedBox(width: 12),
          _buildPillButton(Icons.file_download, 'Download', () {
            ActionButtonController.download();
          }),
          const SizedBox(width: 12),
          _buildPillButton(Icons.folder_open, 'View Downloads', () {
            ActionButtonController.viewDownloads();
          }),
        ],
      ),
    );
  }

  Widget _buildPillButton(IconData icon, String label, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
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
            "If current video isn't playing, kindly check your WiFi.",
            style: TextStyle(
              color: Color(0xFFFFC107),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _seasonEpisodeController,
            builder: (context, _) {
              if (_seasonEpisodeController.isLoading) {
                return SizedBox(
                  height: 44,
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return Shimmer.fromColors(
                        baseColor: const Color(0xFF1E1E1E),
                        highlightColor: const Color(0xFF2A2A2A),
                        child: Container(
                          width: 90,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              final seasons = _seasonEpisodeController.seasons;
              if (seasons.isEmpty) return const SizedBox.shrink();

              return SizedBox(
                height: 44,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: seasons.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final seasonNum = seasons[index]['se'] as int;
                    final isSelected = seasonNum == widget.season;
                    return GestureDetector(
                      onTap: () {
                        if (seasonNum != widget.season) {
                          _loadEpisode(seasonNum, 1); // Load first episode of new season
                        }
                      },
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
                          'Season $seasonNum',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'MazzardH',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return ListenableBuilder(
      listenable: _recommendationController,
      builder: (context, _) {
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
              child: _recommendationController.isLoading
                  ? _buildShimmerGrid()
                  : _buildRecommendationGrid(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.5,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF1E1E1E),
          highlightColor: const Color(0xFF2A2A2A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 12,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecommendationGrid() {
    final recommendations = _recommendationController.recommendations;
    
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.5,
      ),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        final rec = recommendations[index];
        return _buildMovieCard(
          rec['imageUrl'] ?? '',
          rec['rating'] ?? 0.0,
          rec['title'] ?? '',
        );
      },
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
            fontFamily: 'MazzardH',
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Episodes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MazzardH',
                ),
              ),
              TextButton(
                onPressed: () {
                  Fluttertoast.showToast(msg: 'Show All clicked. Seasons: ${_seasonEpisodeController.seasons.length}, Loading: ${_seasonEpisodeController.isLoading}');
                  
                  if (_seasonEpisodeController.seasons.isNotEmpty) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => SeasonEpisodeSelector(
                        seasons: _seasonEpisodeController.seasons,
                        currentSeason: widget.season,
                        currentEpisode: widget.episode,
                        onSelect: (season, episode) {
                          _loadEpisode(season, episode);
                        },
                      ),
                    );
                  } else {
                    Fluttertoast.showToast(msg: 'Seasons not loaded yet or empty');
                  }
                },
                child: const Text(
                  'Show All',
                  style: TextStyle(
                    color: Color(0xFFDC143C),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'MazzardH',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: _seasonEpisodeController,
            builder: (context, _) {
              if (_seasonEpisodeController.isLoading) {
                return _buildEpisodesShimmer();
              }

              final episodes = _seasonEpisodeController.getEpisodesForSeason(widget.season);
              
              if (episodes.isEmpty) {
                return const SizedBox.shrink();
              }

              return SizedBox(
                height: 44,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: episodes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final episode = episodes[index];
                    final isActive = episode == widget.episode;
                    
                    return GestureDetector(
                      onTap: () {
                        if (episode != widget.episode) {
                          _loadEpisode(widget.season, episode);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFDC143C).withOpacity(0.2)
                              : const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFFDC143C)
                                : Colors.grey.withOpacity(0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'EP $episode',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'MazzardH',
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodesShimmer() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: const Color(0xFF1E1E1E),
            highlightColor: const Color(0xFF2A2A2A),
            child: Container(
              width: 70,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
