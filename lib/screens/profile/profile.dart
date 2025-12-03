import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'handler/profile_handler.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // TODO: User data state
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String displayName = 'Hiotaku User';
  String username = '@hiotakuuser';
  String avatarUrl = 'assets/profile/default/default.png';
  String _selectedGender = 'male'; // TODO: Gender selection state
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Force reload when coming back to profile
    _loadUserData();
  }
  
  // TODO: Load user data from Supabase
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
            
            // TODO: Handle avatar ID from Supabase
            String? avatarId = data['avatar_url'];
            
            // DEBUG: Show what we got from DB
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('DB Avatar: $avatarId'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.purple,
              ),
            );
            
            if (avatarId != null && avatarId.isNotEmpty && !avatarId.startsWith('http')) {
              // If avatar_url is just filename (e.g., "male1.png", "female3.png"), construct full path
              if (avatarId.contains('male')) {
                avatarUrl = 'assets/profile/male/$avatarId';
                _selectedGender = 'male';
              } else if (avatarId.contains('female')) {
                avatarUrl = 'assets/profile/female/$avatarId';
                _selectedGender = 'female';
              } else if (avatarId == 'default.png') {
                avatarUrl = 'assets/profile/default/default.png';
              } else {
                avatarUrl = 'assets/profile/default/default.png';
              }
              
              // DEBUG: Show constructed path
              Future.delayed(Duration(milliseconds: 500), () {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Constructed: $avatarUrl'),
                      duration: Duration(seconds: 2),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              });
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
      print('Load user data error: $e');
      if (mounted) {
        setState(() {
          userData = null;
          isLoading = false;
        });
      }
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
            padding: EdgeInsets.only(bottom: 100), // TODO: Bottom nav padding
            child: Column(
              children: [
                // TODO: Header section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 48),
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
                          onTap: () {},
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
                
                // TODO: Profile avatar section
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
                          // TODO: Check if user is logged in
                          if (userData == null) {
                            // User not logged in, redirect to login
                            Navigator.pushReplacementNamed(context, '/login');
                          } else {
                            // TODO: User logged in, show avatar selection
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
                
                // TODO: Profile options list
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildProfileOption(Icons.favorite_outline, 'Favourites'),
                      _buildProfileOption(Icons.sync_outlined, 'Sync Account'),
                      _buildProfileOption(Icons.person_add_outlined, 'Requests'),
                      _buildProfileOption(Icons.chat_outlined, 'Chat'),
                      _buildProfileOption(Icons.clear_all_outlined, 'Clear cache'),
                      _buildProfileOption(Icons.history_outlined, 'Clear history'),
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
              // TODO: Handle other options
              if (userData == null) {
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
                // User logged in, show coming soon
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title - Coming Soon!'),
                    backgroundColor: Color(0xFFFF8C00),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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

  // TODO: Show avatar selection bottom sheet
  void _showAvatarSelectionSheet() {
    String tempSelectedGender = _selectedGender;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // TODO: Handle bar
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
                'Choose Avatar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              SizedBox(height: 30),
              
              // TODO: Gender toggle
              Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => tempSelectedGender = 'male'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: tempSelectedGender == 'male' 
                                ? Color(0xFFFF8C00) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Male',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => tempSelectedGender = 'female'),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: tempSelectedGender == 'female' 
                                ? Color(0xFFFF8C00) 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Female',
                              style: TextStyle(
                                color: Colors.white,
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
              
              // TODO: Avatar grid
              Expanded(
                child: GridView.builder(
                  physics: BouncingScrollPhysics(), // Added elastic physics
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: 12, // Updated to show 12 images
                  itemBuilder: (context, index) {
                    String avatarId = '${tempSelectedGender}${index + 1}.png';
                    String avatarPath = 'assets/profile/$tempSelectedGender/$avatarId';
                    
                    return GestureDetector(
                      onTap: () => _selectAvatar(avatarId, avatarPath),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: avatarUrl == avatarPath 
                                ? Color(0xFFFF8C00) 
                                : Colors.white.withOpacity(0.2),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
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
  
  // TODO: Select avatar and save to Supabase
  Future<void> _selectAvatar(String avatarId, String avatarPath) async {
    try {
      // DEBUG: Show what we're trying to save
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saving: $avatarId'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );
      
      final success = await ProfileHandler.updateAvatar(avatarId);
      
      if (success && mounted) {
        setState(() {
          avatarUrl = avatarPath;
          _selectedGender = avatarId.contains('male') ? 'male' : 'female';
        });
        
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Color(0xFFFF8C00),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // DEBUG: Show what was saved
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved: $avatarId, Path: $avatarPath'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar - Check connection'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Select avatar error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // TODO: Build profile image with fallback handling
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
  
  // TODO: Fallback avatar with user initial
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
                // TODO: Use ProfileHandler for logout
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
