import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import '../services/supabase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _formController;
  late AnimationController _buttonController;
  late AnimationController _backgroundController;
  
  late Animation<double> _logoAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _formAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _backgroundAnimation;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _formController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );
    
    // Staggered animations like iOS
    _logoAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    
    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: Curves.easeOutCubic,
    ));
    
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.linear),
    );

    // Start animations
    _mainController.forward();
    _backgroundController.repeat();
    Future.delayed(Duration(milliseconds: 800), () {
      _formController.forward();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _backgroundController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    HapticFeedback.lightImpact();
    setState(() => _isSignUp = !_isSignUp);
    _formController.reset();
    _formController.forward();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    _buttonController.forward().then((_) => _buttonController.reverse());
    HapticFeedback.lightImpact();
    
    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await SupabaseAuthService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        HapticFeedback.lightImpact();
        _showSnackBar('Account created! Check your email ✨', Colors.green);
      } else {
        await SupabaseAuthService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        HapticFeedback.lightImpact();
        Navigator.pop(context);
        _showSnackBar('Welcome back! 🎉', Colors.green);
      }
    } catch (e) {
      HapticFeedback.vibrate();
      _showSnackBar(_isSignUp ? 'Sign up failed 😞' : 'Login failed 😞', Colors.red);
    }

    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.all(20),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 16,
                ),
                prefixIcon: Container(
                  margin: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
                ),
                suffixIcon: suffixIcon,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              ),
              validator: validator,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(Color(0xFF0a0e27), Color(0xFF1a1a2e), _backgroundAnimation.value)!,
                  Color.lerp(Color(0xFF16213e), Color(0xFF0a0e27), _backgroundAnimation.value)!,
                  Color.lerp(Color(0xFF1a1a2e), Color(0xFF16213e), _backgroundAnimation.value)!,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      Spacer(flex: 2),
                      
                      // Animated Logo with glow effect
                      FadeTransition(
                        opacity: _logoAnimation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                            CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
                          ),
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: Image.asset(
                                'assets/images/header_logo.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Animated Title
                      FadeTransition(
                        opacity: _titleAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _mainController,
                            curve: Interval(0.2, 0.6, curve: Curves.easeOutCubic),
                          )),
                          child: Column(
                            children: [
                              Text(
                                _isSignUp ? 'Create Account' : 'Welcome Back',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              SizedBox(height: 12),
                              
                              Text(
                                _isSignUp 
                                    ? 'Join the ultimate anime community'
                                    : 'Continue your anime journey',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      Spacer(flex: 1),
                      
                      // Animated Form
                      FadeTransition(
                        opacity: _formAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email Field
                                _buildGlassField(
                                  controller: _emailController,
                                  hint: 'Email Address',
                                  icon: CupertinoIcons.mail,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Email is required';
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                
                                // Password Field
                                _buildGlassField(
                                  controller: _passwordController,
                                  hint: 'Password',
                                  icon: CupertinoIcons.lock,
                                  obscureText: !_isPasswordVisible,
                                  suffixIcon: GestureDetector(
                                    onTap: () {
                                      setState(() => _isPasswordVisible = !_isPasswordVisible);
                                      HapticFeedback.selectionClick();
                                    },
                                    child: Container(
                                      margin: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _isPasswordVisible 
                                            ? CupertinoIcons.eye_slash 
                                            : CupertinoIcons.eye,
                                        color: Colors.white.withOpacity(0.8),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Password is required';
                                    if (value!.length < 6) return 'Password must be at least 6 characters';
                                    return null;
                                  },
                                ),
                                
                                SizedBox(height: 20),
                                
                                // Glassmorphism Auth Button
                                ScaleTransition(
                                  scale: _buttonScaleAnimation,
                                  child: Container(
                                    width: double.infinity,
                                    height: 60,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blue.withOpacity(0.8),
                                                Colors.blueAccent.withOpacity(0.8),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _isLoading ? null : _handleAuth,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: _isLoading
                                                ? CupertinoActivityIndicator(
                                                    color: Colors.white,
                                                    radius: 12,
                                                  )
                                                : Text(
                                                    _isSignUp ? 'Create Account' : 'Sign In',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      Spacer(flex: 1),
                      
                      // Toggle Button
                      FadeTransition(
                        opacity: _formAnimation,
                        child: GestureDetector(
                          onTap: _toggleMode,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(fontSize: 16),
                                children: [
                                  TextSpan(
                                    text: _isSignUp 
                                        ? 'Already have an account? '
                                        : 'Don\'t have an account? ',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _isSignUp ? 'Sign In' : 'Sign Up',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
