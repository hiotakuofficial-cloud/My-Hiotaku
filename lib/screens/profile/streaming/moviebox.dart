import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/moviebox_service.dart';

class MovieBoxHome extends StatefulWidget {
  const MovieBoxHome({Key? key}) : super(key: key);

  @override
  State<MovieBoxHome> createState() => _MovieBoxHomeState();
}

class _MovieBoxHomeState extends State<MovieBoxHome> with TickerProviderStateMixin {
  late AnimationController _heroZoomController;
  late Animation<double> _heroZoomAnimation;
  late PageController _pageController;
  Timer? _autoScrollTimer;
  
  bool _isLoading = true;
  Map<String, dynamic>? _homeData;
  Map<String, dynamic>? _trendingData;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _heroZoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    _heroZoomAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _heroZoomController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  void _startAutoScroll(int itemCount) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients && itemCount > 0) {
        final nextPage = (_currentPage + 1) % itemCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _heroZoomController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final home = await MovieBoxService.getHome();
      final trending = await MovieBoxService.getTrending(perPage: 20);
      
      setState(() {
        _homeData = home;
        _trendingData = trending;
        _isLoading = false;
      });
      
      final trendingList = trending['data']?['subjectList'] as List? ?? [];
      if (trendingList.length > 1) {
        _startAutoScroll(trendingList.take(5).length);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 10.0),
          child: Icon(Icons.movie, color: Colors.white, size: 30),
        ),
        title: const Text(
          'MovieBox',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B5C)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFFF3B5C)),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B5C)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFFF3B5C),
                  onRefresh: _loadData,
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildContent() {
    final trendingList = _trendingData?['data']?['subjectList'] as List? ?? [];
    final heroMovies = trendingList.take(5).toList();

    return Container(
      color: const Color(0xFF121212),
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (heroMovies.isNotEmpty) _buildHeroCarousel(heroMovies),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildTrendingSection(trendingList),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCarousel(List<dynamic> movies) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.60;

    return SizedBox(
      height: heroHeight,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        itemCount: movies.length,
        itemBuilder: (context, index) {
          return _buildHeroSection(movies[index]);
        },
      ),
    );
  }

  Widget _buildHeroSection(Map<String, dynamic> movie) {
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeight = screenHeight * 0.60;
    final cover = movie['cover'] ?? {};
    final imageUrl = cover['url'] ?? '';
    final title = movie['title'] ?? '';
    final year = movie['releaseDate']?.toString().split('-')[0] ?? '';
    final rating = movie['imdbRatingValue'] ?? '0.0';

    return SizedBox(
      height: heroHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background image with zoom
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _heroZoomAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _heroZoomAnimation.value,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1a1a1a), Color(0xFF121212)],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          // Strong blur overlay
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.7),
                        const Color(0xFF121212),
                      ],
                      stops: const [0.0, 0.3, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Side vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                  stops: const [0.5, 1.0],
                  center: Alignment.center,
                  radius: 1.2,
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                // Meta info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        year,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B5C).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Color(0xFFFF3B5C)),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B5C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        elevation: 8,
                        shadowColor: const Color(0xFFFF3B5C).withOpacity(0.5),
                      ),
                      icon: const Icon(Icons.play_arrow, size: 24),
                      label: const Text(
                        'Play Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                      icon: const Icon(Icons.info_outline, color: Colors.white, size: 22),
                      label: const Text(
                        'Info',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFFFF3B5C)
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection(List<dynamic> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B5C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Trending Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final movie = movies[index];
              final cover = movie['cover'] ?? {};
              final imageUrl = cover['url'] ?? '';
              final title = movie['title'] ?? '';
              final rating = movie['imdbRatingValue'] ?? '0.0';

              return _MovieCard(
                imageUrl: imageUrl,
                title: title,
                rating: rating,
                onTap: () {},
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MovieCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String rating;
  final VoidCallback onTap;

  const _MovieCard({
    required this.imageUrl,
    required this.title,
    required this.rating,
    required this.onTap,
  });

  @override
  State<_MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<_MovieCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 130,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    // Image
                    Positioned.fill(
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1a1a1a), Color(0xFF0a0a0a)],
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.movie, color: Colors.white30, size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                    // Gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Rating badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B5C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 10, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              widget.rating,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Play icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
