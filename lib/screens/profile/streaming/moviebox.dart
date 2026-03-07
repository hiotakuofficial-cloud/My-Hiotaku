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
                      return Container(color: Colors.grey[900]);
                    },
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
                child: Container(
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                    const Color(0xFF121212).withOpacity(1.0),
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                  stops: const [0.6, 1.0],
                  center: Alignment.center,
                  radius: 0.9,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      year,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, size: 16, color: Color(0xFFFF3B5C)),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.play_arrow,
                          color: Color(0xFFFF3B5C), size: 24),
                      label: const Text(
                        'Play',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      children: [
                        OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.transparent),
                            shape: const CircleBorder(),
                            backgroundColor: Colors.white.withOpacity(0.15),
                            padding: const EdgeInsets.all(12),
                          ),
                          child: const Icon(Icons.info_outline,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Info',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
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
        const Text(
          'Trending Now',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final movie = movies[index];
              final cover = movie['cover'] ?? {};
              final imageUrl = cover['url'] ?? '';
              final title = movie['title'] ?? '';

              return _MovieCard(
                imageUrl: imageUrl,
                title: title,
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
  final VoidCallback onTap;

  const _MovieCard({
    required this.imageUrl,
    required this.title,
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
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
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
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.grey[900]);
                        },
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            stops: const [0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white.withOpacity(0.8),
                        size: 48.0,
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
