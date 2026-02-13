import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'handler/user_profile_handler.dart';
import '../../errors/no_internet.dart';
import '../../../components/details_sheet.dart';
import '../../auth/handler/supabase.dart';
import '../../../services/notification_service.dart';
import '../requests/handler/requests_handler.dart';
import '../../../services/websocket_service.dart';

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
  bool isUserOnline = false;
  RealtimeChannel? _presenceChannel;
  String syncStatus = 'none'; // none, requested, connected
  bool isSyncButtonLoading = false; // Track sync button loading state

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
      // Run all queries in parallel for better performance
      final results = await Future.wait([
        UserProfileHandler.getUserProfile(widget.username),
        UserProfileHandler.getUserFavorites(widget.username),
        UserProfileHandler.getUserSyncedAccounts(widget.username),
      ]).timeout(Duration(seconds: 15)); // Reduced timeout
      
      final profileResult = results[0];
      final favoritesResult = results[1];
      final syncedResult = results[2];
      
      if (profileResult['success']) {
        setState(() {
          userProfile = profileResult['user'];
          userFavorites = favoritesResult['success'] == true ? 
              List<Map<String, dynamic>>.from(favoritesResult['favorites'] ?? []) : [];
          syncedAccounts = syncedResult['success'] == true ? 
              List<Map<String, dynamic>>.from(syncedResult['synced_accounts'] ?? []) : [];
          hasNetworkError = false;
          
          // Check if current user after profile loads
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && userProfile != null) {
            String currentUserIdentifier = currentUser.email ?? currentUser.uid;
            String profileUserIdentifier = userProfile!['email'] ?? userProfile!['id'];
            isCurrentUser = currentUserIdentifier == profileUserIdentifier;
          } else {
            isCurrentUser = false;
          }
        });

        // Set loading false AFTER all data is loaded
        setState(() {
          isLoading = false;
        });

        // Check sync status separately if not current user
        if (!isCurrentUser) {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null && userProfile != null) {
            try {
              // Get current user's Supabase ID
              final currentUserData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
              if (currentUserData != null) {
                final status = await SupabaseHandler.getSyncStatus(
                  currentUserId: currentUserData['id'],
                  targetUserId: userProfile!['id'],
                );
                setState(() {
                  syncStatus = status;
                });
              }
            } catch (e) {
            }
          }
        }
        _animationController.forward();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile. Please try again.'),
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
          content: Text('Something went wrong. Please try again.'),
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
              color: Colors.white.withOpacity(0.8),
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
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.transparent,
                  width: 3,
                ),
              ),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundImage: AssetImage(_getProfileImagePath(userProfile!['avatar_url'])),
                    backgroundColor: Color(0xFF2A2A2A),
                  ),
                  if (isUserOnline)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFF121212),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
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
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
        SizedBox(height: 12),
        // Remove online status badge completely
        SizedBox.shrink(),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Public Saved', userProfile!['public_favorites_count'].toString()),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
          _buildStatItem('Synced With', userProfile!['synced_accounts_count'].toString()),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
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
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Color _getSyncButtonColor() {
    if (isCurrentUser) return Color(0xFF121212);
    switch (syncStatus) {
      case 'requested':
      case 'connected':
        return Color(0xFF121212);
      default:
        return Color(0xFFFF8C00);
    }
  }

  String _getSyncButtonText() {
    switch (syncStatus) {
      case 'requested':
        return 'Requested';
      case 'connected':
        return 'Connected';
      default:
        return 'Request Sync';
    }
  }

  IconData _getSyncButtonIcon() {
    switch (syncStatus) {
      case 'requested':
        return Icons.schedule;
      case 'connected':
        return Icons.link;
      default:
        return Icons.sync_rounded;
    }
  }

  void _handleSyncAction() async {
    HapticFeedback.lightImpact();
    
    if (syncStatus == 'connected') {
      _showDisconnectDialog();
    } else if (syncStatus == 'none') {
      // Check if user has reached sync limit
      if (userProfile != null && userProfile!['synced_accounts_count'] >= 2) {
        _showSyncLimitDialog();
        return;
      }
      await _sendSyncRequest();
    }
    // Do nothing if status is 'requested'
  }

  Future<void> _sendSyncRequest() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || userProfile == null) return;

    setState(() => isSyncButtonLoading = true);

    try {
      // Get current user's Supabase ID
      final currentUserData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (currentUserData == null) {
        throw Exception('Current user not found in database');
      }

      final success = await SupabaseHandler.sendSyncRequest(
        senderId: currentUserData['id'],
        receiverId: userProfile!['id'],
        senderUsername: currentUserData['username'] ?? currentUser.displayName ?? 'Unknown',
      );

      if (success) {
        setState(() {
          syncStatus = 'requested';
          isSyncButtonLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync request sent successfully!'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => isSyncButtonLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync request already exists or failed'),
            backgroundColor: Color(0xFFFF9800),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => isSyncButtonLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request failed. Please try again.'),
          backgroundColor: Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSyncLimitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sync Limit Reached', style: TextStyle(color: Colors.white)),
        content: Text(
          'This user has already reached the maximum sync limit of 2 accounts.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Color(0xFFFF8C00))),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Disconnect', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to disconnect? This will remove the connection and shared favorites between you and ${userProfile!['username'] ?? 'this user'}.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _disconnectSync();
            },
            child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnectSync() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || userProfile == null) return;

    setState(() => isSyncButtonLoading = true);

    try {
      // Get current user's Supabase data
      final currentUserData = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      if (currentUserData == null) {
        throw Exception('Current user not found in database');
      }

      // Find the merge request between these users
      final requests = await SupabaseHandler.getData(
        table: 'merge_requests',
        filters: {},
      );

      String? requestId;
      if (requests != null) {
        for (final request in requests) {
          final senderId = request['sender_id'].toString();
          final receiverId = request['receiver_id'].toString();
          final currentUserId = currentUserData['id'].toString();
          final targetUserId = userProfile!['id'].toString();
          
          if ((senderId == currentUserId && receiverId == targetUserId) ||
              (senderId == targetUserId && receiverId == currentUserId)) {
            requestId = request['id'].toString();
            break;
          }
        }
      }

      bool success = false;
      if (requestId != null) {
        // Use the same disconnect function as requests page (with notifications)
        success = await RequestsHandler.disconnectUsers(requestId);
      } else {
        // Fallback to basic disconnect if no request found
        success = await SupabaseHandler.disconnectSync(
          userId1: currentUser.uid,
          userId2: userProfile!['firebase_uid'] ?? userProfile!['id'],
        );
      }

      if (success) {
        setState(() {
          syncStatus = 'none';
          isSyncButtonLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully disconnected'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => isSyncButtonLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to disconnect. Please try again.'),
            backgroundColor: Color(0xFFFF5252),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect'),
          backgroundColor: Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
                border: Border.all(color: Colors.white.withOpacity(0.2)),
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
            onTap: (isCurrentUser || isSyncButtonLoading) ? null : () => _handleSyncAction(),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _getSyncButtonColor(),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isCurrentUser) ...[
                    Text(
                      'You',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    if (isSyncButtonLoading) ...[
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Lottie.asset(
                          'assets/animations/loading.json',
                          width: 20,
                          height: 20,
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        _getSyncButtonText(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      Icon(_getSyncButtonIcon(), color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        _getSyncButtonText(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
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
            border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                        color: Colors.white.withOpacity(0.7), 
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
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 60,
                  color: Colors.white.withOpacity(0.3),
                ),
                SizedBox(height: 20),
                Text(
                  'No public saved anime yet',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
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
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                                Colors.black.withOpacity(0.9),
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
                  color: Color(0xFFFF8C00).withOpacity(0.2),
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
