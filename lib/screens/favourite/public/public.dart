import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'handler/public_handler.dart';
import '../../errors/no_internet.dart';
import '../../details/details.dart';

class PublicFavoritesPage extends StatefulWidget {
  @override
  _PublicFavoritesPageState createState() => _PublicFavoritesPageState();
}

class _PublicFavoritesPageState extends State<PublicFavoritesPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Search state
  bool isSearchMode = false;
  TextEditingController searchController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  
  // Data state
  List<Map<String, dynamic>> publicFavorites = [];
  List<Map<String, dynamic>> topUsers = [];
  List<Map<String, dynamic>> searchResults = [];
  
  // Loading states
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isSearching = false;
  bool hasNetworkError = false;
  bool hasMoreData = true;
  
  // Pagination
  int currentPage = 0;
  final int pageSize = 30;
  
  ScrollController scrollController = ScrollController();
  Timer? searchDebouncer;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    scrollController.addListener(_onScroll);
    searchController.addListener(_onSearchChanged);
    
    _loadInitialData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    scrollController.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    searchDebouncer?.cancel();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    setState(() {
      isLoading = true;
      hasNetworkError = false;
    });
    
    _animationController.reset();
    
    try {
      final futures = await Future.wait([
        PublicHandler.getPublicFavorites().timeout(Duration(seconds: 10)),
        PublicHandler.getPublicFavoritesStats().timeout(Duration(seconds: 10)),
      ]);
      
      final allFavorites = futures[0] as List<Map<String, dynamic>>;
      final stats = futures[1] as Map<String, dynamic>;
      
      setState(() {
        publicFavorites = allFavorites.take(pageSize).toList();
        hasMoreData = allFavorites.length > pageSize;
        currentPage = 1;
        isLoading = false;
        hasNetworkError = false;
      });
      
      _loadTopUsers();
      _animationController.forward();
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
  
  Future<void> _loadTopUsers() async {
    try {
      // Get users with most public favorites (mock implementation)
      final users = await PublicHandler.getPublicFavoritesWithUserInfo();
      final userCounts = <String, Map<String, dynamic>>{};
      
      for (var fav in users) {
        final userId = fav['user_id']?.toString();
        if (userId != null) {
          if (userCounts.containsKey(userId)) {
            userCounts[userId]!['count'] = (userCounts[userId]!['count'] ?? 0) + 1;
          } else {
            userCounts[userId] = {
              'user_id': userId,
              'username': fav['username'] ?? 'User',
              'avatar_url': fav['avatar_url'] ?? 'default.png',
              'count': 1,
            };
          }
        }
      }
      
      final sortedUsers = userCounts.values.toList()
        ..sort((a, b) => (b['count'] ?? 0).compareTo(a['count'] ?? 0));
      
      setState(() {
        topUsers = sortedUsers.take(4).toList();
      });
    } catch (e) {
    }
  }
  
  void _onScroll() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMoreData && !isSearchMode) {
        _loadMoreData();
      }
    }
  }
  
  Future<void> _loadMoreData() async {
    if (isLoadingMore) return;
    
    setState(() => isLoadingMore = true);
    
    try {
      final allFavorites = await PublicHandler.getPublicFavorites();
      final startIndex = currentPage * pageSize;
      final endIndex = startIndex + pageSize;
      
      if (startIndex < allFavorites.length) {
        final newFavorites = allFavorites.skip(startIndex).take(pageSize).toList();
        
        setState(() {
          publicFavorites.addAll(newFavorites);
          currentPage++;
          hasMoreData = endIndex < allFavorites.length;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          hasMoreData = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() => isLoadingMore = false);
    }
  }
  
  void _onSearchChanged() {
    searchDebouncer?.cancel();
    searchDebouncer = Timer(Duration(milliseconds: 500), () {
      if (searchController.text.trim().isNotEmpty) {
        _performSearch(searchController.text.trim());
      } else {
        setState(() {
          searchResults.clear();
          isSearching = false;
        });
      }
    });
  }
  
  Future<void> _performSearch(String query) async {
    setState(() => isSearching = true);
    
    try {
      final results = await PublicHandler.searchPublicFavorites(query);
      setState(() {
        searchResults = results;
        isSearching = false;
      });
    } catch (e) {
      setState(() => isSearching = false);
    }
  }
  
  void _toggleSearchMode() {
    setState(() {
      isSearchMode = !isSearchMode;
      if (isSearchMode) {
        searchFocusNode.requestFocus();
      } else {
        searchController.clear();
        searchResults.clear();
        searchFocusNode.unfocus();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (hasNetworkError) {
      return NoInternetScreen(onRetry: _loadInitialData);
    }
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        extendBodyBehindAppBar: true,
        body: RefreshIndicator(
          onRefresh: _loadInitialData,
          color: Color(0xFFFF8C00),
          backgroundColor: Color(0xFF1E1E1E),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 100),
                child: Column(
                  children: [
                    _buildHeader(),
                    SizedBox(height: 20),
                    if (!isSearchMode) ...[
                      _buildTopUsers(),
                      SizedBox(height: 20),
                    ],
                    _buildContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(isSearchMode ? -1.0 : 1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: isSearchMode 
            ? _buildSearchHeader() 
            : _buildNormalHeader(),
        ),
      ),
    );
  }
  
  Widget _buildNormalHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AnimatedDefaultTextStyle(
          duration: Duration(milliseconds: 300),
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          child: Text('Public Favorites'),
        ),
        AnimatedScale(
          scale: isSearchMode ? 0.8 : 1.0,
          duration: Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _toggleSearchMode();
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF8C00).withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.search,
                color: Color(0xFFFF8C00),
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchHeader() {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Color(0xFFFF8C00).withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF8C00).withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Search by username...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                icon: AnimatedRotation(
                  turns: isSearchMode ? 0.5 : 0.0,
                  duration: Duration(milliseconds: 300),
                  child: Icon(Icons.search, color: Color(0xFFFF8C00), size: 20),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        AnimatedScale(
          scale: isSearchMode ? 1.0 : 0.8,
          duration: Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _toggleSearchMode();
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: AnimatedRotation(
                turns: isSearchMode ? 0.25 : 0.0,
                duration: Duration(milliseconds: 300),
                child: Icon(Icons.close, color: Colors.white70, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTopUsers() {
    if (topUsers.isEmpty) return SizedBox.shrink();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Contributors',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: topUsers.map((user) => _buildTopUserCard(user)).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTopUserCard(Map<String, dynamic> user) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Color(0xFFFF8C00).withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFF8C00).withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(child: _buildUserAvatar(user['avatar_url'])),
        ),
        SizedBox(height: 8),
        Text(
          user['username'] ?? 'User',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${user['count'] ?? 0}',
          style: TextStyle(
            color: Color(0xFFFF8C00),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildUserAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty || avatarUrl == 'default.png') {
      return Image.asset(
        'assets/profile/default/default.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.white.withOpacity(0.1),
          child: Icon(Icons.person, color: Colors.white54, size: 30),
        ),
      );
    }
    
    if (avatarUrl.startsWith('assets/')) {
      return Image.asset(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.white.withOpacity(0.1),
          child: Icon(Icons.person, color: Colors.white54, size: 30),
        ),
      );
    }
    
    if (avatarUrl.startsWith('male') || avatarUrl.startsWith('female')) {
      String fullPath = avatarUrl.startsWith('male') 
        ? 'assets/profile/male/$avatarUrl'
        : 'assets/profile/female/$avatarUrl';
      
      return Image.asset(
        fullPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/profile/default/default.png',
          fit: BoxFit.cover,
        ),
      );
    }
    
    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Image.asset(
        'assets/profile/default/default.png',
        fit: BoxFit.cover,
      ),
    );
  }
  
  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: Lottie.asset(
          'assets/animations/loading.json',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
      );
    }
    
    if (isSearchMode) {
      return _buildSearchResults();
    }
    
    return _buildPublicFavoritesList();
  }
  
  Widget _buildSearchResults() {
    if (isSearching) {
      return Center(
        child: Lottie.asset(
          'assets/animations/loading.json',
          width: 80,
          height: 80,
          fit: BoxFit.contain,
        ),
      );
    }
    
    if (searchResults.isEmpty && searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, color: Colors.white.withOpacity(0.3), size: 80),
            SizedBox(height: 20),
            Text(
              'No results found',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: searchResults.map((result) => _buildFavoriteItem(result)).toList(),
    );
  }
  
  Widget _buildPublicFavoritesList() {
    if (publicFavorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public_off, color: Colors.white.withOpacity(0.3), size: 80),
            SizedBox(height: 20),
            Text(
              'No public favorites yet',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          children: [
            ...publicFavorites.map((favorite) => _buildFavoriteItem(favorite)).toList(),
            if (isLoadingMore)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Lottie.asset(
                    'assets/animations/loading.json',
                    width: 50,
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFavoriteItem(Map<String, dynamic> favorite) {
    return GestureDetector(
      onTap: () => _navigateToDetails(favorite),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 60,
                height: 80,
                color: Colors.white.withOpacity(0.1),
                child: favorite['anime_image'] != null
                  ? Image.network(
                      favorite['anime_image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                      ),
                    )
                  : Icon(Icons.movie, color: Colors.white54),
              ),
            ),
            SizedBox(width: 12),
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
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.white54, size: 14),
                      SizedBox(width: 4),
                      Text(
                        favorite['username'] ?? 'Anonymous',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.public, color: Color(0xFFFF8C00), size: 20),
          ],
        ),
      ),
    );
  }
  
  void _navigateToDetails(Map<String, dynamic> favorite) {
    try {
      final animeId = favorite['anime_id'];
      if (animeId == null || animeId.toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open details. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AnimeDetailsPage(
            title: favorite['anime_title'] ?? 'Unknown Title',
            poster: favorite['anime_image'] ?? '',
            description: 'No description available.',
            genres: ['Public'],
            rating: 0.0,
            year: 'Unknown',
            animeId: animeId.toString(),
            animeType: 'Unknown',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open details. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
