import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/moviebox_service.dart';
import 'player/play.dart';
import 'components/lang_preference.dart';

class MovieBoxDetail extends StatefulWidget {
  final String subjectId;
  final String? detailPath;

  const MovieBoxDetail({
    Key? key,
    required this.subjectId,
    this.detailPath,
  }) : super(key: key);

  @override
  State<MovieBoxDetail> createState() => _MovieBoxDetailState();
}

class _MovieBoxDetailState extends State<MovieBoxDetail> {
  Map<String, dynamic>? _detailData;
  List<dynamic> _recommendations = [];
  bool _isLoading = true;
  bool _isLoadingVideo = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await MovieBoxService.getDetail(
        id: widget.subjectId,
        path: widget.detailPath,
      );
      
      final recs = await MovieBoxService.getRecommendations(id: widget.subjectId);
      
      setState(() {
        _detailData = detail;
        _recommendations = recs['data']?['items'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _detailData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Shimmer.fromColors(
          baseColor: const Color(0xFF1C1C27),
          highlightColor: const Color(0xFF13131A),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 400,
                pinned: false,
                backgroundColor: const Color(0xFF121212),
                flexibleSpace: Container(color: const Color(0xFF1C1C27)),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 200, height: 24, color: const Color(0xFF1C1C27)),
                      const SizedBox(height: 12),
                      Container(width: 150, height: 20, color: const Color(0xFF1C1C27)),
                      const SizedBox(height: 16),
                      Row(
                        children: List.generate(3, (_) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(width: 80, height: 32, decoration: BoxDecoration(color: const Color(0xFF1C1C27), borderRadius: BorderRadius.circular(16))),
                        )),
                      ),
                      const SizedBox(height: 24),
                      Container(width: double.infinity, height: 100, color: const Color(0xFF1C1C27)),
                      const SizedBox(height: 24),
                      Container(width: 150, height: 20, color: const Color(0xFF1C1C27)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 216,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          separatorBuilder: (_, __) => const SizedBox(width: 16),
                          itemBuilder: (_, __) => Container(width: 120, decoration: BoxDecoration(color: const Color(0xFF1C1C27), borderRadius: BorderRadius.circular(16))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_detailData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.white54),
                const SizedBox(height: 16),
                const Text('Failed to load details', style: TextStyle(color: Colors.white54, fontFamily: 'MazzardH')),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadDetail,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B5C)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final subject = (_detailData?['data']?['subject'] ?? {}) as Map<String, dynamic>;
    final cover = subject['cover'] ?? {};
    final stills = subject['stills'] ?? {};
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: false,
            backgroundColor: const Color(0xFF121212),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 28),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  _buildHeroBanner(stills['url']?.toString() ?? cover['url']?.toString() ?? ''),
                  Positioned(
                    bottom: 20,
                    left: 16,
                    child: _buildPosterCard(cover['url']?.toString() ?? ''),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildTitle(subject),
                  const SizedBox(height: 12),
                  _buildRating(subject),
                  const SizedBox(height: 16),
                  _buildMetadata(subject),
                  const SizedBox(height: 16),
                  _buildGenres(subject),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildOverview(subject),
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

  Widget _buildHeroBanner(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(color: const Color(0xFF1a1a1a));
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF1a1a1a),
              child: const Icon(Icons.movie, color: Colors.white24, size: 64),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                const Color(0xFF121212),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPosterCard(String imageUrl) {
    return Container(
      width: 120,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1a1a1a),
                  child: const Icon(Icons.movie, color: Colors.white24, size: 48),
                ),
              )
            : Container(
                color: const Color(0xFF1a1a1a),
                child: const Icon(Icons.movie, color: Colors.white24, size: 48),
              ),
      ),
    );
  }

  Widget _buildTitle(Map<String, dynamic> subject) {
    return Text(
      subject['title']?.toString() ?? 'Unknown Title',
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'MazzardH',
      ),
    );
  }

  Widget _buildRating(Map<String, dynamic> subject) {
    final rating = subject['imdbRatingValue']?.toString() ?? '0.0';
    final votes = int.tryParse(subject['imdbRatingCount']?.toString() ?? '0') ?? 0;
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFC107),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: Colors.black, size: 18),
              const SizedBox(width: 4),
              Text(
                rating,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MazzardH',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${votes > 0 ? "${(votes / 1000).toStringAsFixed(0)}K votes" : "No votes"}',
          style: const TextStyle(color: Color(0xFFB0B0B0), fontFamily: 'MazzardH'),
        ),
      ],
    );
  }

  Widget _buildMetadata(Map<String, dynamic> subject) {
    final releaseDate = subject['releaseDate']?.toString() ?? '';
    final year = releaseDate.isNotEmpty ? releaseDate.split('-')[0] : 'N/A';
    final country = subject['countryName']?.toString() ?? 'Unknown';
    
    return Row(
      children: [
        _buildMetadataItem(Icons.movie, 'MOVIE'),
        const SizedBox(width: 24),
        _buildMetadataItem(Icons.calendar_today, year),
        const SizedBox(width: 24),
        _buildMetadataItem(Icons.location_on, country),
      ],
    );
  }

  Widget _buildMetadataItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFB0B0B0), size: 18),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Color(0xFFB0B0B0), fontFamily: 'MazzardH'),
        ),
      ],
    );
  }

  Widget _buildGenres(Map<String, dynamic> subject) {
    final genreString = subject['genre']?.toString() ?? '';
    final genres = genreString.isNotEmpty 
        ? genreString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    
    // Get subject type (1 = Movie, 2 = Series)
    final subjectType = subject['subjectType'] ?? 2;
    final typeLabel = subjectType == 1 ? 'Movie' : 'Series';
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Type badge (Movie/Series)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE5003C),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            typeLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'MazzardH',
            ),
          ),
        ),
        // Genre badges
        ...genres.map((genre) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFB0B0B0).withOpacity(0.3)),
          ),
          child: Text(
            genre,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'MazzardH'),
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildActionButtons() {
    final subject = _detailData?['data']?['subject'];
    final title = subject?['title'] ?? '';
    final rating = double.tryParse(subject?['imdbRatingValue']?.toString() ?? '0') ?? 0.0;
    final genres = (subject?['genre']?.toString() ?? '').split(',');
    final posterUrl = subject?['cover']?['url'] ?? '';
    final subjectType = subject?['subjectType'] ?? 2; // 1 = Movie, 2 = Series

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoadingVideo ? null : () async {
              if (_isLoadingVideo) return;
              
              setState(() => _isLoadingVideo = true);
              
              try {
                // For movies: season=0, episode=0; For series: season=1, episode=1
                final season = subjectType == 1 ? 0 : 1;
                final episode = subjectType == 1 ? 0 : 1;
                
                // Get detailPath from loaded data
                final detailPath = subject?['detailPath'] ?? widget.detailPath ?? '';
                
                // Get available languages and select best one
                final dubs = subject?['dubs'] as List? ?? [];
                final availableLanguages = dubs.cast<Map<String, dynamic>>();
                final selectedLang = await LanguagePreference.selectLanguageWithHistory(
                  availableLanguages: availableLanguages,
                );
                
                final playData = await MovieBoxService.getPlayUrls(
                  id: widget.subjectId,
                  path: detailPath,
                  season: season,
                  episode: episode,
                );
                
                final streams = playData['data']?['streams'] as List? ?? [];
                if (streams.isEmpty) {
                  if (mounted) {
                    setState(() => _isLoadingVideo = false);
                    Fluttertoast.showToast(msg: 'No video available');
                  }
                  return;
                }
                
                // Get saved quality preference or use minimum (360p)
                final prefs = await SharedPreferences.getInstance();
                final savedQuality = prefs.getString('preferred_quality') ?? '360';

                final stream = streams.firstWhere(
                  (s) => s['resolutions'] == savedQuality,
                  orElse: () => streams.first,
                );
                
                final videoUrl = stream['url'] as String? ?? '';
                final availableQualities = streams
                    .map((s) => '${s['resolutions']}p')
                    .toList()
                    .cast<String>();
                
                if (!mounted) return;
                
                setState(() => _isLoadingVideo = false);
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayPage(
                      videoUrl: videoUrl,
                      subjectId: widget.subjectId,
                      detailPath: widget.detailPath ?? '',
                      season: season,
                      episode: episode,
                      title: title,
                      posterUrl: posterUrl,
                      availableQualities: availableQualities,
                      recommendations: const [],
                      subjectType: subjectType,
                      rating: rating,
                      genres: genres.join(', '),
                      initialLanguage: selectedLang,
                    ),
                  ),
                );
              } catch (e) {
                if (mounted) {
                  setState(() => _isLoadingVideo = false);
                  Fluttertoast.showToast(msg: 'Failed to load video');
                }
              }
            },
            icon: _isLoadingVideo 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.play_arrow),
            label: _isLoadingVideo ? const SizedBox.shrink() : const Text('Watch Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B5C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'MazzardH'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: null, // Disabled
            icon: const Icon(Icons.live_tv),
            label: const Text('Stream Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1a1a1a),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: const Color(0xFFB0B0B0).withOpacity(0.3)),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'MazzardH'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverview(Map<String, dynamic> subject) {
    final description = subject['description']?.toString() ?? 'No description available.';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'MazzardH',
          ),
        ),
        const SizedBox(height: 12),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0.0, 0.9, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: Text(
            description,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 15,
              height: 1.5,
              fontFamily: 'MazzardH',
            ),
            maxLines: 8,
            overflow: TextOverflow.fade,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations() {
    if (_recommendations.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You May Also Like',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'MazzardH',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 216,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: _recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final rec = _recommendations[index] ?? {};
              final cover = rec['cover'] ?? {};
              final imageUrl = cover['url']?.toString() ?? '';
              
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieBoxDetail(
                        subjectId: rec['subjectId']?.toString() ?? '',
                        detailPath: rec['detailPath']?.toString(),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFF1a1a1a),
                              child: const Icon(Icons.movie, color: Colors.white24, size: 48),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1a1a1a),
                            child: const Icon(Icons.movie, color: Colors.white24, size: 48),
                        ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
