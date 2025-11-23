import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return Scaffold(
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
