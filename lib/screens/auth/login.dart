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
  
  // Focus nodes for input animations
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
    
    // Smooth iOS-style opening with delay
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
    _fadeController.dispose();
    _elasticController.dispose();
    super.dispose();
  }

  // iOS-style error toast
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
              child: Icon(
                icon,
                color: Colors.red,
                size: 16,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
                      SizedBox(height: 120),
                      
                      // Sign In Title - Clean and minimal
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
                      
                      // Subtitle
                      Text(
                        _isLoginMode ? 'Welcome back' : 'Create your account',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    
                    SizedBox(height: 60),
                    
                    // Google Login Button - Enhanced
                    _buildGoogleLoginButton(),
                    
                    SizedBox(height: 32),
                    
                    // Clean OR Divider with Gradient Lines
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
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
                            'Or',
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
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
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
                  
                  // Name Field (only for signup)
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
                
                // Email Field
                _buildInputField(
                  label: 'Email address',
                  hint: 'Enter your email address',
                  controller: _emailController,
                  focusNode: _emailFocus,
                  icon: Icons.email_outlined,
                ),
                
                SizedBox(height: 24),
                
                // Password Field
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
                        // Clear fields when switching modes
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
    );
  }
  }

  Widget _buildGoogleLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleGoogleLogin,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google Icon from assets
                Image.asset(
                  'assets/images/google.png',
                  height: 20,
                  width: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
    required IconData icon,
    required FocusNode focusNode,
    bool isPassword = false,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, child) {
        bool isFocused = focusNode.hasFocus;
        bool hasText = controller.text.isNotEmpty;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            
            // Input Container
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              height: 50,
              decoration: BoxDecoration(
                color: isFocused 
                    ? Colors.white.withOpacity(0.08) 
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused 
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: isFocused ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                obscureText: isPassword && !_isPasswordVisible,
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: Icon(
                    icon,
                    color: isFocused 
                        ? Colors.white.withOpacity(0.8)
                        : Colors.white.withOpacity(0.5),
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSignInButton() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading 
              ? [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)]
              : [Color(0xFFFF8C00), Color(0xFFFF6B00)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading ? [] : [
          BoxShadow(
            color: Color(0xFFFF8C00).withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : () {
            HapticFeedback.mediumImpact();
            _handleAction();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            alignment: Alignment.center,
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
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
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
      _showErrorToast('Please fill all fields', Icons.warning_rounded);
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      _showErrorToast('Please enter a valid email address', Icons.email_outlined);
      return;
    }

    // Validate password length
    if (_passwordController.text.length < 6) {
      _showErrorToast('Password must be at least 6 characters', Icons.lock_outline);
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
      
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      
      String message;
      IconData icon;
      
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          icon = Icons.person_off_outlined;
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          icon = Icons.lock_outline;
          break;
        case 'email-already-in-use':
          message = 'Email already registered';
          icon = Icons.email_outlined;
          break;
        case 'weak-password':
          message = 'Password is too weak';
          icon = Icons.security_outlined;
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          icon = Icons.email_outlined;
          break;
        case 'user-disabled':
          message = 'Account has been disabled';
          icon = Icons.block_outlined;
          break;
        case 'network-request-failed':
          message = 'Network error - check connection';
          icon = Icons.wifi_off_outlined;
          break;
        default:
          message = e.message ?? 'Authentication failed';
          icon = Icons.error_outline;
      }
      
      _showErrorToast(message, icon);
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorToast('Unexpected error occurred', Icons.error_outline);
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
      _showErrorToast('Google login failed', Icons.g_mobiledata_outlined);
    }
  }
}

// Professional Google Icon Painter
class GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Google "G" background circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2, paint);
    
    // Google "G" letter
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;
    
    // Blue part of G
    paint.color = Color(0xFF4285F4);
    path.moveTo(center.dx + radius * 0.3, center.dy - radius * 0.7);
    path.lineTo(center.dx + radius * 0.7, center.dy - radius * 0.7);
    path.lineTo(center.dx + radius * 0.7, center.dy - radius * 0.2);
    path.lineTo(center.dx + radius * 0.3, center.dy - radius * 0.2);
    path.close();
    canvas.drawPath(path, paint);
    
    // Red part of G
    paint.color = Color(0xFFEA4335);
    path.reset();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // -90 degrees
      1.57,  // 90 degrees
    );
    path.lineTo(center.dx, center.dy - radius * 0.4);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius * 0.4),
      -1.57, // -90 degrees
      -1.57, // -90 degrees
      false,
    );
    path.close();
    canvas.drawPath(path, paint);
    
    // Yellow part of G
    paint.color = Color(0xFFFBBC05);
    path.reset();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      0, // 0 degrees
      1.57, // 90 degrees
    );
    path.lineTo(center.dx + radius * 0.4, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius * 0.4),
      0, // 0 degrees
      -1.57, // -90 degrees
      false,
    );
    path.close();
    canvas.drawPath(path, paint);
    
    // Green part of G
    paint.color = Color(0xFF34A853);
    path.reset();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      1.57, // 90 degrees
      1.57, // 90 degrees
    );
    path.lineTo(center.dx - radius * 0.4, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius * 0.4),
      1.57, // 90 degrees
      1.57, // 90 degrees
      false,
    );
    path.close();
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
