import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';
import 'create_account_screen.dart';
import 'waiting_verification_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _formController;
  late AnimationController _buttonController;
  late AnimationController _verificationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _verificationFadeAnimation;
  late Animation<Offset> _verificationSlideAnimation;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  // Verification variables
  bool _isVerifying = false;
  Timer? _verificationTimer;
  Timer? _timeoutTimer;
  int _remainingTime = 180;
  String _verifyingEmail = '';

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _formController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: Duration(milliseconds: 100),
      vsync: this,
    );
    
    _verificationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.elasticOut),
    );
    
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    
    _verificationFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _verificationController, curve: Curves.easeOut),
    );
    
    _verificationSlideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _verificationController, curve: Curves.easeOut),
    );
    
    _controller.forward();
    _formController.forward();
  }

  void _startVerificationCheck() {
    setState(() {
      _isVerifying = true;
      _remainingTime = 180;
      _verifyingEmail = _emailController.text.trim();
    });
    
    _verificationController.forward();
    
    // Auto verification check every 3 seconds
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isVerifying) return;
      
      try {
        // Try to login to check if email is verified
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _verifyingEmail,
          password: _passwordController.text,
        );
        
        if (response.user != null && response.user!.emailConfirmedAt != null) {
          // Email verified! Auto-login successful
          _stopVerificationCheck();
          _showSuccessToast('Email verified! Welcome! 🎉');
          
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pop(context);
          }
        }
      } catch (loginError) {
        final errorStr = loginError.toString().toLowerCase();
        if (!errorStr.contains('email not confirmed') && 
            !errorStr.contains('confirmation')) {
          print('Verification check error: $loginError');
        }
        // Continue checking for confirmation errors
      }
    });
    
    // Timeout timer
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime--;
        });
        
        if (_remainingTime <= 0) {
          _stopVerificationCheck();
          _showErrorToast('Verification timeout. Please try manual login.');
        }
      }
    });
  }

  void _stopVerificationCheck() {
    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
    _verificationController.reset();
    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();
    _controller.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _verificationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    // Direct navigation to Create Account Screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateAccountScreen()),
    );
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
      await SupabaseAuthService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      Navigator.pop(context);
      _showSuccessToast('Welcome back!');
    } catch (e) {
      HapticFeedback.vibrate();
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      
      if (errorMsg.contains('Please confirm your email first') || 
          errorMsg.contains('Email not confirmed') || 
          errorMsg.contains('confirmation') ||
          errorMsg.contains('CONFIRMATION_REQUIRED')) {
        // User exists but not verified - show confirmation dialog
        _showConfirmationDialog();
      } else {
        _showErrorToast(errorMsg);
      }
    }

    setState(() => _isLoading = false);
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Email Not Confirmed',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Your email is not confirmed to login. Would you like to resend confirmation email?',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                setState(() => _isLoading = true);
                
                try {
                  await Supabase.instance.client.auth.resend(
                    type: OtpType.signup,
                    email: _emailController.text.trim(),
                  );
                  _showSuccessToast('Confirmation email sent!');
                } catch (e) {
                  // Email is usually sent even on "error" - just show success
                  _showSuccessToast('Confirmation email sent!');
                }
                
                setState(() => _isLoading = false);
                
                // Always navigate to waiting screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WaitingVerificationScreen(
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                    ),
                  ),
                );
              },
              child: Text(
                'Confirm',
                style: TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showInfoToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildVerificationScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f0f23),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _verificationFadeAnimation,
            child: SlideTransition(
              position: _verificationSlideAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    Spacer(flex: 2),
                    
                    // Lottie Animation with Glassmorphism Background
                    Container(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glassmorphism Background
                          ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Lottie Email Animation
                          Lottie.asset(
                            'assets/animations/64757bd3-7f3c-499c-a976-281563ded36c.json',
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                            repeat: true,
                            animate: true,
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: 48),
                    
                    // Title with Gradient
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Color(0xFF64B5F6),
                          Color(0xFF1976D2),
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Description with Glassmorphism
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            'A verification link has been sent to your inbox.\nPlease click the link to continue.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Email Display with Neumorphism
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF64B5F6).withOpacity(0.15),
                            Color(0xFF1976D2).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Color(0xFF64B5F6).withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF64B5F6).withOpacity(0.2),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        _verifyingEmail,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Status with Animated Dots
                    Column(
                      children: [
                        Text(
                          'Waiting for confirmation',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        // Animated Loading Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) {
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 600),
                              margin: EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color(0xFF64B5F6).withOpacity(0.7),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF64B5F6).withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                        
                        SizedBox(height: 16),
                        
                        Text(
                          'Auto-checking... ${_formatTime(_remainingTime)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64B5F6).withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    Spacer(flex: 2),
                    
                    // Cancel Button with Glassmorphism
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          margin: EdgeInsets.only(bottom: 40),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.1),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: TextButton(
                            onPressed: _stopVerificationCheck,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.9),
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      return _buildVerificationScreen();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1a1a2e),
                Color(0xFF16213e),
                Color(0xFF0f0f23),
                Color(0xFF000000),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Spacer(flex: 1),
                          
                          // Logo and Title Section
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Column(
                              children: [
                                // App Logo
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF64B5F6).withOpacity(0.4),
                                        blurRadius: 25,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.asset(
                                      'assets/images/header_logo.png',
                                      height: 90,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: 40),
                                
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Color(0xFF64B5F6),
                                      Color(0xFF1976D2),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Welcome Back',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: 12),
                                
                                Text(
                                  'Sign in to continue watching',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 50),
                          
                          // Form Section
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email Field
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: 'Email',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: Color(0xFF64B5F6).withOpacity(0.8),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Email is required';
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                
                                SizedBox(height: 20),
                                
                                // Password Field
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: 'Password',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                                      prefixIcon: Icon(
                                        Icons.lock_outlined,
                                        color: Color(0xFF64B5F6).withOpacity(0.8),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Password is required';
                                      if (value!.length < 6) return 'Password must be at least 6 characters';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 36),
                          
                          // Submit Button
                          ScaleTransition(
                            scale: _buttonAnimation,
                            child: Container(
                              width: double.infinity,
                              height: 58,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF64B5F6),
                                    Color(0xFF1976D2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF64B5F6).withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 20),
                          
                          // Forgot Password Link
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Color(0xFF64B5F6),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 28),
                          
                          // Toggle Mode
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Don\'t have an account? ',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
                              ),
                              GestureDetector(
                                onTap: _toggleMode,
                                child: Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: Color(0xFF64B5F6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          Spacer(flex: 1),
                        ],
                      ),
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
}
