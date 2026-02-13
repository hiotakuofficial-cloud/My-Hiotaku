import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'handler/syncuser_handler.dart';
import '../../errors/no_internet.dart';
import '../../profile/user_profile/user_profile.dart';
import '../../../services/websocket_service.dart';

class SyncUserPage extends StatefulWidget {
  @override
  _SyncUserPageState createState() => _SyncUserPageState();
}

class _SyncUserPageState extends State<SyncUserPage> with TickerProviderStateMixin {
  late AnimationController _searchController;
  late AnimationController _listController;
  late Animation<double> _searchSlideAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<Offset> _cardSlideAnimation;
  
  TextEditingController _searchTextController = TextEditingController();
  Timer? _searchTimer;
  
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  bool isSearchMode = false;
  bool hasNetworkError = false;
  RealtimeChannel? _presenceChannel;

  @override
  void initState() {
    super.initState();
    _searchController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _listController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _searchSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchController, curve: Curves.easeInOut),
    );
    
    _titleSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _searchController, curve: Curves.easeInOut),
    );
    
    _cardSlideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _listController, curve: Curves.easeOut),
    );
    
    _loadUsers();
    _subscribeToPresenceUpdates();
  }

  // Subscribe to real-time presence updates (optimized)
  void _subscribeToPresenceUpdates() {
    if (!WebSocketService.isReady) {
      // Retry after 2 seconds if not ready
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) _subscribeToPresenceUpdates();
      });
      return;
    }
    
    try {
      _presenceChannel = WebSocketService.subscribeToPresence((presence) {
        // Update user online status in real-time
        setState(() {
          for (var user in users) {
            if (user['firebase_uid'] == presence['firebase_uid']) {
              user['is_online'] = presence['is_online'] ?? false;
              break;
            }
          }
          // Update filtered users too
          for (var user in filteredUsers) {
            if (user['firebase_uid'] == presence['firebase_uid']) {
              user['is_online'] = presence['is_online'] ?? false;
              break;
            }
          }
        });
        
        // Silent update - no toast needed
      });
      
      // Silent subscription - no toast needed
    } catch (e) {
      // Silent error handling - retry after 3 seconds
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) _subscribeToPresenceUpdates();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    _searchTextController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _loadUsers() async {
    setState(() {
      isLoading = true;
      hasNetworkError = false;
    });
    
    try {
      final result = await SyncUserHandler.getAllUsers()
          .timeout(Duration(seconds: 10));
      
      if (result['success']) {
        List<Map<String, dynamic>> loadedUsers = List<Map<String, dynamic>>.from(result['users']);
        
        // Load online status for each user if WebSocket is ready
        if (WebSocketService.isReady) {
          for (var user in loadedUsers) {
            if (user['firebase_uid'] != null) {
              try {
                final isOnline = await WebSocketService.isUserOnline(user['firebase_uid']);
                user['is_online'] = isOnline;
              } catch (e) {
                user['is_online'] = false;
              }
            } else {
              user['is_online'] = false;
            }
          }
        }
        
        setState(() {
          users = loadedUsers;
          filteredUsers = users;
          isLoading = false;
          hasNetworkError = false;
        });
        _listController.forward();
      } else {
        setState(() {
          isLoading = false;
          hasNetworkError = true;
        });
      }
    } on TimeoutException {
      setState(() {
        isLoading = false;
        hasNetworkError = true;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasNetworkError = true;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(Duration(milliseconds: 200), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => filteredUsers = users);
      return;
    }

    // Local search for real-time results
    setState(() {
      filteredUsers = users.where((user) {
        final username = (user['username'] ?? '').toLowerCase();
        final email = (user['email'] ?? '').toLowerCase();
        final displayName = (user['display_name'] ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        
        return username.contains(searchLower) || 
               email.contains(searchLower) ||
               displayName.contains(searchLower);
      }).toList();
    });
  }

  void _toggleSearch() {
    HapticFeedback.lightImpact();
    setState(() => isSearchMode = !isSearchMode);
    
    if (isSearchMode) {
      _searchController.forward();
    } else {
      _searchController.reverse().then((_) {
        _searchTextController.clear();
        setState(() => filteredUsers = users);
      });
    }
  }

  String _getProfileImagePath(Map<String, dynamic> user) {
    String? profileImage = user['avatar_url'];
    if (profileImage == null || profileImage.isEmpty) {
      return 'assets/profile/default/default.png';
    }
    
    if (profileImage.startsWith('male') || profileImage.startsWith('female')) {
      String gender = profileImage.startsWith('male') ? 'male' : 'female';
      return 'assets/profile/$gender/$profileImage';
    }
    
    return 'assets/profile/default/default.png';
  }

  @override
  Widget build(BuildContext context) {
    if (hasNetworkError) {
      return NoInternetScreen(
        onRetry: _loadUsers,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: RefreshIndicator(
          onRefresh: () async => _loadUsers(),
          color: Color(0xFFFF8C00),
          backgroundColor: Color(0xFF1E1E1E),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 20),
                  _buildUserList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _searchController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: isSearchMode 
                    ? FadeTransition(
                        opacity: _searchSlideAnimation,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: TextField(
                            controller: _searchTextController,
                            onChanged: _onSearchChanged,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search users...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            autofocus: true,
                          ),
                        ),
                      )
                    : FadeTransition(
                        opacity: Animation.fromValueListenable(
                          ValueNotifier(1.0 - _searchSlideAnimation.value),
                        ),
                        child: Text(
                          'Sync Users',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                ),
                SizedBox(width: 15),
                GestureDetector(
                  onTap: _toggleSearch,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Icon(
                      isSearchMode ? Icons.close : Icons.search,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Text(
              '${filteredUsers.length} users found',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserList() {
    if (isLoading) {
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

    if (filteredUsers.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_search,
                size: 80,
                color: Colors.white.withOpacity(0.3),
              ),
              SizedBox(height: 20),
              Text(
                'No users found',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        ...List.generate(filteredUsers.length, (index) {
          return SlideTransition(
            position: _cardSlideAnimation,
            child: _buildUserCard(filteredUsers[index], index),
          );
        }),
        SizedBox(height: 10), // Add bottom padding for proper scroll
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: AssetImage(_getProfileImagePath(user)),
              backgroundColor: Color(0xFF2A2A2A),
            ),
            if (user['is_online'] == true)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color(0xFF1E1E1E),
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          user['username'] ?? 'Unknown User',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              user['display_name'] ?? user['email'] ?? '',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  user['is_online'] == true ? Icons.circle : Icons.circle_outlined,
                  size: 12,
                  color: user['is_online'] == true ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 4),
                Text(
                  user['is_online'] == true ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: user['is_online'] == true 
                        ? Colors.green 
                        : Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(
                username: user['username'] ?? 'unknown',
              ),
            ),
          );
        },
      ),
    );
  }
}
