import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../errors/no_internet.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  DateTime? _lastClickTime;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: _emailSent ? _buildSuccessScreen() : _buildResetScreen(),
        ),
      ),
    );
  }

  Widget _buildResetScreen() {
    return CustomScrollView(
      physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Forgot Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 40), // Balance the back button
                  ],
                ),
                
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Lottie Animation
                      Container(
                        height: 250,
                        width: 250,
                        child: Lottie.asset(
                          'assets/animations/forgot.json',
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      SizedBox(height: 30),
                      
                      // Title
                      Text(
                        'Reset Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Description
                      Text(
                        'Don\'t worry! It happens. Please enter the\nemail associated with your account.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Address',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            
                            // Email Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: _errorMessage != null 
                                  ? Border.all(color: Colors.red, width: 1)
                                  : null,
                              ),
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: TextStyle(color: Colors.white),
                                enabled: !_isLoading,
                                validator: _validateEmail,
                                decoration: InputDecoration(
                                  hintText: 'name@example.com',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (_errorMessage != null) {
                                    setState(() => _errorMessage = null);
                                  }
                                },
                              ),
                            ),
                            
                            // Error Message
                            if (_errorMessage != null)
                              Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Send Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSendReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF8C00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Send',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessScreen() {
    return CustomScrollView(
      physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _emailSent = false);
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Check Your Email',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
                
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success Animation
                      Container(
                        height: 300,
                        width: 300,
                        child: Lottie.asset(
                          'assets/animations/sended.json',
                          fit: BoxFit.contain,
                          repeat: false,
                        ),
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Title
                      Text(
                        'Email Sent!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Description
                      Text(
                        'We\'ve sent a password reset link to\n${_emailController.text}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Open Gmail Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _openGmail,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF8C00),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.email, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Open Gmail',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Back to Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.login, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Back to Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final email = value.trim().toLowerCase();
    
    // Basic email format validation
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    // Check for common typos
    if (email.contains('..') || email.startsWith('.') || email.endsWith('.')) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  Future<void> _handleSendReset() async {
    // Debounce: Prevent clicks within 2 seconds
    final now = DateTime.now();
    if (_lastClickTime != null && now.difference(_lastClickTime!).inSeconds < 2) {
      return;
    }
    _lastClickTime = now;
    
    if (!_formKey.currentState!.validate()) return;
    
    // Prevent multiple clicks
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final email = _emailController.text.trim().toLowerCase();
      
      // Direct password reset - Firebase handles email existence internally
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timed out. Please check your connection.');
        },
      );
      
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
      
      HapticFeedback.lightImpact();
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e.code);
      });
      
      HapticFeedback.heavyImpact();
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please check your internet connection and try again';
      });
      
      // Show network error page only for network issues
      if (e.toString().contains('network') || 
          e.toString().contains('connection') || 
          e.toString().contains('timeout')) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoInternetScreen()),
        );
      }
    }
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'We couldn\'t find an account with this email';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again';
      case 'network-request-failed':
        return 'Please check your internet connection';
      case 'auth/user-disabled':
        return 'This account has been temporarily disabled';
      case 'auth/operation-not-allowed':
        return 'Password reset is currently unavailable';
      default:
        return 'Something went wrong. Please try again';
    }
  }

  Future<void> _openGmail() async {
    HapticFeedback.lightImpact();
    
    try {
      // Try multiple Gmail URL schemes
      final gmailSchemes = [
        'googlegmail://',
        'gmail://',
        'mailto:',
      ];
      
      bool opened = false;
      
      for (String scheme in gmailSchemes) {
        try {
          final url = Uri.parse(scheme);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            opened = true;
            break;
          }
        } catch (e) {
          continue;
        }
      }
      
      if (!opened) {
        // Fallback to web Gmail
        final webGmailUrl = Uri.parse('https://mail.google.com');
        await launchUrl(webGmailUrl, mode: LaunchMode.externalApplication);
      }
      
    } catch (e) {
      // Show helpful message instead of error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Check your email app for the password reset link'),
          backgroundColor: Color(0xFFFF8C00),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
