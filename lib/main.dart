import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'screens/landing/splash.dart';
import 'screens/landing/onboarding.dart';
import 'screens/auth/login.dart';
import 'screens/auth/bord_login.dart';
import 'screens/home_screen.dart';
import 'config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  try {
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } on FirebaseException catch (e) {
    print('❌ Firebase initialization failed: ${e.code} - ${e.message}');
    // App can still run without Firebase, but features will be limited
  } catch (e) {
    print('❌ Unexpected Firebase error: ${e.toString()}');
  }
  
  // Set orientation
  try {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    print('✅ Orientation set to portrait');
  } catch (e) {
    print('⚠️ Failed to set orientation: ${e.toString()}');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hiotaku',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFF121212),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: _SmoothPageTransition(),
            TargetPlatform.iOS: _SmoothPageTransition(),
          },
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/onboarding': (context) => OnboardingScreen(),
        '/login': (context) => LoginScreen(),
        '/bord_login': (context) => BordLoginScreen(),
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
    SearchPage(),
    FavoritesPage(),
    ProfilePage(),
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

  void _onNavTap(int index) {
    HapticFeedback.lightImpact();
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
        backgroundColor: Color(0xFF121212),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
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
              color: Color(0xFF121212).withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
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
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_rounded, 0, 'Home'),
                  _buildNavItem(Icons.search_rounded, 1, 'Search'),
                  _buildNavItem(Icons.favorite_rounded, 2, 'Favorites'),
                  _buildNavItem(Icons.account_circle, 3, 'Profile'),
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
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
          size: 24,
        ),
      ),
    );
  }
}

// Placeholder pages
class SearchPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        extendBodyBehindAppBar: true,
        body: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 100),
          child: Column(
            children: [
              Text(
                'Search',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search anime...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6)),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'Search functionality coming soon!',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        extendBodyBehindAppBar: true,
        body: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 100),
          child: Column(
            children: [
              Text(
                'Favorites',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_outline, color: Colors.white.withOpacity(0.3), size: 80),
                      SizedBox(height: 20),
                      Text(
                        'No favorites yet',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add anime to your favorites to see them here',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: SafeArea(
          child: Column(
            children: [
              // Header with back button and settings
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    ),
                    Text(
                      'My Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Profile Avatar and Info
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'H',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Color(0xFF121212),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  Text(
                    'Hiotaku User',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  
                  SizedBox(height: 4),
                  
                  Text(
                    '@hiotakuuser',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 40),
              
              // Profile Options List
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildProfileOption(Icons.favorite_outline, 'Favourites'),
                    _buildProfileOption(Icons.download_outlined, 'Downloads'),
                    _buildProfileOption(Icons.language_outlined, 'Language'),
                    _buildProfileOption(Icons.location_on_outlined, 'Location'),
                    _buildProfileOption(Icons.subscriptions_outlined, 'Subscription'),
                    _buildProfileOption(Icons.clear_all_outlined, 'Clear cache'),
                    _buildProfileOption(Icons.history_outlined, 'Clear history'),
                    _buildProfileOption(Icons.logout_outlined, 'Log out', isLogout: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {bool isLogout = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isLogout 
                ? Colors.red.withOpacity(0.1) 
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isLogout ? Colors.red : Colors.white.withOpacity(0.8),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isLogout ? Colors.red : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.white.withOpacity(0.4),
          size: 16,
        ),
        onTap: () {
          if (isLogout) {
            _showLogoutDialog();
          } else {
            // Handle other options
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title - Coming Soon!'),
                backgroundColor: Color(0xFFFF8C00),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Log Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}


