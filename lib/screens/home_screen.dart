import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../services/supabase_auth_service.dart';
import '../models/api_models.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController _pageController = PageController();
  int _currentPage = 0;
  List<AnimeItem> featuredAnime = [];
  List<AnimeItem> trendingAnime = [];
  List<AnimeItem> popularAnime = [];
  bool isLoading = true;
  bool isUserLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    
    // Listen to auth state changes
    SupabaseAuthService.authStateChanges.listen((authState) {
      if (mounted) {
        setState(() {
          isUserLoggedIn = authState.session != null;
        });
      }
    });
  }

  Future<void> _loadHomeData() async {
    try {
      setState(() => isLoading = true);
      
      // Load home data (contains trending/popular anime)
      final homeData = await ApiService.getHome();
      
      setState(() {
        // Split home data into different sections
        final allAnime = homeData.data;
        featuredAnime = allAnime.take(5).toList();
        trendingAnime = allAnime.skip(5).take(10).toList();
        popularAnime = allAnime.skip(15).take(10).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading home data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: isLoading ? _buildLoading() : _buildContent(),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text('Loading...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        _buildHeader(),
        _buildFeaturedCarousel(),
        _buildSectionTitle('Trending'),
        _buildHorizontalList(trendingAnime),
        _buildSectionTitle('Popular'),
        _buildHorizontalList(popularAnime),
        SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
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
            // Profile Section - no background
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (!isUserLoggedIn) {
                  // Navigate to login screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                } else {
                  // Show logged in popup
                  _showLoggedInPopup();
                }
              },
              child: Container(
                width: 24,
                height: 24,
                child: isUserLoggedIn
                    ? ClipOval(
                        child: SupabaseAuthService.userPhotoUrl != null
                            ? Image.network(
                                SupabaseAuthService.userPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(Icons.person, color: Colors.white, size: 20);
                                },
                              )
                            : Icon(Icons.person, color: Colors.white, size: 20),
                      )
                    : Image.asset(
                        'assets/images/login.png',
                        color: Colors.white,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoggedInPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Logged In',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await SupabaseAuthService.signOut();
                Navigator.pop(context);
              },
              child: Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    return SliverToBoxAdapter(
      child: Container(
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: featuredAnime.length,
                itemBuilder: (context, index) {
                  return _buildFeaturedCard(featuredAnime[index]);
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
        (index) => Container(
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

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 30, 20, 16),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<AnimeItem> animeList) {
    return SliverToBoxAdapter(
      child: Container(
        height: 200,
        child: ListView.builder(
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
    return Container(
      width: 140,
      margin: EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
