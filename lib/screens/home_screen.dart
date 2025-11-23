import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../models/api_models.dart';
import '../widgets/anime_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

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
  }

  Future<void> _loadAnime() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final result = await ApiService.getHome();
      if (mounted) {
        setState(() {
          animeList = result.data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
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
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0a0e27), Color(0xFF16213e)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Row(
        children: [
          // HIOTAKU Logo
          Container(
            height: 40,
            child: Image.asset(
              'assets/images/header_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          Spacer(),
          // Profile Section
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              if (!isUserLoggedIn) {
                // Show login dialog or navigate to login
                _showLoginDialog();
              } else {
                // Navigate to profile screen
                _navigateToProfile();
              }
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUserLoggedIn ? null : Colors.white.withOpacity(0.1),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: isUserLoggedIn
                  ? ClipOval(
                      child: Image.asset(
                        'assets/images/default_avatar.png', // Default avatar
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person, color: Colors.white, size: 20);
                        },
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      color: Colors.white.withOpacity(0.8),
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF16213e),
        title: Text('Login Required', style: TextStyle(color: Colors.white)),
        content: Text(
          'Please login to access your profile and personalized features.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to login screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Login'),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    // Navigate to profile screen
    print('Navigate to profile');
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
      child: ListView.builder(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: animeList.length,
        itemBuilder: (context, index) {
          return AnimeCard(
            anime: animeList[index],
            index: index,
          );
        },
      ),
    );
  }
}
