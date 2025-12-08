import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'handler/syncuser_handler.dart';
import '../../errors/no_internet.dart';

class SyncUserPage extends StatefulWidget {
  @override
  _SyncUserPageState createState() => _SyncUserPageState();
}

class _SyncUserPageState extends State<SyncUserPage> with TickerProviderStateMixin {
  late AnimationController _searchController;
  late AnimationController _listController;
  late Animation<double> _searchAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  TextEditingController _searchTextController = TextEditingController();
  Timer? _searchTimer;
  
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;
  bool isSearchMode = false;
  bool hasNetworkError = false;

  @override
  void initState() {
    super.initState();
    _searchController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _listController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _searchAnimation = CurvedAnimation(
      parent: _searchController, 
      curve: Curves.elasticOut,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _listController, 
      curve: Curves.elasticOut,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3), 
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listController, 
      curve: Curves.elasticOut,
    ));
    
    _loadUsers();
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
        setState(() {
          users = List<Map<String, dynamic>>.from(result['users']);
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
    _searchTimer = Timer(Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => filteredUsers = users);
      return;
    }

    try {
      final result = await SyncUserHandler.getAllUsers(searchQuery: query)
          .timeout(Duration(seconds: 5));
      
      if (result['success']) {
        setState(() {
          filteredUsers = List<Map<String, dynamic>>.from(result['users']);
        });
      }
    } catch (e) {
      // Fallback to local search if API fails
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
  }

  void _toggleSearch() {
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
          child: CustomScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildHeader(),
              _buildUserList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      backgroundColor: Color(0xFF121212),
      elevation: 0,
      floating: true,
      pinned: false,
      snap: false,
      expandedHeight: 140,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedBuilder(
                animation: _searchAnimation,
                builder: (context, child) {
                  return Row(
                    children: [
                      if (!isSearchMode) ...[
                        Expanded(
                          child: Transform.translate(
                            offset: Offset(
                              _searchAnimation.value * -100, 
                              0
                            ),
                            child: Opacity(
                              opacity: 1 - _searchAnimation.value,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sync Users',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (isSearchMode) ...[
                        Expanded(
                          child: Transform.translate(
                            offset: Offset(
                              (1 - _searchAnimation.value) * 100, 
                              0
                            ),
                            child: Transform.scale(
                              scale: _searchAnimation.value,
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
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                      ],
                      Transform.scale(
                        scale: isSearchMode ? _searchAnimation.value : 1.0,
                        child: GestureDetector(
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
                      ),
                    ],
                  );
                },
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
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    if (isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF8C00),
          ),
        ),
      );
    }

    if (filteredUsers.isEmpty) {
      return SliverFillRemaining(
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

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildUserCard(filteredUsers[index], index),
            ),
          );
        },
        childCount: filteredUsers.length,
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
          _showComingSoon();
        },
      ),
    );
  }

  void _showComingSoon() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'User profile feature will be available in the next update.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: TextStyle(color: Color(0xFFFF8C00)),
            ),
          ),
        ],
      ),
    );
  }
}
