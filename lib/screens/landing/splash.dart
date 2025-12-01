import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/api_cache.dart';
import '../../services/permission_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Hide status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward();
    
    // Check auth and preload data
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Request permissions first
    await _requestPermissions();
    
    // Preload data during splash
    await _preloadData();
    
    // Wait for minimum splash duration
    await Future.delayed(Duration(milliseconds: 2500));
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Check if first time user
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time') ?? true;
    
    if (isFirstTime) {
      // First time user - show onboarding
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else {
      // Returning user - go directly to main app
      Navigator.of(context).pushReplacementNamed('/main');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request notification permission silently
      await PermissionService.requestNotificationPermission();
      
      // Request storage permissions silently
      await PermissionService.requestStoragePermissions();
      
      // Request media permissions silently (Android 13+)
      await PermissionService.requestMediaPermissions();
      
      print('Permissions requested during splash');
    } catch (e) {
      print('Permission request failed: $e');
    }
  }

  Future<void> _preloadData() async {
    try {
      // Add timeout to prevent splash from getting stuck
      await Future.any([
        Future.delayed(Duration(milliseconds: 1500)), // Max 1.5s for preload
        _loadDataWithTimeout(),
      ]);
    } catch (e) {
      print('Preload failed: $e');
      // Continue to main screen even if preload fails
    }
  }
  
  Future<void> _loadDataWithTimeout() async {
    try {
      // Check if data is already cached
      final cacheKey = 'home_1';
      final cached = ApiCache.get(cacheKey);
      
      if (cached == null) {
        // Load fresh data in background during splash
        await ApiService.getHome();
        print('Main screen data preloaded during splash');
      } else {
        print('Using cached data for main screen');
      }
    } catch (e) {
      print('Data load failed: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF000000),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF000000),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Simple elegant logo
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 30,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                      
                      SizedBox(height: 40),
                      
                      // App name - clean typography
                      Text(
                        'HIOTAKU',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                      
                      SizedBox(height: 12),
                      
                      Text(
                        'Premium Anime',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.6),
                          letterSpacing: 2,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      
                      SizedBox(height: 80),
                      
                      // Minimal loading indicator
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.8),
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
      ),
    );
  }
}
