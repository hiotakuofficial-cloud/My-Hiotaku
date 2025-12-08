import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'handler/syncuser_handler.dart';

class SyncUserPage extends StatefulWidget {
  @override
  _SyncUserPageState createState() => _SyncUserPageState();
}

class _SyncUserPageState extends State<SyncUserPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _searchController;
  late Animation<double> _searchAnimation;
  late AnimationController _elasticController;
  late Animation<double> _elasticAnimation;
  
  TextEditingController _searchTextController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();
  
  bool _isSearchMode = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  
  @override
  void initState() {
    super.initState();
    
    _searchController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _searchAnimation = CurvedAnimation(
      parent: _searchController,
      curve: Curves.easeInOutCubic,
    );
    
    _elasticController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _elasticAnimation = CurvedAnimation(
      parent: _elasticController,
      curve: Curves.elasticOut,
    );
    
    // Always start elastic animation
    _elasticController.forward();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _elasticController.dispose();
    _searchTextController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
  
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await SyncUserHandler.getAllUsers();
      
      if (result['success']) {
        _allUsers = List<Map<String, dynamic>>.from(result['users'] ?? []);
        _filteredUsers = List.from(_allUsers);
      } else {
        _allUsers = [];
        _filteredUsers = [];
      }
    } catch (e) {
      print('Error loading users: $e');
      _allUsers = [];
      _filteredUsers = [];
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearchMode = !_isSearchMode;
    });
    
    if (_isSearchMode) {
      _searchController.forward();
      Future.delayed(Duration(milliseconds: 200), () {
        _searchFocusNode.requestFocus();
      });
    } else {
      _searchController.reverse();
      _searchFocusNode.unfocus();
      _searchTextController.clear();
      _filteredUsers = List.from(_allUsers);
    }
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user['username'].toLowerCase().contains(query.toLowerCase()) ||
                 user['email'].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
  
  void _onUserTap(Map<String, dynamic> user) {
    HapticFeedback.lightImpact();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ScaleTransition(
        scale: _elasticAnimation,
        child: AlertDialog(
          backgroundColor: Color(0xFF1A1F3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'View Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: AssetImage(_getProfileImagePath(user['profile_image'])),
                backgroundColor: Colors.grey[700],
              ),
              SizedBox(height: 16),
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Profile viewing feature will be available in the next update.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFFFF8C00),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    _elasticController.reset();
    _elasticController.forward();
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
  
  String _getProfileImagePath(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) {
      return 'assets/profile/default/default.png';
    }
    
    if (profileImage.startsWith('http')) {
      return profileImage;
    }
    
    if (profileImage.startsWith('male')) {
      return 'assets/profile/male/$profileImage';
    } else if (profileImage.startsWith('female')) {
      return 'assets/profile/female/$profileImage';
    } else if (profileImage == 'default.png') {
      return 'assets/profile/default/default.png';
    } else {
      return 'assets/profile/default/default.png';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E27),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Color(0xFF0A0E27).withOpacity(0.8),
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.light,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: AnimatedBuilder(
                animation: _searchAnimation,
                builder: (context, child) {
                  return _isSearchMode
                      ? Transform.scale(
                          scale: _searchAnimation.value,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.2)),
                            ),
                            child: TextField(
                              controller: _searchTextController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'Search users...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: Colors.white.withOpacity(0.6),
                                  size: 20,
                                ),
                              ),
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        )
                      : Transform.translate(
                          offset: Offset(
                            (1 - _searchAnimation.value) * 0,
                            0,
                          ),
                          child: Opacity(
                            opacity: 1 - _searchAnimation.value,
                            child: Text(
                              'Sync Users',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                },
              ),
              actions: [
                AnimatedBuilder(
                  animation: _searchAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _searchAnimation.value * 0.5,
                      child: IconButton(
                        icon: Icon(
                          _isSearchMode ? Icons.close : Icons.search,
                          color: Colors.white,
                        ),
                        onPressed: _toggleSearch,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _elasticAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.8 + (_elasticAnimation.value * 0.2),
            child: Opacity(
              opacity: _elasticAnimation.value,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
                      ),
                    )
                  : CustomScrollView(
                      physics: BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: SizedBox(height: kToolbarHeight + 20),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recommended Users',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Connect with other anime enthusiasts',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                                SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                        _filteredUsers.isEmpty
                            ? SliverToBoxAdapter(
                                child: Container(
                                  height: 300,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 80,
                                          color: Colors.white30,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No users found',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white60,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Try adjusting your search or check back later',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.4),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final user = _filteredUsers[index];
                                    return Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF1A1F3A),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => _onUserTap(user),
                                          borderRadius: BorderRadius.circular(16),
                                          child: Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Row(
                                              children: [
                                                Stack(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 28,
                                                      backgroundImage: AssetImage(
                                                        _getProfileImagePath(user['profile_image']),
                                                      ),
                                                      backgroundColor: Colors.grey[700],
                                                    ),
                                                    if (user['is_online'] == true)
                                                      Positioned(
                                                        bottom: 2,
                                                        right: 2,
                                                        child: Container(
                                                          width: 14,
                                                          height: 14,
                                                          decoration: BoxDecoration(
                                                            color: Colors.green,
                                                            shape: BoxShape.circle,
                                                            border: Border.all(
                                                              color: Color(0xFF1A1F3A),
                                                              width: 2,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        user['username'] ?? 'Unknown User',
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        user['email'] ?? 'No email',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                      SizedBox(height: 4),
                                                      Text(
                                                        'Joined ${_formatDate(user['created_at'])}',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.white60,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: Colors.white.withOpacity(0.4),
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  childCount: _filteredUsers.length,
                                ),
                              ),
                        SliverToBoxAdapter(
                          child: SizedBox(height: 40),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}
