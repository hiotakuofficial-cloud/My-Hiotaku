import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'handler/user_profile_handler.dart';
import '../../errors/no_internet.dart';

class UserProfilePage extends StatefulWidget {
  final String username;
  
  const UserProfilePage({Key? key, required this.username}) : super(key: key);
  
  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Map<String, dynamic>? userProfile;
  List<Map<String, dynamic>> userFavorites = [];
  List<Map<String, dynamic>> syncedAccounts = [];
  bool isLoading = true;
  bool hasNetworkError = false;
  bool isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3), 
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController, 
      curve: Curves.elasticOut,
    ));
    
    _checkCurrentUser();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkCurrentUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    // You'd need to get current user's username from your user data
    // For now, just checking if logged in
    isCurrentUser = currentUser != null;
  }

  void _loadUserProfile() async {
    setState(() {
      isLoading = true;
      hasNetworkError = false;
    });
    
    try {
      final profileResult = await UserProfileHandler.getUserProfile(widget.username)
          .timeout(Duration(seconds: 10));
      
      if (profileResult['success']) {
        final favoritesResult = await UserProfileHandler.getUserFavorites(widget.username);
        final syncedResult = await UserProfileHandler.getUserSyncedAccounts(widget.username);
        
        setState(() {
          userProfile = profileResult['user'];
          userFavorites = favoritesResult['success'] ? 
              List<Map<String, dynamic>>.from(favoritesResult['favorites']) : [];
          syncedAccounts = syncedResult['success'] ? 
              List<Map<String, dynamic>>.from(syncedResult['synced_accounts']) : [];
          isLoading = false;
          hasNetworkError = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          isLoading = false;
          hasNetworkError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasNetworkError = true;
      });
    }
  }

  String _getProfileImagePath(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return 'assets/profile/default/default.png';
    }
    
    if (avatarUrl.startsWith('male') || avatarUrl.startsWith('female')) {
      String gender = avatarUrl.startsWith('male') ? 'male' : 'female';
      return 'assets/profile/$gender/$avatarUrl';
    }
    
    return 'assets/profile/default/default.png';
  }

  void _syncWithUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to sync accounts'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Row(
          children: [
            CircularProgressIndicator(color: Color(0xFFFF8C00)),
            SizedBox(width: 20),
            Text('Syncing account...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    try {
      final result = await UserProfileHandler.syncWithUser(
        currentUserId: currentUser.uid,
        targetUsername: widget.username,
      );

      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (result['success']) {
        _loadUserProfile(); // Refresh data
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync account'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hasNetworkError) {
      return NoInternetScreen(onRetry: _loadUserProfile);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: RefreshIndicator(
          onRefresh: () async => _loadUserProfile(),
          color: Color(0xFFFF8C00),
          backgroundColor: Color(0xFF1E1E1E),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 30),
                  if (isLoading) _buildLoading() else _buildProfileContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(Icons.arrow_back, color: Colors.white.withOpacity(0.8)),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              '@${widget.username}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 45),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (userProfile == null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: Colors.white.withOpacity(0.3)),
              SizedBox(height: 20),
              Text(
                'User not found',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: 30),
            _buildStatsRow(),
            SizedBox(height: 30),
            if (!isCurrentUser) _buildActionButtons(),
            SizedBox(height: 20),
            _buildSyncedAccounts(),
            SizedBox(height: 30),
            _buildFavorites(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage(_getProfileImagePath(userProfile!['avatar_url'])),
              backgroundColor: Color(0xFF2A2A2A),
            ),
            if (userProfile!['is_online'] == true)
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Color(0xFF121212), width: 3),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 20),
        Text(
          userProfile!['display_name'] ?? 'Unknown User',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          '@${userProfile!['username']}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              userProfile!['is_online'] == true ? Icons.circle : Icons.circle_outlined,
              size: 12,
              color: userProfile!['is_online'] == true ? Colors.green : Colors.grey,
            ),
            SizedBox(width: 5),
            Text(
              userProfile!['is_online'] == true ? 'Online' : 'Offline',
              style: TextStyle(
                color: userProfile!['is_online'] == true ? Colors.green : Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Public Favorites', userProfile!['public_favorites_count'].toString()),
        _buildStatItem('Synced Accounts', userProfile!['synced_accounts_count'].toString()),
        _buildStatItem('Max Sync', '2'),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    bool canSync = userProfile!['can_sync'] == true;
    
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message feature coming soon!'),
                  backgroundColor: Color(0xFFFF8C00),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 15),
        Expanded(
          child: GestureDetector(
            onTap: canSync ? _syncWithUser : null,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: canSync ? Color(0xFFFF8C00) : Colors.grey,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    canSync ? 'Sync' : 'Limit Reached',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncedAccounts() {
    if (syncedAccounts.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synced Accounts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15),
        ...syncedAccounts.map((account) => Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(_getProfileImagePath(account['avatar_url'])),
                backgroundColor: Color(0xFF2A2A2A),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account['display_name'] ?? 'Unknown',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '@${account['username']}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildFavorites() {
    if (userFavorites.isEmpty) {
      return Column(
        children: [
          Text(
            'Public Saved',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 50,
                  color: Colors.white.withOpacity(0.3),
                ),
                SizedBox(height: 15),
                Text(
                  'No public saved anime yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Public Saved (${userFavorites.length})',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemCount: userFavorites.length > 9 ? 9 : userFavorites.length,
          itemBuilder: (context, index) {
            final favorite = userFavorites[index];
            return Container(
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    favorite['anime_poster'] != null && favorite['anime_poster'].isNotEmpty
                      ? Image.network(
                          favorite['anime_poster'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Color(0xFF2A2A2A),
                            child: Icon(
                              Icons.movie,
                              color: Colors.white54,
                              size: 30,
                            ),
                          ),
                        )
                      : Container(
                          color: Color(0xFF2A2A2A),
                          child: Icon(
                            Icons.movie,
                            color: Colors.white54,
                            size: 30,
                          ),
                        ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          favorite['anime_title'] ?? 'Unknown',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (userFavorites.length > 9)
          Padding(
            padding: EdgeInsets.only(top: 15),
            child: Center(
              child: Text(
                '+${userFavorites.length - 9} more anime',
                style: TextStyle(
                  color: Color(0xFFFF8C00),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
