import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_auth_service.dart';
import 'waiting_verification_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _formController;
  late AnimationController _buttonController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _buttonAnimation;
  
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  Timer? _suggestionTimer;

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
    
    _controller.forward();
    _formController.forward();
    
    // Listen to username changes for suggestions
    _usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim();
    if (username.length >= 3) {
      _suggestionTimer?.cancel();
      _suggestionTimer = Timer(Duration(milliseconds: 800), () {
        _checkUsernameAvailability(username);
      });
    } else {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    setState(() {
      _isCheckingUsername = true;
      _isUsernameAvailable = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();
      
      setState(() {
        _isUsernameAvailable = response == null;
        _isCheckingUsername = false;
      });
    } catch (e) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    _buttonController.forward().then((_) => _buttonController.reverse());
    HapticFeedback.lightImpact();
    
    setState(() => _isLoading = true);

    try {
      await SupabaseAuthService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Navigate to waiting verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WaitingVerificationScreen(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        ),
      );
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      
      if (errorMsg.contains('CONFIRMATION_REQUIRED') ||
          errorMsg.contains('Email not confirmed') || 
          errorMsg.contains('confirmation')) {
        // User exists but not verified - go to waiting screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingVerificationScreen(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          ),
        );
      } else if (errorMsg.contains('already registered') || 
                 errorMsg.contains('User already registered')) {
        // User already exists - show iOS style alert
        _showAlreadyExistsAlert();
      } else {
        HapticFeedback.vibrate();
        _showErrorToast(errorMsg);
      }
    }

    setState(() => _isLoading = false);
  }

  void _showAlreadyExistsAlert() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Account Already Exists',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'An account with this email already exists. Please login instead.',
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
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context); // Go back to login
              },
              child: Text(
                'Login',
                style: TextStyle(color: Color(0xFF64B5F6), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
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

  @override
  void dispose() {
    _suggestionTimer?.cancel();
    _controller.dispose();
    _formController.dispose();
    _buttonController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                        children: [
                          Spacer(flex: 1),
                          
                          // Title Section with Logo
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
                                      height: 80,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: 32),
                                
                                ShaderMask(
                                  shaderCallback: (bounds) => LinearGradient(
                                    colors: [
                                      Color(0xFF64B5F6),
                                      Color(0xFF1976D2),
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                
                                SizedBox(height: 12),
                                
                                Text(
                                  'Join the anime universe',
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
                                // Username Field with Availability Check
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _usernameController,
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: 'Username',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                                      prefixIcon: Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF64B5F6).withOpacity(0.8),
                                      ),
                                      suffixIcon: _isCheckingUsername
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: Padding(
                                                padding: EdgeInsets.all(12),
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF64B5F6),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : _isUsernameAvailable != null
                                              ? Icon(
                                                  _isUsernameAvailable!
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  color: _isUsernameAvailable!
                                                      ? Colors.green
                                                      : Colors.red,
                                                )
                                              : null,
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Username is required';
                                      if (value!.length < 3) return 'Username must be at least 3 characters';
                                      if (_isUsernameAvailable == false) return 'Username is not available';
                                      return null;
                                    },
                                  ),
                                ),
                                
                                SizedBox(height: 20),
                                
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
                                
                                SizedBox(height: 20),
                                
                                // Confirm Password Field
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: !_isConfirmPasswordVisible,
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: 'Confirm Password',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: Color(0xFF64B5F6).withOpacity(0.8),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                          });
                                        },
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Please confirm your password';
                                      if (value != _passwordController.text) return 'Passwords do not match';
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 36),
                          
                          // Create Account Button
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
                                onPressed: _isLoading ? null : _createAccount,
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
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
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
