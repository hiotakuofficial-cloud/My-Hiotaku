import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'handler/firebase_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'forgot.dart';

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
  
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  
  late AnimationController _fadeController;
  late AnimationController _elasticController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _elasticAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _elasticController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.fastOutSlowIn,
    ));
    
    _elasticAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _elasticController,
      curve: Curves.elasticOut,
    ));
    
    Future.delayed(Duration(milliseconds: 150), () {
      if (mounted) {
        _fadeController.forward();
        Future.delayed(Duration(milliseconds: 200), () {
          if (mounted) {
            _elasticController.forward();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _nameFocus.dispose();
    
    // Properly dispose animation controllers
    if (_fadeController.isAnimating) {
      _fadeController.stop();
    }
    if (_elasticController.isAnimating) {
      _elasticController.stop();
    }
    _fadeController.dispose();
    _elasticController.dispose();
    
    super.dispose();
  }

  void _showErrorToast(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.red, size: 14),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.grey[900],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

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
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: BoxDecoration(
            color: Color(0xFF121212),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(height: 60),
                      
                      Text(
                        _isLoginMode ? 'Sign In' : 'Sign Up',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      
                      SizedBox(height: 8),
                      
                      Text(
                        _isLoginMode ? 'Welcome back' : 'Create your account',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      
                      SizedBox(height: 60),
                      
                      _buildGoogleLoginButton(),
                      
                      SizedBox(height: 32),
                      
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.2),
                                      Colors.white.withOpacity(0.4),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.4),
                                      Colors.white.withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (!_isLoginMode) ...[
                        _buildInputField(
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          controller: _nameController,
                          focusNode: _nameFocus,
                          icon: Icons.person_outline_rounded,
                        ),
                        SizedBox(height: 24),
                      ],
                      
                      _buildInputField(
                        label: 'Email address',
                        hint: 'Enter your email address',
                        controller: _emailController,
                        focusNode: _emailFocus,
                        icon: Icons.email_outlined,
                      ),
                      
                      SizedBox(height: 24),
                      
                      _buildInputField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                      ),
                      
                      if (_isLoginMode) ...[
                        SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
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
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                      
                      SizedBox(height: 40),
                      
                      _buildSignInButton(),
                      
                      SizedBox(height: 30),
                      
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
                                _emailController.clear();
                                _passwordController.clear();
                                _nameController.clear();
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
    );
  }

  Widget _buildGoogleLoginButton() {
    return ScaleTransition(
      scale: _elasticAnimation,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _isLoading ? null : _handleGoogleLogin,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/google.png', width: 24, height: 24),
                  SizedBox(width: 16),
                  Text(
                    'Continue with Google',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return ScaleTransition(
      scale: _elasticAnimation,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading 
                ? [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)]
                : [Color(0xFFFF8C00), Color(0xFFFF6B00)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: _isLoading ? [] : [
            BoxShadow(
              color: Color(0xFFFF8C00).withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: _isLoading ? null : () {
              HapticFeedback.lightImpact();
              _handleEmailLogin();
            },
            child: Center(
              child: _isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _isLoginMode ? 'Sign In' : 'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    bool isPassword = false,
  }) {
    return ScaleTransition(
      scale: _elasticAnimation,
      child: AnimatedBuilder(
        animation: focusNode,
        builder: (context, child) {
          bool isFocused = focusNode.hasFocus;
          
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
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isFocused 
                        ? Color(0xFFFF8C00) 
                        : Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: isPassword && !_isPasswordVisible,
                  style: TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      icon,
                      color: isFocused 
                          ? Color(0xFFFF8C00) 
                          : Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                    suffixIcon: isPassword
                        ? IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: Colors.white.withOpacity(0.6),
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
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleEmailLogin() async {
    // Validate fields based on current mode
    if (_emailController.text.trim().isEmpty) {
      _showErrorToast('Please enter your email address', Icons.email_outlined);
      return;
    }
    
    if (_passwordController.text.isEmpty) {
      _showErrorToast('Please enter your password', Icons.lock_outline);
      return;
    }
    
    if (!_isLoginMode && _nameController.text.trim().isEmpty) {
      _showErrorToast('Please enter your full name', Icons.person_outline);
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim())) {
      _showErrorToast('Please enter a valid email address', Icons.email_outlined);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showErrorToast('Password must be at least 6 characters', Icons.lock_outline);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await FirebaseHandler().signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          context: context,
        );
      } else {
        await FirebaseHandler().signUpWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          context: context,
        );
      }
      
      setState(() => _isLoading = false);
      
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_time', false);
      
      // FCM will be initialized in home screen
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      String message = e.toString().replaceAll('Exception: ', '');
      IconData icon = Icons.error_outline;
      
      if (message.contains('user-not-found')) {
        message = 'No account found with this email';
        icon = Icons.person_outline;
      } else if (message.contains('wrong-password')) {
        message = 'Incorrect password';
        icon = Icons.lock_outline;
      } else if (message.contains('email-already-in-use')) {
        message = 'Email already registered';
        icon = Icons.email_outlined;
      } else if (message.contains('weak-password')) {
        message = 'Password is too weak';
        icon = Icons.security_outlined;
      } else if (message.contains('invalid-email')) {
        message = 'Invalid email address';
        icon = Icons.email_outlined;
      } else {
        message = 'Unexpected error occurred';
        icon = Icons.error_outline;
      }
      
      _showErrorToast(message, icon);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      bool firebaseOK = await FirebaseHandler().checkFirebaseConnection(context: context);
      if (!firebaseOK) {
        setState(() => _isLoading = false);
        return;
      }

      bool googleOK = await FirebaseHandler().checkGooglePlayServices(context: context);
      if (!googleOK) {
        setState(() => _isLoading = false);
        return;
      }

      User? user = await FirebaseHandler().signInWithGoogle(context: context);
      
      setState(() => _isLoading = false);
      
      if (user != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('first_time', false);
        
        // FCM will be initialized in home screen
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showErrorToast('Google login failed', Icons.g_mobiledata_outlined);
    }
  }
}
