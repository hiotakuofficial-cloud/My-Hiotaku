import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'handler/profile_handler.dart';
import 'requests/requests.dart';
import 'notifications/notification_of_user.dart';
import 'notifications/handler/notification_of_user_handler.dart';
import 'downloads/downloads.dart';
import 'favourite/connected.dart';
import '../settings/settings.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String displayName = 'Hiotaku User';
  String username = '@hiotakuuser';
  String avatarUrl = 'assets/profile/default/default.png';
  String _selectedGender = 'male';
  int _unreadCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUnreadCount();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force reload when coming back to profile
    _loadUserData();
    _loadUnreadCount();
  }
  
  Future<void> _loadUserData() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final data = await ProfileHandler.getCurrentUserData();
      
      if (mounted) {
        setState(() {
          userData = data;
          
          if (data != null) {
            displayName = data['display_name'] ?? 'Hiotaku User';
            username = '@${data['username'] ?? 'hiotakuuser'}';
            
            String? avatarId = data['avatar_url'];
            
            if (avatarId != null && avatarId.isNotEmpty && !avatarId.startsWith('http')) {
              // If avatar_url is just filename (e.g., "male1.png", "female3.png"), construct full path
              if (avatarId.startsWith('male')) {
                avatarUrl = 'assets/profile/male/$avatarId';
                _selectedGender = 'male';
              } else if (avatarId.startsWith('female')) {
                avatarUrl = 'assets/profile/female/$avatarId';
                _selectedGender = 'female';
              } else if (avatarId == 'default.png') {
                avatarUrl = 'assets/profile/default/default.png';
              } else {
                avatarUrl = 'assets/profile/default/default.png';
              }
            } else {
              // Network URL or fallback
              avatarUrl = avatarId ?? 'assets/profile/default/default.png';
            }
          } else {
            // No user data - reset to defaults
            displayName = 'Hiotaku User';
            username = '@hiotakuuser';
            avatarUrl = 'assets/profile/default/default.png';
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userData = null;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationOfUserHandler.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      // Silent fail
    }
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
        body: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.only(bottom: 100),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Notification icon on left
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const NotificationOfUser()),
                            );
                            // Clear red dot when returning from notifications
                            setState(() {
                              _unreadCount = 0;
                            });
                            _loadUnreadCount(); // Refresh actual count
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            child: Stack(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 22,
                                  ),
                                ),
                                if (_unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'My Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsPage(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(Icons.settings_outlined, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                Column(
                  children: [
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
                            child: _buildProfileImage(),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 16),
                    
                    Text(
                      displayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    SizedBox(height: 4),
                    
                    Text(
                      username,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          if (userData == null) {
                            // User not logged in, redirect to login
                            Navigator.pushReplacementNamed(context, '/login');
                          } else {
                            _showAvatarSelectionSheet();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: userData == null 
                                  ? [Colors.blue, Colors.blue.shade700]
                                  : [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            userData == null ? 'Login Now' : 'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 40),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildProfileOption(Icons.chat_outlined, 'Chat'),
                      _buildProfileOption(Icons.person_add_outlined, 'Requests'),
                      _buildProfileOption(Icons.favorite_outline, 'Favourites'),
                      _buildProfileOption(Icons.download_outlined, 'Downloads'),
                      _buildProfileOption(Icons.clear_all_outlined, 'Clear cache'),
                      _buildProfileOption(Icons.logout_outlined, userData == null ? 'Login' : 'Log out', isLogout: true),
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

  void _openAppSettings() async {
    try {
      // Open Android app settings where user can clear data
      const platform = MethodChannel('com.hiotaku.app/settings');
      await platform.invokeMethod('openAppSettings');
    } catch (e) {
      // Fallback - show dialog with instructions
      _showClearCacheDialog();
    }
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear App Data'),
        content: Text('Go to Settings > Apps > Hiotaku > Storage > Clear Data to clear app cache and data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, {bool isLogout = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            if (isLogout) {
              if (userData == null) {
                // User not logged in, redirect to login
                Navigator.pushReplacementNamed(context, '/login');
              } else {
                // User logged in, show logout dialog
                _showLogoutDialog();
              }
            } else {
              if (title == 'Clear cache') {
                _openAppSettings();
              } else if (userData == null) {
                // User not logged in, show login prompt
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please login to access $title'),
                    backgroundColor: Colors.blue,
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Login',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                    ),
                  ),
                );
              } else {
                // Handle specific options
                if (title == 'Clear cache') {
                  _openAppSettings();
                } else if (title == 'Requests') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RequestsPage()),
                  );
                } else if (title == 'Favourites') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ConnectedFavoritesPage()),
                  );
                } else if (title == 'Downloads') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DownloadsScreen()),
                  );
                } else {
                  // Other options - show coming soon
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title - Coming Soon!'),
                      backgroundColor: Color(0xFFFF8C00),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }
          },
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLogout 
                    ? Colors.red.withOpacity(0.1) 
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isLogout ? Colors.red : Colors.white.withOpacity(0.8),
                size: 20,
              ),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isLogout ? Colors.red : Colors.white,
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

  void _showAvatarSelectionSheet() {
    String tempSelectedGender = _selectedGender;
    bool isUpdating = false; // Loading state
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false, // Prevent dismiss during loading
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              SizedBox(height: 20),
              
              Text(
                isUpdating ? 'Updating Avatar...' : 'Choose Avatar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              if (isUpdating) ...[
                SizedBox(height: 20),
                CircularProgressIndicator(
                  color: Color(0xFFFF8C00),
                  strokeWidth: 3,
                ),
                SizedBox(height: 10),
                Text(
                  'Please wait...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
              
              SizedBox(height: 30),
              
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(isUpdating ? 0.05 : 0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isUpdating ? null : () => setModalState(() => tempSelectedGender = 'male'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: tempSelectedGender == 'male' 
                                ? Color(0xFFFF8C00).withOpacity(isUpdating ? 0.5 : 1.0)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Male',
                              style: TextStyle(
                                color: Colors.white.withOpacity(isUpdating ? 0.5 : 1.0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: isUpdating ? null : () => setModalState(() => tempSelectedGender = 'female'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: tempSelectedGender == 'female' 
                                ? Color(0xFFFF8C00).withOpacity(isUpdating ? 0.5 : 1.0)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Female',
                              style: TextStyle(
                                color: Colors.white.withOpacity(isUpdating ? 0.5 : 1.0),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30),
              
              Expanded(
                child: GridView.builder(
                  physics: isUpdating ? NeverScrollableScrollPhysics() : BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    String avatarId = '${tempSelectedGender}${index + 1}.png';
                    String avatarPath = 'assets/profile/$tempSelectedGender/$avatarId';
                    
                    return GestureDetector(
                      onTap: isUpdating ? null : () => _selectAvatar(avatarId, avatarPath, setModalState),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: avatarUrl == avatarPath 
                                ? Color(0xFFFF8C00).withOpacity(isUpdating ? 0.5 : 1.0)
                                : Colors.white.withOpacity(isUpdating ? 0.1 : 0.2),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(isUpdating ? 0.5 : 0.0),
                              BlendMode.darken,
                            ),
                            child: Image.asset(
                              avatarPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.withOpacity(0.3),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white.withOpacity(0.5),
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _selectAvatar(String avatarId, String avatarPath, Function setModalState) async {
    try {
      // Set loading state
      setModalState(() {});
      
      // Show loading toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Updating avatar...'),
            ],
          ),
          duration: Duration(seconds: 10),
          backgroundColor: Color(0xFFFF8C00),
        ),
      );
      
      // Add timeout of 10 seconds
      final success = await Future.any([
        ProfileHandler.updateAvatar(avatarId),
        Future.delayed(Duration(seconds: 10), () => false), // Timeout after 10s
      ]);
      
      if (success && mounted) {
        setState(() {
          avatarUrl = avatarPath;
          _selectedGender = avatarId.contains('male') ? 'male' : 'female';
        });
        
        Navigator.pop(context);
        
        // Clear loading toast
        ScaffoldMessenger.of(context).clearSnackBars();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Avatar updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Clear loading toast
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // Reset loading state
        setModalState(() {});
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Weak network or timeout. Please try again.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _selectAvatar(avatarId, avatarPath, setModalState),
            ),
          ),
        );
      }
    } catch (e) {
      
      // Clear loading toast
      ScaffoldMessenger.of(context).clearSnackBars();
      
      // Reset loading state
      setModalState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Connection error. Check your internet.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildProfileImage() {
    if (isLoading) {
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
    
    // Try to load from assets first
    if (avatarUrl.startsWith('assets/')) {
      return Image.asset(
        avatarUrl,
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAvatar();
        },
      );
    }
    
    // Try to load from network (Firebase photo URL)
    if (avatarUrl.startsWith('http')) {
      return Image.network(
        avatarUrl,
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
          return _buildFallbackAvatar();
        },
      );
    }
    
    // Fallback to default avatar
    return _buildFallbackAvatar();
  }
  
  Widget _buildFallbackAvatar() {
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
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Log Out',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: Colors.white.withOpacity(0.8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await ProfileHandler.logoutUser();
                if (success && mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              child: Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
