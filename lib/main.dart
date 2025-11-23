import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://brwzqawoncblbxqoqyua.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyd3pxYXdvbmNibGJ4cW9xeXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzM1MjIsImV4cCI6MjA3NzkwOTUyMn0.-HNrfcz5K2N6f_Q8tQsWtsUJCV_SW13Hcj565qU5eCA',
  );

  // Listen for deep links
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedIn) {
      print('User signed in via deep link: ${data.session?.user?.email}');
    }
  });
  
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hiotaku',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF0a0e27),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _SmoothPageTransition(),
            TargetPlatform.iOS: _SmoothPageTransition(),
          },
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/main': (context) => MainScreen(),
        '/login': (context) => LoginScreen(),
        '/confirm': (context) => ConfirmationScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class _SmoothPageTransition extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(0.1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn)),
        child: child,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _navAnimationController;

  final List<Widget> _screens = [
    HomeScreen(),
    _PlaceholderScreen('Search'),
    _PlaceholderScreen('Favorites'),
    _PlaceholderScreen('Profile'),
  ];

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
    
    _pageController = PageController();
    _navAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _navAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      _navAnimationController.reset();
      setState(() => _currentIndex = index);
      _navAnimationController.forward();
    }
  }

  void _onNavTap(int index) {
    HapticFeedback.lightImpact();
    _navAnimationController.reset();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _navAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              children: _screens,
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_rounded, 0, 'Home'),
                  _buildNavItem(Icons.search_rounded, 1, 'Search'),
                  _buildNavItem(Icons.favorite_rounded, 2, 'Favorites'),
                  _buildNavItem(Icons.person_rounded, 3, 'Profile'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, String label) {
    bool isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onNavTap(index),
      child: AnimatedBuilder(
        animation: _navAnimationController,
        builder: (context, child) {
          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 16 : 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(_navAnimationController.value) : Colors.transparent,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: isSelected ? (1.0 + 0.1 * _navAnimationController.value) : 1.0,
                  child: Icon(
                    icon,
                    color: isSelected 
                        ? Color.lerp(Colors.white.withOpacity(0.6), Colors.black, _navAnimationController.value)
                        : Colors.white.withOpacity(0.6),
                    size: 24,
                  ),
                ),
                if (isSelected) ...[
                  SizedBox(width: 8 * _navAnimationController.value),
                  Opacity(
                    opacity: _navAnimationController.value,
                    child: Transform.translate(
                      offset: Offset((1 - _navAnimationController.value) * 10, 0),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class ConfirmationScreen extends StatefulWidget {
  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    _handleConfirmation();
  }

  void _handleConfirmation() async {
    // Wait for auth state to settle
    await Future.delayed(Duration(seconds: 2));
    
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user != null && user.emailConfirmedAt != null) {
      // User is confirmed and logged in - go to main app
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } else {
      // Not logged in or not confirmed - go to login
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFF64B5F6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Account Confirmed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Redirecting to app...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(
                color: Color(0xFF64B5F6),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('$title Screen', style: TextStyle(color: Colors.white, fontSize: 24)),
      ),
    );
  }
}
