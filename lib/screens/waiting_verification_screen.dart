import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
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
  late AnimationController _dotsController;
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
    
    _dotsController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _controller.forward();
    _dotsController.repeat();
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
    _dotsController.dispose();
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
                      
                      // Clean Lottie Animation
                      Lottie.asset(
                        'assets/animations/64757bd3-7f3c-499c-a976-281563ded36c.json',
                        width: 160,
                        height: 160,
                        fit: BoxFit.contain,
                        repeat: true,
                        animate: true,
                      ),
                      
                      SizedBox(height: 48),
                      
                      // Title
                      Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Description
                      Text(
                        'A verification link has been sent to your inbox.\nPlease click the link to continue.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Email Display
                      Text(
                        widget.email,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64B5F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      SizedBox(height: 40),
                      
                      // Status with Animated Loading Dots
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
                          AnimatedBuilder(
                            animation: _dotsController,
                            builder: (context, child) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  double delay = index * 0.3;
                                  double animValue = (_dotsController.value - delay).clamp(0.0, 1.0);
                                  double opacity = 0.3 + 0.7 * (0.5 + 0.5 * math.sin(animValue * 2 * math.pi));
                                  double scale = 0.8 + 0.4 * (0.5 + 0.5 * math.sin(animValue * 2 * math.pi));
                                  
                                  return Container(
                                    margin: EdgeInsets.symmetric(horizontal: 4),
                                    width: 8 * scale,
                                    height: 8 * scale,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF64B5F6).withOpacity(opacity),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                          
                          SizedBox(height: 16),
                          
                          Text(
                            'Confirming... ${_formatTime(_remainingTime)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64B5F6).withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      Spacer(flex: 2),
                      
                      // Clean Cancel Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        margin: EdgeInsets.only(bottom: 40),
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
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
