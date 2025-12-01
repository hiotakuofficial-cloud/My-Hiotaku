import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'handler/firebase_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoginMode = true;
  
  late AnimationController _fadeController;
  late AnimationController _elasticController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _elasticAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _elasticController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _elasticAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _elasticController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    _elasticController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _fadeController.dispose();
    _elasticController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF0a0e27),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0a0e27),
                Color(0xFF1a1f3a),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _elasticAnimation,
                    child: Column(
                      children: [
                        SizedBox(height: 80),
                        
                        // App Logo/Title with elastic bounce
                        AnimatedBuilder(
                          animation: _elasticAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 0.8 + (_elasticAnimation.value * 0.2),
                              child: Text(
                                'Hiotaku',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 60),
                        
                        // Sign In Title
                        Text(
                          _isLoginMode ? 'Sign In' : 'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        SizedBox(height: 40),
                        
                        // Google Login Button
                        _buildGoogleLoginButton(),
                        
                        SizedBox(height: 30),
                        
                        // Divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 30),
                        
                        // Name Field (only for signup)
                        if (!_isLoginMode) ...[
                          _buildInputField(
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            controller: _nameController,
                            icon: Icons.person_outline,
                          ),
                          SizedBox(height: 20),
                        ],
                        
                        // Email Field
                        _buildInputField(
                          label: 'Email address',
                          hint: 'Enter your email address',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Password Field
                        _buildInputField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passwordController,
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        
                        if (_isLoginMode) ...[
                          SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Forgot password feature coming soon!'),
                                    backgroundColor: Colors.orange,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                        
                        SizedBox(height: 40),
                        
                        // Sign In Button
                        _buildSignInButton(),
                        
                        SizedBox(height: 30),
                        
                        // Toggle Login/Signup
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLoginMode ? "Don't have an account? " : "Already have an account? ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _isLoginMode = !_isLoginMode;
                                });
                              },
                              child: Text(
                                _isLoginMode ? 'Sign Up' : 'Sign In',
                                style: TextStyle(
                                  color: Color(0xFFFF8C00),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleLoginButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleGoogleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://developers.google.com/identity/images/g-logo.png',
                  ),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Sign up with Google',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !_isPasswordVisible,
            style: TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(0.5),
                size: 20,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white.withOpacity(0.5),
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF8C00).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isLoginMode ? 'Sign In' : 'Sign Up',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _handleAction() async {
    // Validate fields
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty ||
        (!_isLoginMode && _nameController.text.isEmpty)) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Please fill all fields'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Please enter a valid email address'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate password length
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Password must be at least 6 characters'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    try {
      User? user;
      
      if (_isLoginMode) {
        // Firebase Email/Password Login
        user = await FirebaseHandler().signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          context: context,
        );
      } else {
        // Firebase Email/Password Sign Up
        user = await FirebaseHandler().signUpWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          context: context,
        );
      }
      
      setState(() => _isLoading = false);
      
      if (user != null) {
        // Mark onboarding as completed after successful login
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('first_time', false);
        
        // Success - navigate to main app
        Navigator.pushReplacementNamed(context, '/main');
      }
      
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Unexpected error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleGoogleLogin() async {
    HapticFeedback.lightImpact();
    
    setState(() => _isLoading = true);
    
    try {
      // Check Firebase connection first
      bool firebaseOK = await FirebaseHandler().checkFirebaseConnection(context: context);
      if (!firebaseOK) {
        setState(() => _isLoading = false);
        return;
      }

      // Check Google Play Services
      bool googleOK = await FirebaseHandler().checkGooglePlayServices(context: context);
      if (!googleOK) {
        setState(() => _isLoading = false);
        return;
      }

      // Use FirebaseHandler for Google Sign-in with context
      User? user = await FirebaseHandler().signInWithGoogle(context: context);
      
      setState(() => _isLoading = false);
      
      if (user != null) {
        // Mark onboarding as completed after successful Google login
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('first_time', false);
        
        // Success - navigate to main app
        Navigator.pushReplacementNamed(context, '/main');
      }
      
    } catch (e) {
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
