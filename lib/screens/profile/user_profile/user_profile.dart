import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'handler/user_profile_handler.dart';
import '../../errors/no_internet.dart';
import '../../../components/details_sheet.dart';

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
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1), 
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController, 
      curve: Curves.easeOut,
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
    // This will be called when profile data loads
  }

  void _loadUserProfile() async {
    setState(() {
      isLoading = true;
      hasNetworkError = false;
    });
    
    try {
      final profileResult = await UserProfileHandler.getUserProfile(widget.username)
          .timeout(Duration(seconds: 30));
      
      if (profileResult['success']) {
        final favoritesResult = await UserProfileHandler.getUserFavorites(widget.username);
        final syncedResult = await UserProfileHandler.getUserSyncedAccounts(widget.username);
        
        setState(() {
          userProfile = profileResult['user'];
          userFavorites = favoritesResult['success'] == true ? 
              List<Map<String, dynamic>>.from(favoritesResult['favorites'] ?? []) : [];
          syncedAccounts = syncedResult['success'] == true ? 
              List<Map<String, dynamic>>.from(syncedResult['synced_accounts'] ?? []) : [];
          isLoading = false;
          hasNetworkError = false;
          
          // Check if current user after profile loads
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && currentUser.displayName != null) {
            isCurrentUser = currentUser.displayName!.toLowerCase() == widget.username.toLowerCase();
          } else {
            isCurrentUser = false;
          }
        });
        _animationController.forward();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile load failed: ${profileResult['message']}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          isLoading = false;
          // Don't set network error for API failures, just show error message
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        isLoading = false;
        // Only set network error for timeout/connection issues
        hasNetworkError = e.toString().contains('timeout') || e.toString().contains('SocketException');
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

  // Remove unused _syncWithUser method since it's not being used

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
            physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 20),
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
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white.withValues(alpha: 0.8),
              size: 24,
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(
              '@${widget.username}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(width: 40),
      ],
    );
  }

  Widget _buildLoading() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Lottie.asset(
          'assets/animations/loading.json',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
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
              Icon(Icons.person_off, size: 80, color: Colors.white.withValues(alpha: 0.3)),
              SizedBox(height: 20),
              Text(
                'User not found',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18),
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
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: userProfile!['is_online'] == true ? Colors.green : Colors.transparent,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: 65,
                backgroundImage: AssetImage(_getProfileImagePath(userProfile!['avatar_url'])),
                backgroundColor: Color(0xFF2A2A2A),
              ),
            ),
            if (userProfile!['is_online'] == true)
              Positioned(
                bottom: 8,
                right: 8,
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
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '@${userProfile!['username']}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: userProfile!['is_online'] == true 
                ? Colors.green.withValues(alpha: 0.2) 
                : Colors.grey.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: userProfile!['is_online'] == true ? Colors.green : Colors.grey,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: userProfile!['is_online'] == true ? Colors.green : Colors.grey,
              ),
              SizedBox(width: 6),
              Text(
                userProfile!['is_online'] == true ? 'Online' : 'Offline',
                style: TextStyle(
                  color: userProfile!['is_online'] == true ? Colors.green : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Public Saved', userProfile!['public_favorites_count'].toString()),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
          _buildStatItem('Synced With', userProfile!['synced_accounts_count'].toString()),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.1)),
          _buildStatItem('Max Sync', '2'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message feature coming soon!'),
                  backgroundColor: Color(0xFFFF8C00),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.message_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
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
            onTap: isCurrentUser ? null : () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Request Sync feature coming soon!'),
                  backgroundColor: Color(0xFFFF8C00),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isCurrentUser ? Color(0xFF1E1E1E).withValues(alpha: 0.5) : Color(0xFFFF8C00),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sync_rounded, 
                    color: isCurrentUser ? Colors.white.withValues(alpha: 0.3) : Colors.white, 
                    size: 20
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Request Sync',
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white.withValues(alpha: 0.3) : Colors.white,
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 15),
        ...syncedAccounts.map((account) => Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
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
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '@${account['username']}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7), 
                        fontSize: 13,
                      ),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 60,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                SizedBox(height: 20),
                Text(
                  'No public saved anime yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 16,
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.7,
          ),
          itemCount: userFavorites.length > 9 ? 9 : userFavorites.length,
          itemBuilder: (context, index) {
            final favorite = userFavorites[index];
            return GestureDetector(
              onTap: () {
                // Show details sheet with anime data
                HapticFeedback.lightImpact();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DetailsSheet(
                    animeId: favorite['anime_id'] ?? '',
                    animeType: favorite['anime_type'] ?? 'sub',
                    title: favorite['anime_title'],
                    poster: favorite['anime_image'],
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      favorite['anime_image'] != null && favorite['anime_image'].isNotEmpty
                        ? Image.network(
                            favorite['anime_image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Color(0xFF2A2A2A),
                              child: Icon(
                                Icons.movie_rounded,
                                color: Colors.white54,
                                size: 35,
                              ),
                            ),
                          )
                        : Container(
                            color: Color(0xFF2A2A2A),
                            child: Icon(
                              Icons.movie_rounded,
                              color: Colors.white54,
                              size: 35,
                            ),
                          ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Text(
                            favorite['anime_title'] ?? 'Unknown',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
              ),
            );
          },
        ),
        if (userFavorites.length > 9)
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFFF8C00).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Color(0xFFFF8C00)),
                ),
                child: Text(
                  '+${userFavorites.length - 9} more anime',
                  style: TextStyle(
                    color: Color(0xFFFF8C00),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
