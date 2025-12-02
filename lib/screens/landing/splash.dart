import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/permission_service.dart';
import '../auth/login.dart';
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // GIF duration + transition time
    await Future.wait([
      Future.delayed(Duration(milliseconds: 3500)), // 3.5 seconds
      _preloadData(),
    ]);
    
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
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

  Future<void> _preloadData() async {
    try {
      await Future.wait([
        PermissionService.requestNotificationPermission().catchError((_) => null),
        ApiService.getHome().catchError((_) => null),
        ApiService.getPopular().catchError((_) => null),
      ], eagerError: false);
    } catch (e) {
      print('Preload error: $e');
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
