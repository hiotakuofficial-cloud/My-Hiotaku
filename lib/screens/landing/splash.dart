import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/permission_service.dart';
import '../../services/statistics.dart';
import '../../main.dart';
import 'onboarding.dart';

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
    final gifTimer = Future.delayed(Duration(milliseconds: 3000)); // Match GIF duration
    
    // Request permissions and track app open in background (non-blocking)
    _requestPermissions();
    _trackAppOpen();
    
    // Wait for GIF completion
    await gifTimer;
    
    // Get SharedPreferences
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

  void _requestPermissions() async {
    try {
      await PermissionService.requestNotificationPermission();
    } catch (e) {
    }
  }

  void _trackAppOpen() async {
    try {
      await StatisticsService.trackAppOpen();
    } catch (e) {
      // Silent fail
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
