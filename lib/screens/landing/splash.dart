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
    // Hide status bar completely
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Fixed 3-second splash duration
    await Future.delayed(Duration(milliseconds: 3000));
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Request permissions in background (non-blocking)
    _requestPermissions();
    
    // Check network connectivity
    bool hasInternet = await _checkInternetConnection();
    
    if (!hasInternet) {
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

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
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
      print('Permission request error: $e');
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
