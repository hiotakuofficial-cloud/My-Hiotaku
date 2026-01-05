import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../../favourite/handler/favourite_handler.dart';
import '../../errors/no_internet.dart';
import '../../errors/loading_error.dart';
import '../../details/details.dart';
import '../../favourite/syncuser/syncuser.dart';
import '../../player/player/player.dart';
import '../../auth/handler/supabase.dart';

class ConnectedFavoritesPage extends StatefulWidget {
  @override
  _ConnectedFavoritesPageState createState() => _ConnectedFavoritesPageState();
}

class _ConnectedFavoritesPageState extends State<ConnectedFavoritesPage> 
    with TickerProviderStateMixin {
  
  late AnimationController _searchController;
  late AnimationController _listController;
  late Animation<double> _searchSlideAnimation;
  late Animation<Offset> _cardSlideAnimation;
  
  TextEditingController _searchTextController = TextEditingController();
  Timer? _searchTimer;
  
  List<Map<String, dynamic>> connectedFavorites = [];
  List<Map<String, dynamic>> filteredFavorites = [];
  bool isLoading = true;
  bool isSearchMode = false;
  bool hasNetworkError = false;
  bool hasLoadingError = false;
  bool isAuthenticated = true;
  String? selectedAnimeId;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkAuthAndLoad();
  }

  void _initAnimations() {
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
    
    _cardSlideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _listController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    _searchTextController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthAndLoad() async {
    // Check if user is authenticated
    if (FirebaseAuth.instance.currentUser?.uid == null) {
      setState(() {
        isAuthenticated = false;
        isLoading = false;
      });
      return;
    }
    
    await _loadConnectedFavorites();
  }

  Future<void> _loadConnectedFavorites() async {
    setState(() {
      isLoading = true;
      hasNetworkError = false;
      hasLoadingError = false;
      errorMessage = null;
    });
    
    try {
      final favorites = await FavouriteHandler.getConnectedFavorites()
          .timeout(Duration(seconds: 15));
      
      setState(() {
        connectedFavorites = favorites;
        filteredFavorites = favorites;
        isLoading = false;
        hasNetworkError = false;
        hasLoadingError = false;
      });
      _listController.forward();
    } on TimeoutException {
      setState(() {
        isLoading = false;
        hasNetworkError = true;
        errorMessage = 'Connection timeout. Please check your internet connection.';
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasLoadingError = true;
        errorMessage = 'Failed to load connected favorites. Please try again.';
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
      setState(() => filteredFavorites = connectedFavorites);
      return;
    }

    setState(() {
      filteredFavorites = connectedFavorites.where((fav) {
        final title = (fav['anime_title'] ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        return title.contains(searchLower);
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
        setState(() => filteredFavorites = connectedFavorites);
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

  String _maskEmail(String email) {
    if (email.length <= 4) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    
    final username = parts[0];
    final domain = parts[1];
    
    if (username.length <= 4) {
      return email;
    }
    
    final masked = username.substring(0, username.length - 4) + '****';
    return '$masked@$domain';
  }

  @override
  Widget build(BuildContext context) {
    // Authentication error
    if (!isAuthenticated) {
      return _buildAuthErrorScreen();
    }
    
    // Network error
    if (hasNetworkError) {
      return NoInternetScreen(
        onRetry: _loadConnectedFavorites,
      );
    }
    
    // Loading error
    if (hasLoadingError) {
      return LoadingErrorScreen(
        onRetry: _loadConnectedFavorites,
        errorMessage: errorMessage,
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
          onRefresh: _loadConnectedFavorites,
          color: Color(0xFFFF8C00),
          backgroundColor: Color(0xFF1E1E1E),
          child: CustomScrollView(
            physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverPadding(
                padding: EdgeInsets.all(20),
                sliver: _buildFavoritesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthErrorScreen() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: SafeArea(
          child: Container(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF8C00).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_off_outlined,
                    size: 60,
                    color: Color(0xFFFF8C00),
                  ),
                ),
                SizedBox(height: 40),
                Text(
                  'Authentication Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Please sign in to view connected favorites',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 48),
                Container(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Go Back',
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
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _searchController,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: isSearchMode 
                      ? FadeTransition(
                          opacity: _searchSlideAnimation,
                          child: Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: TextField(
                              controller: _searchTextController,
                              onChanged: _onSearchChanged,
                              style: TextStyle(color: Colors.white, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search connected favorites...',
                                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.6), size: 20),
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
                            'Connected Favorites',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                  ),
                  SizedBox(width: 15),
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: Icon(
                      isSearchMode ? Icons.close : Icons.search,
                      color: Colors.white.withOpacity(0.8),
                      size: 24,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                '${filteredFavorites.length} shared favorites',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoritesList() {
    if (isLoading) {
      return SliverFillRemaining(
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

    if (filteredFavorites.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_outline,
                  size: 60,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              SizedBox(height: 30),
              Text(
                'No Connected Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Connect with friends to see their favorite anime and share yours with them',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 40),
              Container(
                width: 200,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SyncUserPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF8C00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_add, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Find Friends',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
            position: _cardSlideAnimation,
            child: _buildFavoriteCard(filteredFavorites[index], index),
          );
        },
        childCount: filteredFavorites.length,
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> favorite, int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailsPage(
              animeId: favorite['anime_id'] ?? '',
              title: favorite['anime_title'] ?? '',
              animeType: 'anime',
              description: '',
              genres: [],
              poster: favorite['anime_image'] ?? '',
              rating: 0.0,
              year: '',
            ),
          ),
        );
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showContextMenu(context, favorite);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                bottomLeft: Radius.circular(15),
              ),
              child: Container(
                width: 100,
                height: 140,
                child: favorite['anime_image'] != null
                  ? Image.network(
                      favorite['anime_image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Color(0xFF2A2A2A),
                          child: Icon(Icons.image_not_supported, color: Colors.white.withOpacity(0.5)),
                        );
                      },
                    )
                  : Container(
                      color: Color(0xFF2A2A2A),
                      child: Icon(Icons.image, color: Colors.white.withOpacity(0.5)),
                    ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      favorite['anime_title'] ?? 'Unknown Title',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Added ${_formatDate(favorite['added_at'])}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.favorite, color: Color(0xFFFF8C00), size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Shared favorite',
                          style: TextStyle(
                            color: Color(0xFFFF8C00),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDetails(Map<String, dynamic> favorite) {
    // Mock user data - replace with actual user lookup
    final userData = {
      'username': 'friend_user',
      'email': 'friend@example.com',
      'avatar_url': 'male1.png',
    };
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(_getProfileImagePath(userData['avatar_url'])),
            backgroundColor: Color(0xFF2A2A2A),
          ),
          SizedBox(height: 12),
          Text(
            userData['username'] ?? 'Unknown User',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _maskEmail(userData['email'] ?? ''),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFFFF8C00).withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Color(0xFFFF8C00).withOpacity(0.5)),
            ),
            child: Text(
              'Shared this favorite',
              style: TextStyle(
                color: Color(0xFFFF8C00),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Map<String, dynamic> favorite) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60,
                          height: 80,
                          child: favorite['anime_image'] != null
                            ? Image.network(favorite['anime_image'], fit: BoxFit.cover)
                            : Container(color: Color(0xFF2A2A2A)),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              favorite['anime_title'] ?? 'Unknown Title',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Added ${_formatDate(favorite['added_at'])}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  _buildContextMenuItem(
                    icon: Icons.play_arrow,
                    title: 'Watch Now',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlayerScreen(
                            animeId: favorite['anime_id'] ?? '',
                            animeTitle: favorite['anime_title'] ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildContextMenuItem(
                    icon: Icons.share,
                    title: 'Share',
                    onTap: () async {
                      Navigator.pop(context);
                      await _shareAnime(favorite);
                    },
                  ),
                  _buildContextMenuItem(
                    icon: Icons.info_outline,
                    title: 'View Details',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AnimeDetailsPage(
                            animeId: favorite['anime_id'] ?? '',
                            title: favorite['anime_title'] ?? '',
                            animeType: 'anime',
                            description: '',
                            genres: [],
                            poster: favorite['anime_image'] ?? '',
                            rating: 0.0,
                            year: '',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
            SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAnime(Map<String, dynamic> favorite) async {
    try {
      // Get current user info
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final user = await SupabaseHandler.getUserByFirebaseUID(currentUser.uid);
      final username = user?['username'] ?? 'Anonymous';
      
      // Create share message
      final shareText = '''Hiotaku | Shared by $username

Hey!  
Want to watch this anime together?

Anime ID: ${favorite['anime_id'] ?? ''}

Note: This link works only inside the Hiotaku chat system.''';
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: shareText));
      
      // Show native share dialog
      await Share.share(
        shareText,
        subject: 'Check out this anime: ${favorite['anime_title'] ?? 'Unknown'}',
      );
      
      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anime shared and copied to clipboard!'),
            backgroundColor: Color(0xFFFF8C00),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share anime'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'Unknown';
    
    try {
      DateTime date = DateTime.parse(dateTime.toString());
      DateTime now = DateTime.now();
      Duration difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
