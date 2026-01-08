import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'dart:async';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';
import '../models/api_models.dart';
import 'profile/handler/profile_handler.dart';
import 'details/details.dart';
import 'pages/popular.dart';
import 'pages/upcoming.dart';
import 'pages/anime_movies.dart';
import 'pages/hindi_dubbed.dart';
import 'pages/recently_added.dart';
import 'auth/login.dart';
import 'errors/no_internet.dart';
import 'errors/loading_error.dart';
import 'settings/settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notifications/handler/firebase_messaging_handler.dart';
import '../services/websocket_service.dart';

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
  
  // Cache timestamp to avoid frequent API calls
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  // User authentication state
  Map<String, dynamic>? userData;
  String avatarUrl = 'assets/profile/default/default.png';
  bool isUserLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Load home data and user data in parallel
    Future.wait([
      _loadHomeData(),
      _loadUserData(),
    ]);
    
    _startAutoSlide();
    _initializeFCMIfLoggedIn();
    _initializeWebSocketIfLoggedIn();
  }

  // Initialize WebSocket for logged in users (optimized)
  void _initializeWebSocketIfLoggedIn() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await WebSocketService.initialize();
      
      // Set user online status
      await WebSocketService.setOnlineStatus(true);
    }
  }

  // Initialize FCM only if user is logged in
  void _initializeFCMIfLoggedIn() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser != null) {
        await FirebaseMessagingHandler.initialize();
      } else {
      }
    } catch (e) {
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for online/offline status
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null && WebSocketService.isReady) {
      switch (state) {
        case AppLifecycleState.resumed:
          // App came to foreground
          WebSocketService.setOnlineOnForeground();
          _startAutoSlide();
          _loadUserData(); // Reload user data when app resumes
          break;
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          // App went to background
          WebSocketService.setOfflineOnBackground();
          _stopAutoSlide();
          break;
        default:
          break;
      }
    } else {
      // Original behavior for non-logged in users
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          _stopAutoSlide();
          break;
        case AppLifecycleState.resumed:
          _startAutoSlide();
          _loadUserData(); // Reload user data when app resumes
          break;
        default:
          break;
      }
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

  int _retryCount = 0;
  static const int _maxRetries = 3;

  Future<void> _loadUserData() async {
    try {
      final data = await ProfileHandler.getCurrentUserData();
      
      if (mounted) {
        setState(() {
          userData = data;
          isUserLoading = false;
          
          if (data != null) {
            String? avatarId = data['avatar_url'];
            
            if (avatarId != null && avatarId.isNotEmpty && !avatarId.startsWith('http')) {
              // Construct avatar path based on filename
              if (avatarId.startsWith('male')) {
                avatarUrl = 'assets/profile/male/$avatarId';
              } else if (avatarId.startsWith('female')) {
                avatarUrl = 'assets/profile/female/$avatarId';
              } else if (avatarId == 'default.png') {
                avatarUrl = 'assets/profile/default/default.png';
              } else {
                avatarUrl = 'assets/profile/default/default.png';
              }
            } else {
              // Network URL or fallback
              avatarUrl = avatarId ?? 'assets/profile/default/default.png';
            }
          } else {
            avatarUrl = 'assets/profile/default/default.png';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userData = null;
          isUserLoading = false;
          avatarUrl = 'assets/profile/default/default.png';
        });
      }
    }
  }

  Future<void> _loadHomeData() async {
    // Check cache first
    if (_lastLoadTime != null && 
        DateTime.now().difference(_lastLoadTime!) < _cacheExpiry &&
        featuredAnime.isNotEmpty) {
      return; // Use cached data
    }
    
    try {
      setState(() => isLoading = true);
      
      // Load all sections in parallel for faster loading
      final results = await Future.wait([
        ApiService.getHome(),
        ApiService.getPopular(1),
        ApiService.getMovies(1),
        ApiService.getTopUpcoming(1),
        ApiService.getSubbed(1),
        ApiService.getHindiAnime(1),
      ]);
      
      setState(() {
        // Use parallel API results - 6 featured items
        featuredAnime = results[0].data.isNotEmpty ? results[0].data.take(6).toList() : [];
        trendingAnime = results[1].data.isNotEmpty ? results[1].data.take(10).toList() : [];
        topMovies = results[2].data.isNotEmpty ? results[2].data.take(10).toList() : [];
        popularAnime = results[3].data.isNotEmpty ? results[3].data.take(10).toList() : [];
        recentlyUpdated = results[4].data.isNotEmpty ? results[4].data.take(10).toList() : [];
        hindiAnime = results[5].data.isNotEmpty ? results[5].data.take(10).toList() : [];
        isLoading = false;
        _retryCount = 0; // Reset retry count on success
        _lastLoadTime = DateTime.now(); // Update cache timestamp
      });
    } catch (e) {
      // Silent retry mechanism
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(seconds: 2));
        _loadHomeData();
        return;
      }
      
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
            // Profile/Login Section
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (userData == null) {
                    // User not logged in - navigate to login
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(),
                      ),
                    );
                  } else {
                    // User logged in - navigate to settings
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  child: isUserLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        )
                      : userData == null
                          ? Container(
                              width: 3,
                              height: 3,
                              child: Image.asset(
                                'assets/images/login.png',
                                color: Colors.white,
                                fit: BoxFit.contain,
                              ),
                            )
                          : ClipOval(
                              child: _buildUserAvatar(),
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
        child: featuredAnime.isEmpty 
          ? _buildFeaturedEmptyState()
          : Column(
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnimeDetailsPage(
                                title: featuredAnime[index].title,
                                poster: featuredAnime[index].poster ?? '',
                                description: featuredAnime[index].description ?? 'No description available.',
                                genres: (featuredAnime[index].type?.isNotEmpty ?? false) ? [featuredAnime[index].type!] : ['Unknown'],
                                rating: 0.0,
                                year: 'Unknown',
                                animeId: featuredAnime[index].id,
                                animeType: featuredAnime[index].type ?? 'Unknown',
                              ),
                            ),
                          ).then((_) {
                            Future.delayed(Duration(seconds: 2), () {
                              _startAutoSlide();
                            });
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

  Widget _buildFeaturedEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/fallback/notfound.png',
            width: 100,
            height: 100,
            color: Colors.grey[600],
          ),
          SizedBox(height: 16),
          Text(
            'No featured content available',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              _retryCount = 0;
              _loadHomeData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: Text(
              'Retry',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
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
                return Image.asset(
                  'assets/fallback/notfound.png',
                  fit: BoxFit.cover,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF8C00),
                      strokeWidth: 2,
                    ),
                  ),
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
        child: animeList.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
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

  Widget _buildUserAvatar() {
    // Try to load from assets first
    if (avatarUrl.startsWith('assets/')) {
      return Image.asset(
        avatarUrl,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAvatar();
        },
      );
    }
    
    // Try to load from network (Firebase photo URL)
    if (avatarUrl.startsWith('http')) {
      return Image.network(
        avatarUrl,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 32,
            height: 32,
            color: Colors.grey[800],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF8C00),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAvatar();
        },
      );
    }
    
    // Fallback to default avatar
    return _buildFallbackAvatar();
  }
  
  Widget _buildFallbackAvatar() {
    String displayName = userData?['display_name'] ?? 'Hiotaku User';
    String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H';
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Color(0xFFFF8C00),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/fallback/notfound.png',
            width: 80,
            height: 80,
            color: Colors.grey[600],
          ),
          SizedBox(height: 12),
          Text(
            'No content available',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _retryCount = 0;
              _loadHomeData();
            },
            child: Text(
              'Retry',
              style: TextStyle(
                color: Color(0xFFFF8C00),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(AnimeItem anime) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailsPage(
              title: anime.title,
              poster: anime.poster ?? '',
              description: anime.description ?? 'No description available.',
              genres: (anime.type?.isNotEmpty ?? false) ? [anime.type!] : ['Unknown'],
              rating: 0.0, // Will be fetched by handler
              year: 'Unknown', // Will be fetched by handler
              animeId: anime.id,
              animeType: anime.type ?? 'Unknown',
            ),
          ),
        );
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
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/fallback/notfound.png',
                          fit: BoxFit.cover,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[800],
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFFF8C00),
                              strokeWidth: 1.5,
                            ),
                          ),
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
