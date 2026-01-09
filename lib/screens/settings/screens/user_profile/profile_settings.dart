import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/handler/supabase.dart';
import '../../../auth/forgot.dart';

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late Animation<double> _headerAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  String? _errorMessage;

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
    
    _headerController.forward();
    _loadUserData();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await SupabaseHandler.getUserByFirebaseUID(user.uid);
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile data';
        _isLoading = false;
      });
    }
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
        body: RefreshIndicator(
          onRefresh: () async => _loadUserData(),
          color: Color(0xFFFF8C00),
          backgroundColor: Color(0xFF1E1E1E),
          child: AnimatedBuilder(
            animation: _headerController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _headerAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: SingleChildScrollView(
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
                          _isLoading
                              ? _buildLoadingState()
                              : _errorMessage != null
                                  ? _buildErrorState()
                                  : _buildContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
              'Profile Settings',
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
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Loading profile...',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadUserData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildProfileCard(),
        SizedBox(height: 40),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildProfileCard() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _userData?['display_name'] ?? user?.displayName ?? 'User';
    final email = _userData?['email'] ?? user?.email ?? '';
    final username = _userData?['username'] ?? '';
    final avatarUrl = _userData?['avatar_url'] ?? user?.photoURL;

    return Column(
      children: [
        // Profile Image
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
              ),
              child: ClipOval(
                child: _buildProfileImage(avatarUrl, displayName),
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        // Display Name
        Text(
          displayName,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        if (username.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(
            '@$username',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ],
        
        SizedBox(height: 8),
        
        // Email
        Text(
          email,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
        
        SizedBox(height: 16),
        
        // Join Date
        if (_userData?['created_at'] != null) ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Joined ${_formatDate(_userData!['created_at'])}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getProfileImagePath(Map<String, dynamic>? userData) {
    String? profileImage = userData?['avatar_url'];
    if (profileImage == null || profileImage.isEmpty) {
      return 'assets/profile/default/default.png';
    }
    
    if (profileImage.startsWith('male') || profileImage.startsWith('female')) {
      String gender = profileImage.startsWith('male') ? 'male' : 'female';
      return 'assets/profile/$gender/$profileImage';
    }
    
    if (profileImage.startsWith('http')) {
      return profileImage; // Network URL
    }
    
    return 'assets/profile/default/default.png';
  }

  Widget _buildProfileImage(String? avatarUrl, String displayName) {
    if (_isLoading) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.3),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF8C00),
            strokeWidth: 2,
          ),
        ),
      );
    }
    
    // Get proper image path
    String imagePath = _getProfileImagePath(_userData);
    
    // Try to load from assets first
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAvatar(displayName);
        },
      );
    }
    
    // Try to load from network (Firebase photo URL)
    if (imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF8C00),
              strokeWidth: 2,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAvatar(displayName);
        },
      );
    }
    
    // Fallback to default avatar
    return _buildFallbackAvatar(displayName);
  }

  Widget _buildFallbackAvatar(String displayName) {
    String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'H';
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }





  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.edit_outlined,
          title: 'Edit Profile',
          onTap: () => _navigateToEditProfile(),
        ),
        Container(
          height: 0.5,
          color: Colors.white.withOpacity(0.1),
        ),
        _buildActionButton(
          icon: Icons.lock_outline,
          title: 'Change Password',
          onTap: () => _navigateToChangePassword(),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white.withOpacity(0.8),
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadUserData();
      }
    });
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return 'Recently';
    }
  }
}

// Edit Profile Screen
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  EditProfileScreen({this.userData});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _displayNameController.text = widget.userData?['display_name'] ?? '';
    _usernameController.text = widget.userData?['username'] ?? '';
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
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[900]?.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[700]!, width: 1),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[400]),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
              
              _buildTextField(
                controller: _displayNameController,
                label: 'Display Name',
                hint: 'Enter your display name',
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Display name is required';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 20),
              
              _buildTextField(
                controller: _usernameController,
                label: 'Username',
                hint: 'Enter your username',
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Username is required';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value!)) {
                    return 'Username can only contain letters, numbers, and underscores';
                  }
                  if (value.length < 3 || value.length > 30) {
                    return 'Username must be 3-30 characters';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          'Update Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2A2A2A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF6C5CE7)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
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
              'Edit Profile',
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
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final result = await SupabaseHandler.upsertUser(
        firebaseUID: user.uid,
        email: user.email!,
        displayName: _displayNameController.text.trim(),
        username: _usernameController.text.trim(),
        avatarUrl: user.photoURL,
      );

      if (result != null) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = 'Failed to update profile';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while updating profile';
        _isLoading = false;
      });
    }
  }
}

// Change Password Screen
class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

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
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[900]?.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[700]!, width: 1),
                          ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[400]),
                  ),
                ),
                SizedBox(height: 20),
              ],
              
              if (_successMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[900]?.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[700]!, width: 1),
                  ),
                  child: Text(
                    _successMessage!,
                    style: TextStyle(color: Colors.green[400]),
                  ),
                ),
                SizedBox(height: 20),
              ],
              
              _buildPasswordField(
                controller: _currentPasswordController,
                label: 'Current Password',
                hint: 'Enter your current password',
                isVisible: _showCurrentPassword,
                onToggleVisibility: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Current password is required';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 20),
              
              _buildPasswordField(
                controller: _newPasswordController,
                label: 'New Password',
                hint: 'Enter your new password',
                isVisible: _showNewPassword,
                onToggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'New password is required';
                  }
                  if (value!.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 20),
              
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                hint: 'Confirm your new password',
                isVisible: _showConfirmPassword,
                onToggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return 'Please confirm your new password';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 8),
              
              // Forgot Password Link
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
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
                      color: Color(0xFF6C5CE7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C5CE7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                          'Change Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: !isVisible,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: Color(0xFF1A1A1A),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[500],
              ),
              onPressed: onToggleVisibility,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2A2A2A)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF2A2A2A)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Color(0xFF6C5CE7)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
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
              'Change Password',
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
    );
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(_newPasswordController.text);

      setState(() {
        _successMessage = 'Password changed successfully';
        _isLoading = false;
      });

      // Clear form
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      // Navigate back after delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to change password';
      
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'New password is too weak';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log in again and try';
          break;
      }

      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while changing password';
        _isLoading = false;
      });
    }
  }
}
