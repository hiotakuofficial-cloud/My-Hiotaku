import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../services/api_cache.dart';
import '../services/auth_service.dart';
import '../models/api_models.dart';
import '../widgets/anime_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  List<AnimeItem> animeList = [];
  bool isLoading = true;
  String error = '';
  bool isUserLoggedIn = false; // Track login status

  @override
  bool get wantKeepAlive => true; // Keep state alive

  @override
  void initState() {
    super.initState();
    _loadAnime();
    
    // Listen to auth state changes
    AuthService.authStateChanges.listen((user) {
      if (mounted) {
        setState(() {
          isUserLoggedIn = user != null;
        });
      }
    });
  }

  Future<void> _loadAnime() async {
    if (!mounted) return;

    // Show cached data immediately if available
    final cacheKey = 'home_1';
    final cached = ApiCache.get<HomeResponse>(cacheKey);
    if (cached != null && cached.data.isNotEmpty) {
      setState(() {
        animeList = cached.data;
        isLoading = false;
        error = '';
      });
    } else {
      setState(() {
        isLoading = true;
        error = '';
      });
    }

    try {
      final result = await ApiService.getHome();
      if (mounted) {
        setState(() {
          animeList = result.data;
          isLoading = false;
          error = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Only show error if no cached data
          if (animeList.isEmpty) {
            error = e.toString();
            isLoading = false;
          } else {
            isLoading = false;
          }
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await _loadAnime();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0a0e27), Color(0xFF16213e)],
            ),
          ),
          child: SafeArea(
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                      child: AuthService.userPhotoUrl != null
                          ? Image.network(
                              AuthService.userPhotoUrl!,
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
            // Default avatar
            CircleAvatar(
              radius: 40,
              backgroundImage: AuthService.userPhotoUrl != null 
                  ? NetworkImage(AuthService.userPhotoUrl!) 
                  : null,
              child: AuthService.userPhotoUrl == null 
                  ? Icon(Icons.person, color: Colors.white, size: 40) 
                  : null,
            ),
            SizedBox(height: 16),
            Text(
              'Logged In',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              AuthService.userName,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              AuthService.userEmail,
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await AuthService.signOut();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Signed out successfully'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Sign out failed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return LoadingWidget();
    }
    
    if (error.isNotEmpty) {
      return CustomErrorWidget(
        error: error,
        onRetry: _loadAnime,
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Colors.blue,
      backgroundColor: Color(0xFF16213e),
      child: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          // Header as part of scrollable content
          SliverToBoxAdapter(
            child: _buildHeader(),
          ),
          // Anime list
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return AnimeCard(
                    anime: animeList[index],
                    index: index,
                  );
                },
                childCount: animeList.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
