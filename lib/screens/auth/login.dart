import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isLoginMode = true; // true for Login, false for Sign Up

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1f3a),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1f3a),
              Color(0xFF2d3561),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: 60),
                
                // Floating food icons background
                _buildFloatingIcons(),
                
                SizedBox(height: 40),
                
                // Chef hat icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 40,
                    color: Color(0xFF1a1f3a),
                  ),
                ),
                
                SizedBox(height: 40),
                
                // Login/Sign Up toggle
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF2d3561),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLoginMode = true),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isLoginMode ? Color(0xFFFF4444) : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'Login',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: _isLoginMode ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLoginMode = false),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isLoginMode ? Color(0xFFFF4444) : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'Sign up',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: !_isLoginMode ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 40),
                
                // Form fields
                if (!_isLoginMode) ...[
                  _buildInputField('Full Name', 'Enter Name for Display', false),
                  SizedBox(height: 20),
                ],
                
                _buildInputField('Email Address', 'hiotakuofficial@gmail.com', false),
                SizedBox(height: 20),
                
                _buildInputField('Password', '••••••••', true),
                
                if (_isLoginMode) ...[
                  SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to forgot password
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Forgot password feature coming soon!'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      },
                      child: Text(
                        'Forgot password',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: 40),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isLoginMode ? 'Login' : 'Sign up',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingIcons() {
    return Container(
      height: 120,
      child: Stack(
        children: [
          // Floating food icons
          Positioned(top: 10, left: 20, child: _buildFloatingIcon('🍎', Colors.red)),
          Positioned(top: 30, right: 30, child: _buildFloatingIcon('🍌', Colors.yellow)),
          Positioned(top: 60, left: 60, child: _buildFloatingIcon('🥕', Colors.orange)),
          Positioned(top: 20, left: 100, child: _buildFloatingIcon('🍇', Colors.purple)),
          Positioned(top: 80, right: 80, child: _buildFloatingIcon('🍓', Colors.red)),
          Positioned(top: 50, right: 150, child: _buildFloatingIcon('🥬', Colors.green)),
        ],
      ),
    );
  }

  Widget _buildFloatingIcon(String emoji, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String hint, bool isPassword) {
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
            color: Color(0xFF2d3561),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: isPassword ? _passwordController : _emailController,
            obscureText: isPassword && !_isPasswordVisible,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      onPressed: () {
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
  }

  void _handleAction() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(Duration(seconds: 2));
    
    setState(() => _isLoading = false);
    
    // Navigate to main app
    Navigator.pushReplacementNamed(context, '/main');
  }
}
