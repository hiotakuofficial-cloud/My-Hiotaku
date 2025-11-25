import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  late AnimationController _controller;
  late AnimationController _buttonController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonAnimation;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _buttonController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      return;
    }

    _buttonController.forward().then((_) => _buttonController.reverse());
    HapticFeedback.lightImpact();

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'https://hiotaku.kesug.com/reset-password.php',
      );
      
      _showSuccessToast('Password reset email sent!');
      Navigator.pop(context);
    } catch (e) {
      _showErrorToast('Failed to send reset email');
    }

    setState(() => _isLoading = false);
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
                Color(0xFF0F0F23),
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 80),
                          
                          // Title Section
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              
                              SizedBox(height: 8),
                              
                              Text(
                                'No worries, we\'ll send you reset instructions.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 48),
                          
                          // Email Field
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              
                              SizedBox(height: 8),
                              
                              Form(
                                key: _formKey,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _emailController,
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email',
                                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                      prefixIcon: Icon(
                                        Icons.email_outlined,
                                        color: Colors.white.withOpacity(0.6),
                                        size: 20,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 32),
                          
                          // Reset Button
                          AnimatedBuilder(
                            animation: _buttonAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _buttonAnimation.value,
                                child: Container(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF64B5F6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
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
                                            'Send Reset Link',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          Spacer(),
                          
                          SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
