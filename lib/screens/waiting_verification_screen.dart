import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WaitingVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const WaitingVerificationScreen({
    Key? key,
    required this.email,
    required this.password,
  }) : super(key: key);

  @override
  _WaitingVerificationScreenState createState() => _WaitingVerificationScreenState();
}

class _WaitingVerificationScreenState extends State<WaitingVerificationScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Timer? _verificationTimer;
  Timer? _timeoutTimer;
  int _remainingTime = 180;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
    _startVerificationCheck();
  }

  void _startVerificationCheck() {
    // Auto verification check every 3 seconds
    _verificationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        // Try to login to check if email is verified
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: widget.email,
          password: widget.password,
        );
        
        if (response.user != null && response.user!.emailConfirmedAt != null) {
          // Email verified! Auto-login successful
          _stopVerificationCheck();
          _showSuccessToast('Email verified! Welcome! 🎉');
          
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        }
      } catch (loginError) {
        final errorStr = loginError.toString().toLowerCase();
        if (!errorStr.contains('email not confirmed') && 
            !errorStr.contains('confirmation')) {
          print('Verification check error: $loginError');
        }
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
    _verificationTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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

  @override
  void dispose() {
    _stopVerificationCheck();
    _controller.dispose();
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
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
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
                          widget.email,
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
                              onPressed: () => Navigator.pop(context),
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
      ),
    );
  }
}
