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
  List<String> _usernameSuggestions = [];
  bool _showSuggestions = false;
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
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
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
    if (username.length >= 2) {
      _suggestionTimer?.cancel();
      _suggestionTimer = Timer(Duration(milliseconds: 500), () {
        _getUsernameSuggestions(username);
      });
    } else {
      setState(() {
        _showSuggestions = false;
        _usernameSuggestions.clear();
      });
    }
  }

  Future<void> _getUsernameSuggestions(String username) async {
    try {
      // Check if username exists in database
      final response = await Supabase.instance.client
          .from('users')
          .select('username')
          .ilike('username', '$username%')
          .limit(5);
      
      List<String> existingUsernames = (response as List)
          .map((user) => user['username'] as String)
          .toList();
      
      // Generate suggestions
      List<String> suggestions = [];
      
      // Add original if not taken
      if (!existingUsernames.contains(username)) {
        suggestions.add(username);
      }
      
      // Add variations
      for (int i = 1; i <= 3; i++) {
        String suggestion = '$username$i';
        if (!existingUsernames.contains(suggestion)) {
          suggestions.add(suggestion);
        }
      }
      
      // Add random suffix suggestions
      List<String> suffixes = ['_official', '_pro', '_user', '123', '456'];
      for (String suffix in suffixes) {
        String suggestion = '$username$suffix';
        if (!existingUsernames.contains(suggestion) && suggestions.length < 5) {
          suggestions.add(suggestion);
        }
      }
      
      setState(() {
        _usernameSuggestions = suggestions.take(5).toList();
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      print('Username suggestion error: $e');
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
      HapticFeedback.vibrate();
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      _showErrorToast(errorMsg);
    }

    setState(() => _isLoading = false);
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
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
                        children: [
                          Spacer(flex: 1),
                          
                          // Title Section
                          ScaleTransition(
                            scale: _scaleAnimation,
                            child: Column(
                              children: [
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
                                // Username Field with Suggestions
                                Column(
                                  children: [
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
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                        ),
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) return 'Username is required';
                                          if (value!.length < 3) return 'Username must be at least 3 characters';
                                          return null;
                                        },
                                      ),
                                    ),
                                    
                                    // Username Suggestions
                                    if (_showSuggestions && _usernameSuggestions.isNotEmpty)
                                      Container(
                                        margin: EdgeInsets.only(top: 8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                        ),
                                        child: Column(
                                          children: _usernameSuggestions.map((suggestion) {
                                            return ListTile(
                                              dense: true,
                                              title: Text(
                                                suggestion,
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.9),
                                                  fontSize: 14,
                                                ),
                                              ),
                                              leading: Icon(
                                                Icons.lightbulb_outline,
                                                color: Color(0xFF64B5F6).withOpacity(0.7),
                                                size: 16,
                                              ),
                                              onTap: () {
                                                _usernameController.text = suggestion;
                                                setState(() {
                                                  _showSuggestions = false;
                                                });
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                  ],
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
