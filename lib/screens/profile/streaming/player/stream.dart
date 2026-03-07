import 'package:flutter/material.dart';
import 'components/options.dart';
import 'components/comment.dart';
import 'components/player.dart';
import 'handler/video_handler.dart';

const Color _bg = Color(0xFF0B0B0B);
const Color _surface = Color(0xFF141414);
const Color _white = Color(0xFFFFFFFF);
const Color _grey = Color(0xFFB0B0B0);
const Color _accent = Color(0xFFE5003C);
const Color _gold = Color(0xFFFFC107);
const Color _card = Color(0xFF1E1E1E);

class StreamPage extends StatefulWidget {
  final String subjectId;
  final String detailPath;
  final String title;
  final double rating;
  final List<String> genres;
  final String posterUrl;
  final int commentCount;
  final List<MovieCard> recommendations;

  const StreamPage({
    Key? key,
    required this.subjectId,
    required this.detailPath,
    required this.title,
    required this.rating,
    required this.genres,
    required this.posterUrl,
    this.commentCount = 0,
    this.recommendations = const [],
  }) : super(key: key);

  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  late VideoHandler _videoHandler;

  @override
  void initState() {
    super.initState();
    _videoHandler = VideoHandler(
      subjectId: widget.subjectId,
      detailPath: widget.detailPath,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    await _videoHandler.loadVideo();
    await _videoHandler.loadSeasons();
  }

  @override
  void dispose() {
    _videoHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _videoHandler,
        builder: (context, _) {
          if (_videoHandler.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _accent),
            );
          }

          if (_videoHandler.error != null) {
            return Center(
              child: Text(
                'Error: ${_videoHandler.error}',
                style: const TextStyle(color: _white, fontFamily: 'MazzardH'),
              ),
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Video Player Area
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.width * (9 / 16),
                flexibleSpace: FlexibleSpaceBar(
                  background: VideoPlayer(
                    videoUrl: _videoHandler.currentVideoUrl ?? '',
                    posterUrl: widget.posterUrl,
                  ),
                ),
                automaticallyImplyLeading: false,
                backgroundColor: _bg,
              ),

              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: _white,
                        fontFamily: 'MazzardH',
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rating & Genres
                    Row(
                      children: [
                        const Icon(Icons.star, color: _gold, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          widget.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: _white,
                            fontSize: 16,
                            fontFamily: 'MazzardH',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.genres.join(', '),
                            style: const TextStyle(
                              color: _grey,
                              fontSize: 16,
                              fontFamily: 'MazzardH',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Episode Info
                    if (_videoHandler.seasons.isNotEmpty)
                      Text(
                        'S${_videoHandler.currentSeason} E${_videoHandler.currentEpisode}',
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MazzardH',
                        ),
                      ),
                    if (_videoHandler.seasons.isNotEmpty) const SizedBox(height: 16),

                    // Action Buttons
                    PlayerOptions(
                      actions: [
                        ButtonData(
                          label: 'Share',
                          icon: Icons.share_outlined,
                          onPressed: () => _showSnack('Share'),
                        ),
                        ButtonData(
                          label: 'Feedback',
                          icon: Icons.feedback_outlined,
                          onPressed: () => _showSnack('Feedback'),
                        ),
                        ButtonData(
                          label: 'Download',
                          icon: Icons.download_outlined,
                          onPressed: () => _showSnack('Download'),
                        ),
                        ButtonData(
                          label: 'View Downloads',
                          icon: Icons.folder_open_outlined,
                          onPressed: () => _showSnack('View Downloads'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Quality Selection
                    if (_videoHandler.qualities.isNotEmpty) ...[
                      const Text(
                        'Quality',
                        style: TextStyle(
                          color: _white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MazzardH',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _videoHandler.qualities.map((quality) {
                            final isActive = quality == _videoHandler.selectedQuality;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _QualityChip(
                                label: quality.resolution,
                                size: quality.sizeInMB,
                                isActive: isActive,
                                onTap: () => _videoHandler.switchQuality(quality),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Episode Navigation
                    if (_videoHandler.seasons.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _videoHandler.previousEpisode,
                            icon: const Icon(Icons.skip_previous),
                            label: const Text('Previous'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _card,
                              foregroundColor: _white,
                              textStyle: const TextStyle(fontFamily: 'MazzardH'),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _videoHandler.nextEpisode,
                            icon: const Icon(Icons.skip_next),
                            label: const Text('Next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: _white,
                              textStyle: const TextStyle(fontFamily: 'MazzardH'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Comments Section
                    CommentSection(
                      onViewAll: () => _showSnack('View All Comments'),
                      onCommentSubmit: (comment) => _showSnack('Comment: $comment'),
                    ),
                    const SizedBox(height: 24),

                    // Recommendations
                    if (widget.recommendations.isNotEmpty) ...[
                      const Text(
                        'You May Also Like',
                        style: TextStyle(
                          color: _white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MazzardH',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: widget.recommendations.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => widget.recommendations[i],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _accent),
    );
  }
}

// Quality Selection Chip
class _QualityChip extends StatelessWidget {
  final String label;
  final String size;
  final bool isActive;
  final VoidCallback onTap;

  const _QualityChip({
    required this.label,
    required this.size,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _accent.withOpacity(0.2) : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _accent : _grey.withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: _accent.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${label}p',
              style: TextStyle(
                color: isActive ? _white : _grey,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                fontFamily: 'MazzardH',
              ),
            ),
            Text(
              size,
              style: TextStyle(
                color: isActive ? _white.withOpacity(0.7) : _grey.withOpacity(0.7),
                fontSize: 10,
                fontFamily: 'MazzardH',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Movie Card for Recommendations
class MovieCard extends StatelessWidget {
  final String imageUrl;
  final double rating;
  final String title;
  final VoidCallback? onTap;

  const MovieCard({
    Key? key,
    required this.imageUrl,
    required this.rating,
    required this.title,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double posterHeight = 160;
    const double posterWidth = posterHeight * (2 / 3);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: posterWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
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
                      height: posterHeight,
                      width: posterWidth,
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: _gold, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: _white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'MazzardH',
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
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: _white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'MazzardH',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
