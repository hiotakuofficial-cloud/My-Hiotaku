import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../../services/api_service.dart';
import '../../services/permission_service.dart';
import '../auth/login.dart';
import '../../main.dart';
import 'onboarding.dart';
import '../errors/no_internet.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Make status bar transparent instead of hiding completely
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ));
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start all tasks in parallel
    final prefsFuture = SharedPreferences.getInstance();
    final internetFuture = _checkInternetConnection();
    final gifTimer = Future.delayed(Duration(milliseconds: 3000)); // Match GIF duration
    
    // Request permissions in background (non-blocking)
    _requestPermissions();
    
    // Wait for both GIF completion AND internet check
    final results = await Future.wait([gifTimer, internetFuture]);
    final hasInternet = results[1] as bool;
    
    if (!hasInternet) {
      // Get SharedPreferences
      SharedPreferences prefs = await prefsFuture;
      
      // Redirect to no internet page
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, _) => NoInternetScreen(
            onRetry: () => _retryConnection(),
          ),
          transitionDuration: Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      return;
    }
    
    // Get SharedPreferences (already loading in parallel)
    SharedPreferences prefs = await prefsFuture;
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

  Future<bool> _checkInternetConnection() async {
    try {
      // Add 2-second timeout to prevent hanging
      final result = await InternetAddress.lookup('google.com')
          .timeout(Duration(seconds: 2));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      // Timeout or network error - assume no internet
      return false;
    }
  }

  void _retryConnection() async {
    bool hasInternet = await _checkInternetConnection();
    
    if (hasInternet) {
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
  }

  void _requestPermissions() async {
    try {
      await PermissionService.requestNotificationPermission();
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Image.asset(
          'assets/animations/splash.gif',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
