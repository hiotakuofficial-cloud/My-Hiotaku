import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ChatLockPage extends StatefulWidget {
  final bool directToPasswordEntry;
  
  const ChatLockPage({Key? key, this.directToPasswordEntry = false}) : super(key: key);
  
  @override
  _ChatLockPageState createState() => _ChatLockPageState();
}

class _ChatLockPageState extends State<ChatLockPage> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late Animation<Offset> _slideAnimation;
  
  int _currentState = 0; // 0: Toggle, 1: Set Password, 2: Enter Password
  bool _isLockEnabled = false;
  bool _isLoading = false;
  int _passwordLength = 4;
  String _password = '';
  String _confirmPassword = '';
  String _enteredPassword = '';
  
  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.elasticOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );
    
    _initializePage();
  }
  
  void _initializePage() async {
    await _checkLockStatus();
    
    if (widget.directToPasswordEntry && _isLockEnabled) {
      setState(() {
        _currentState = 2; // Direct to password entry
      });
    }
    
    _headerController.forward();
  }
  
  @override
  void dispose() {
    _headerController.dispose();
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
        body: SingleChildScrollView(
          physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          child: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 100),
            child: Column(
              children: [
                _buildHeader(),
                SizedBox(height: 30),
                _buildCurrentState(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white.withOpacity(0.7),
                    size: 24,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Chat Lock',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 24),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildCurrentState() {
    switch (_currentState) {
      case 0:
        return _buildToggleState();
      case 1:
        return _buildSetPasswordState();
      case 2:
        return _buildEnterPasswordState();
      default:
        return _buildToggleState();
    }
  }
  
  Widget _buildToggleState() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          SizedBox(height: 100),
          Icon(
            _isLockEnabled ? Icons.lock : Icons.lock_open,
            color: Color(0xFFFF8C00),
            size: 80,
          ),
          SizedBox(height: 30),
          Text(
            _isLockEnabled ? 'Chat Lock is ON' : 'Turn on Chat Lock',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 24,
                ),
                SizedBox(height: 10),
                Text(
                  'Disclaimer',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'If you forgot your password, please submit a request to our support system for assistance.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleToggleLock,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLockEnabled ? Colors.red : Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
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
                      _isLockEnabled ? 'Turn OFF' : 'Turn ON',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSetPasswordState() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50),
          Text(
            'Set Your Password',
            style: TextStyle(
              color: Color(0xFFFF8C00),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 30),
          
          // Password Length Selection
          Text(
            'Password Length',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _passwordLength = 4;
                      _password = '';
                      _confirmPassword = '';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _passwordLength == 4 ? Color(0xFFFF8C00) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _passwordLength == 4 ? Color(0xFFFF8C00) : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      '4 Digits',
                      style: TextStyle(
                        color: _passwordLength == 4 ? Colors.white : Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 15),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _passwordLength = 6;
                      _password = '';
                      _confirmPassword = '';
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _passwordLength == 6 ? Color(0xFFFF8C00) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _passwordLength == 6 ? Color(0xFFFF8C00) : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: Text(
                      '6 Digits',
                      style: TextStyle(
                        color: _passwordLength == 6 ? Colors.white : Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 30),
          
          // Password Input
          Text(
            'Enter Password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 15),
          _buildPasswordDots(_password, _passwordLength),
          
          SizedBox(height: 30),
          
          // Confirm Password Input
          Text(
            'Confirm Password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 15),
          _buildPasswordDots(_confirmPassword, _passwordLength),
          
          SizedBox(height: 40),
          _buildNumberPad(),
          
          SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSavePassword() ? _savePassword : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Save Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnterPasswordState() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          SizedBox(height: 100),
          Icon(
            Icons.lock,
            color: Color(0xFFFF8C00),
            size: 80,
          ),
          SizedBox(height: 30),
          Text(
            'Enter Password',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 40),
          _buildPasswordDots(_enteredPassword, _passwordLength),
          SizedBox(height: 40),
          _buildNumberPad(),
        ],
      ),
    );
  }
  
  Widget _buildPasswordDots(String password, int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        bool isFilled = index < password.length;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? Color(0xFFFF8C00) : Colors.white.withOpacity(0.2),
            border: Border.all(
              color: isFilled ? Color(0xFFFF8C00) : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
        );
      }),
    );
  }
  
  Widget _buildNumberPad() {
    return Container(
      width: 300,
      child: Column(
        children: [
          // Row 1: 1, 2, 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('1'),
              _buildNumberButton('2'),
              _buildNumberButton('3'),
            ],
          ),
          SizedBox(height: 20),
          // Row 2: 4, 5, 6
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('4'),
              _buildNumberButton('5'),
              _buildNumberButton('6'),
            ],
          ),
          SizedBox(height: 20),
          // Row 3: 7, 8, 9
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNumberButton('7'),
              _buildNumberButton('8'),
              _buildNumberButton('9'),
            ],
          ),
          SizedBox(height: 20),
          // Row 4: Clear, 0, Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton('Clear', Icons.clear),
              _buildNumberButton('0'),
              _buildActionButton('Delete', Icons.backspace),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onNumberPressed(number);
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButton(String action, IconData icon) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (action == 'Clear') {
          _onClearPressed();
        } else if (action == 'Delete') {
          _onDeletePressed();
        }
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white.withOpacity(0.7),
            size: 24,
          ),
        ),
      ),
    );
  }
  
  void _onNumberPressed(String number) {
    setState(() {
      if (_currentState == 1) {
        // Set password state
        if (_password.length < _passwordLength && _confirmPassword.length == 0) {
          _password += number;
        } else if (_confirmPassword.length < _passwordLength) {
          _confirmPassword += number;
        }
      } else if (_currentState == 2) {
        // Enter password state
        if (_enteredPassword.length < _passwordLength) {
          _enteredPassword += number;
          if (_enteredPassword.length == _passwordLength) {
            _verifyPassword();
          }
        }
      }
    });
  }
  
  void _onClearPressed() {
    setState(() {
      if (_currentState == 1) {
        _password = '';
        _confirmPassword = '';
      } else if (_currentState == 2) {
        _enteredPassword = '';
      }
    });
  }
  
  void _onDeletePressed() {
    setState(() {
      if (_currentState == 1) {
        if (_confirmPassword.isNotEmpty) {
          _confirmPassword = _confirmPassword.substring(0, _confirmPassword.length - 1);
        } else if (_password.isNotEmpty) {
          _password = _password.substring(0, _password.length - 1);
        }
      } else if (_currentState == 2) {
        if (_enteredPassword.isNotEmpty) {
          _enteredPassword = _enteredPassword.substring(0, _enteredPassword.length - 1);
        }
      }
    });
  }
  
  bool _canSavePassword() {
    return _password.length == _passwordLength && 
           _confirmPassword.length == _passwordLength && 
           _password == _confirmPassword;
  }
  
  Future<void> _checkLockStatus() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/chat_lock.txt');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        final lines = content.split('\n');
        if (lines.length >= 2) {
          setState(() {
            _isLockEnabled = lines[0] == 'true';
            _passwordLength = int.tryParse(lines[1]) ?? 4;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }
  
  Future<void> _saveLockSettings(bool enabled, String password, int length) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/chat_lock.txt');
      
      final content = '$enabled\n$length\n$password';
      await file.writeAsString(content);
    } catch (e) {
      // Handle error silently
    }
  }
  
  Future<String?> _getSavedPassword() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/chat_lock.txt');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        final lines = content.split('\n');
        if (lines.length >= 3) {
          return lines[2];
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }
  
  void _handleToggleLock() async {
    if (_isLockEnabled) {
      // Turn off - verify password first
      setState(() {
        _currentState = 2;
        _enteredPassword = '';
      });
    } else {
      // Turn on - set password
      setState(() {
        _currentState = 1;
        _password = '';
        _confirmPassword = '';
      });
    }
  }
  
  void _savePassword() async {
    setState(() {
      _isLoading = true;
    });
    
    await _saveLockSettings(true, _password, _passwordLength);
    
    setState(() {
      _isLockEnabled = true;
      _currentState = 0;
      _password = '';
      _confirmPassword = '';
      _isLoading = false;
    });
  }
  
  void _verifyPassword() async {
    final savedPassword = await _getSavedPassword();
    
    if (_enteredPassword == savedPassword) {
      if (widget.directToPasswordEntry) {
        // Password verified, close page
        Navigator.pop(context, true);
      } else {
        // Turn off lock
        await _saveLockSettings(false, '', _passwordLength);
        setState(() {
          _isLockEnabled = false;
          _currentState = 0;
          _enteredPassword = '';
        });
      }
    } else {
      // Wrong password
      setState(() {
        _enteredPassword = '';
      });
      
      // Show error feedback
      HapticFeedback.heavyImpact();
    }
  }
}
