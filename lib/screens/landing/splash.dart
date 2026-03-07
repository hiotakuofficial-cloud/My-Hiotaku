import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../services/permission_service.dart';
import '../../services/statistics.dart';
import '../../main.dart';
import 'onboarding.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    // Make status bar transparent
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/animations/hiotaku_splash.mp4');
    
    try {
      await _controller.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      
      // Play video
      await _controller.play();
      
      // Wait for video to complete
      _controller.addListener(() {
        if (_controller.value.position >= _controller.value.duration) {
          _navigateToNext();
        }
      });
      
      // Start background tasks
      _requestPermissions();
      _trackAppOpen();
      
    } catch (e) {
      // Fallback if video fails
      await Future.delayed(Duration(seconds: 3));
      _navigateToNext();
    }
  }

  void _requestPermissions() async {
    try {
      await PermissionService.requestNotificationPermission();
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _trackAppOpen() async {
    try {
      await StatisticsService.trackAppOpen();
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _navigateToNext() async {
    if (!mounted) return;
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time') ?? true;
    
    if (isFirstTime) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => OnboardingScreen(),
          transitionDuration: Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => MainScreen(),
          transitionDuration: Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
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
      backgroundColor: Colors.black,
      body: _isVideoInitialized
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            )
          : Container(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}
