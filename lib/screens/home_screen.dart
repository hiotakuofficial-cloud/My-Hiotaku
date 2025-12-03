import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'dart:async';
import '../services/api_service.dart';
import '../models/api_models.dart';
import 'pages/popular.dart';
import 'pages/upcoming.dart';
import 'pages/anime_movies.dart';
import 'pages/hindi_dubbed.dart';
import 'pages/recently_added.dart';
import 'pages/continue_watching.dart';
import 'auth/login.dart';
import 'errors/no_internet.dart';
import 'errors/loading_error.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentPage = 0;
  List<AnimeItem> featuredAnime = [];
  List<AnimeItem> trendingAnime = [];
  List<AnimeItem> popularAnime = [];
  List<AnimeItem> topMovies = [];
  List<AnimeItem> recentlyUpdated = [];
  List<AnimeItem> hindiAnime = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHomeData();
    _startAutoSlide();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _stopAutoSlide();
        break;
      case AppLifecycleState.resumed:
        _startAutoSlide();
        break;
      default:
        break;
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (featuredAnime.isNotEmpty && mounted) {
        int nextPage = (_currentPage + 1) % featuredAnime.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
  }

  void _restartAutoSlide() {
    _stopAutoSlide();
    _startAutoSlide();
  }

  Future<void> _loadHomeData() async {
    try {
      setState(() => isLoading = true);
      
      // Load different sections with real API calls
      final homeData = await ApiService.getHome();
      final popularData = await ApiService.getPopular(1);
      final moviesData = await ApiService.getMovies(1);
      final topUpcomingData = await ApiService.getTopUpcoming(1);
      final subbedData = await ApiService.getSubbed(1);
      final hindiData = await ApiService.getHindiAnime(1);
      
      setState(() {
        // Use real API data for each section - 6 featured items
        featuredAnime = homeData.data.take(6).toList();
        trendingAnime = popularData.data.take(10).toList();
        popularAnime = topUpcomingData.data.take(10).toList();
        topMovies = moviesData.data.take(10).toList();
        recentlyUpdated = subbedData.data.take(10).toList();
        hindiAnime = hindiData.data.take(10).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      
      // Navigate to appropriate error page
      if (mounted) {
        String errorType = e.toString().toLowerCase();
        
        if (errorType.contains('network') || 
            errorType.contains('connection') || 
            errorType.contains('timeout')) {
          // Network related error
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoInternetScreen(
                onRetry: () {
                  Navigator.pop(context);
                  _loadHomeData();
                },
              ),
            ),
          );
        } else {
          // API or data loading error
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LoadingErrorScreen(
                errorMessage: 'Failed to load anime data.\nPlease try again.',
                onRetry: () {
                  Navigator.pop(context);
                  _loadHomeData();
                },
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        extendBodyBehindAppBar: true,
        body: isLoading ? _buildLoading() : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Lottie.asset(
        'assets/animations/loading.json',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        _buildHeader(),
        _buildFeaturedCarousel(),
        _buildSectionTitle('Continue Watching', () => _navigateToSeeAll('continue')),
        _buildHorizontalList(featuredAnime.take(5).toList()), // Show some as continue watching
        _buildSectionTitle('Popular Now', () => _navigateToSeeAll('popular')),
        _buildHorizontalList(trendingAnime),
        _buildSectionTitle('Top Upcoming', () => _navigateToSeeAll('upcoming')),
        _buildHorizontalList(popularAnime),
        _buildSectionTitle('Anime Movies', () => _navigateToSeeAll('movies')),
        _buildHorizontalList(topMovies),
        _buildSectionTitle('Hindi Dubbed', () => _navigateToSeeAll('hindi')),
        _buildHorizontalList(hindiAnime),
        _buildSectionTitle('Recently Added', () => _navigateToSeeAll('recent')),
        _buildHorizontalList(recentlyUpdated),
        SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 16),
        child: Row(
          children: [
            // HIOTAKU Logo - bigger size
            Container(
              height: 45,
              child: Image.asset(
                'assets/images/header_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            Spacer(),
            // Profile Section - slightly left from original position
            Padding(
              padding: EdgeInsets.only(right: 8), // Move slightly left
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Navigate to login screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                },
                child: Container(
                  width: 24,
                  height: 24,
                  child: Image.asset(
                    'assets/images/login.png',
                    color: Colors.white,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    return SliverToBoxAdapter(
      child: Container(
        height: 300, // Reduced from 400 to 300
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                physics: BouncingScrollPhysics(),
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  _restartAutoSlide(); // Restart timer when user manually swipes
                },
                itemCount: featuredAnime.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _stopAutoSlide();
                      // TODO: Navigate to anime details
                      Future.delayed(Duration(seconds: 2), () {
                        _startAutoSlide();
                      });
                    },
                    child: _buildFeaturedCard(featuredAnime[index]),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            _buildPageIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(AnimeItem anime) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              anime.poster ?? '',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[800],
                  child: Icon(Icons.image, color: Colors.white54, size: 64),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    anime.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (anime.type != null) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        anime.type!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        featuredAnime.length,
        (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index 
                ? Colors.blue 
                : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback? onSeeAll) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 30, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'See All',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.blue,
                        size: 12,
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

  Widget _buildHorizontalList(List<AnimeItem> animeList) {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        child: ListView.builder(
          physics: BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 20),
          itemCount: animeList.length,
          itemBuilder: (context, index) {
            return _buildAnimeCard(animeList[index]);
          },
        ),
      ),
    );
  }

  Widget _buildAnimeCard(AnimeItem anime) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // TODO: Navigate to anime details
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.elasticOut,
        width: 140,
        margin: EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'anime_${anime.id}',
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      anime.poster ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[800],
                          child: Icon(Icons.image, color: Colors.white54),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              anime.title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSeeAll(String section) {
    HapticFeedback.lightImpact();
    
    Widget targetPage;
    switch (section) {
      case 'popular':
        targetPage = PopularPage();
        break;
      case 'upcoming':
        targetPage = UpcomingPage();
        break;
      case 'movies':
        targetPage = AnimeMoviesPage();
        break;
      case 'hindi':
        targetPage = HindiDubbedPage();
        break;
      case 'recent':
        targetPage = RecentlyAddedPage();
        break;
      case 'continue':
        targetPage = ContinueWatchingPage();
        break;
      default:
        // Show snackbar for unimplemented sections
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$section - Coming Soon!'),
            backgroundColor: Colors.blue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
    }

    // iOS-style smooth transition
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetPage,
        transitionDuration: Duration(milliseconds: 400),
        reverseTransitionDuration: Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // iOS-style slide transition
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}
