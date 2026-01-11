import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../handler/chat_handler.dart';
import '../components/button_nav.dart';
import '../widgets/chat_state_widgets.dart';
import '../widgets/no_internet_widget.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _elasticController;
  late AnimationController _listController;
  late Animation<double> _elasticAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  List<Map<String, dynamic>> _chatRooms = [];
  
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasInternet = true;
  String _searchQuery = '';
  int _currentNavIndex = 1; // Default to Chats tab

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  void _initAnimations() {
    _elasticController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _listController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _elasticAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(
          parent: _elasticController,
          curve: Curves.elasticOut,
        ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
          parent: _listController,
          curve: Curves.easeOut,
        ));
  }

  @override
  void dispose() {
    _elasticController.dispose();
    _listController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _hasInternet = true;
      });

      // Simulate loading all users (replace with actual API call)
      await Future.delayed(Duration(milliseconds: 800));
      
      // Load chat rooms
      final rooms = await ChatHandler.getUserChatRooms();
      
      // Mock users data (replace with actual user fetching)
      final mockUsers = _generateMockUsers();
      
      if (mounted) {
        setState(() {
          _chatRooms = rooms;
          _allUsers = mockUsers;
          _filteredUsers = mockUsers;
          _isLoading = false;
        });
        
        _elasticController.forward();
        _listController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _hasInternet = e.toString().contains('network') ? false : true;
        });
      }
    }
  }

  List<Map<String, dynamic>> _generateMockUsers() {
    return [
      {
        'id': '1',
        'username': 'anime_lover',
        'display_name': 'Anime Lover',
        'avatar_url': 'assets/profile/male/male1.png',
        'is_online': true,
        'last_seen': DateTime.now().subtract(Duration(minutes: 2)),
      },
      {
        'id': '2',
        'username': 'otaku_girl',
        'display_name': 'Otaku Girl',
        'avatar_url': 'assets/profile/female/female1.png',
        'is_online': false,
        'last_seen': DateTime.now().subtract(Duration(hours: 1)),
      },
      {
        'id': '3',
        'username': 'manga_reader',
        'display_name': 'Manga Reader',
        'avatar_url': 'assets/profile/male/male2.png',
        'is_online': true,
        'last_seen': DateTime.now(),
      },
      {
        'id': '4',
        'username': 'hisu_bot',
        'display_name': 'Hisu Assistant',
        'avatar_url': 'assets/profile/chat/icons/hisu.png',
        'is_online': true,
        'last_seen': DateTime.now(),
        'is_bot': true,
      },
    ];
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _allUsers;
      } else {
        _filteredUsers = _allUsers.where((user) {
          return user['username'].toLowerCase().contains(query) ||
                 user['display_name'].toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    _elasticController.reset();
    _listController.reset();
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
      bottomNavigationBar: ChatBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _elasticAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _elasticAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF21CBF3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.forum_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hiotaku Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_allUsers.length} users online',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onRefresh,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return AnimatedBuilder(
      animation: _elasticAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _elasticAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search users...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.5),
                  size: 20,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _searchController.clear();
                            HapticFeedback.lightImpact();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Icon(
                            Icons.clear_rounded,
                            color: Colors.white.withOpacity(0.5),
                            size: 18,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (!_hasInternet) {
      return NoInternetWidget(onRetry: _onRefresh);
    }
    
    if (_isLoading) {
      return ChatLoadingWidget(message: 'Loading users...');
    }
    
    if (_hasError) {
      return ChatErrorWidget(
        title: 'Failed to Load',
        message: 'Could not load chat users',
        onRetry: _onRefresh,
      );
    }
    
    if (_filteredUsers.isEmpty) {
      return ChatEmptyWidget(
        title: _searchQuery.isEmpty ? 'No Users Found' : 'No Search Results',
        subtitle: _searchQuery.isEmpty 
            ? 'No users are available for chat'
            : 'Try searching with different keywords',
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: Color(0xFF2196F3),
      backgroundColor: Color(0xFF1E1E1E),
      child: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ListView.builder(
                controller: _scrollController,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  return _buildUserCard(_filteredUsers[index], index);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final isOnline = user['is_online'] ?? false;
    final isBot = user['is_bot'] ?? false;
    
    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _listController.value) * 50 * (index + 1)),
          child: Opacity(
            opacity: _listController.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _startChat(user);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isBot 
                            ? Color(0xFF6C5CE7).withOpacity(0.3)
                            : Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isBot 
                                      ? Color(0xFF6C5CE7).withOpacity(0.5)
                                      : Colors.white.withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  user['avatar_url'] ?? 'assets/profile/default/default.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Color(0xFF2A2A2A),
                                      child: Icon(
                                        Icons.person_rounded,
                                        color: Colors.white.withOpacity(0.5),
                                        size: 24,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (isOnline)
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isBot ? Color(0xFF6C5CE7) : Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFF1A1A1A),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      user['display_name'] ?? 'Unknown User',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isBot)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF6C5CE7).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'BOT',
                                        style: TextStyle(
                                          color: Color(0xFF6C5CE7),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                '@${user['username'] ?? 'unknown'}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                isOnline ? 'Online' : _getLastSeenText(user['last_seen']),
                                style: TextStyle(
                                  color: isOnline 
                                      ? (isBot ? Color(0xFF6C5CE7) : Color(0xFF4CAF50))
                                      : Colors.white.withOpacity(0.4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white.withOpacity(0.4),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getLastSeenText(DateTime? lastSeen) {
    if (lastSeen == null) return 'Last seen unknown';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  void _startChat(Map<String, dynamic> user) {
    // TODO: Navigate to individual chat screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting chat with ${user['display_name']}'),
        backgroundColor: Color(0xFF2196F3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
