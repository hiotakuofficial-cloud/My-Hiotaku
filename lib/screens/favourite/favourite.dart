import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'handler/favourite_handler.dart';
import 'widgets/not_loggedin.dart';
import '../errors/no_internet.dart';
import '../details/details.dart';
import 'public/public.dart';
import 'syncuser/syncuser.dart';

class FavouritePage extends StatefulWidget {
  @override
  _FavouritePageState createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<Map<String, dynamic>> favorites = [];
  bool isLoading = true;
  bool hasNetworkError = false;
  String sortOrder = 'newest'; // 'newest' or 'oldest'
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _loadFavorites();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _loadFavorites() async {
    setState(() {
      isLoading = true;
      hasNetworkError = false;
    });
    
    // Reset animation for refresh
    _animationController.reset();
    
    try {
      final userFavorites = await FavouriteHandler.getUserFavorites()
          .timeout(Duration(seconds: 10));
      setState(() {
        favorites = userFavorites;
        _sortFavorites();
        isLoading = false;
        hasNetworkError = false;
      });
      // Always trigger animation
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
  
  void _sortFavorites() {
    try {
      favorites.sort((a, b) {
        final aTime = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
        
        return sortOrder == 'newest' 
          ? bTime.compareTo(aTime) 
          : aTime.compareTo(bTime);
      });
    } catch (e) {
      // If sorting fails, keep original order
    }
  }
  
  void _changeSortOrder(String newOrder) {
    try {
      setState(() {
        sortOrder = newOrder;
        _sortFavorites();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to sort favorites. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return NotLoggedInWidget();
    }
    
    // Check for network error
    if (hasNetworkError) {
      return NoInternetScreen(
        onRetry: () {
          _loadFavorites();
        },
      );
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
          onRefresh: _loadFavorites,
          color: Color(0xFFFF8C00),
          backgroundColor: Color(0xFF1E1E1E),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 100),
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: 20),
                  _buildActionButtons(),
                  SizedBox(height: 20),
                  _buildSortDropdown(),
                  SizedBox(height: 20),
                  _buildFavoritesList(),
                ],
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
        child: Center(
          child: Text(
            'My Favorites',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionButtons() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Public Saved',
                Icons.public,
                () => _navigateToPublicFavorites(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Sync Users',
                Icons.people,
                () => _navigateToSyncUsers(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSortDropdown() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Color(0xFFFF8C00).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort_rounded,
                color: Color(0xFFFF8C00),
                size: 18,
              ),
              SizedBox(width: 8),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: sortOrder,
                  dropdownColor: Color(0xFF1A1A1A),
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFFF8C00),
                    size: 20,
                  ),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      HapticFeedback.lightImpact();
                      _changeSortOrder(newValue);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: 'newest',
                      child: Row(
                        children: [
                          Icon(Icons.new_releases_outlined, color: Colors.white70, size: 16),
                          SizedBox(width: 8),
                          Text('Newest First'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'oldest',
                      child: Row(
                        children: [
                          Icon(Icons.history_outlined, color: Colors.white70, size: 16),
                          SizedBox(width: 8),
                          Text('Oldest First'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFavoritesList() {
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
    
    if (favorites.isEmpty) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_outline, color: Colors.white.withOpacity(0.3), size: 80),
              SizedBox(height: 20),
              Text(
                'No favorites yet',
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Add anime to your favorites to see them here',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                textAlign: TextAlign.center,
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
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            return _buildFavoriteItem(favorites[index], index);
          },
        ),
      ),
    );
  }
  
  Widget _buildFavoriteItem(Map<String, dynamic> favorite, int index) {
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
                  Text(
                    _formatDate(favorite['created_at']),
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeFavorite(favorite['anime_id'], index),
              icon: Icon(Icons.favorite, color: Color(0xFFFF8C00), size: 20),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(String? dateStr) {
    if (dateStr == null) {
      return 'Just now';
    }
    
    try {
      // Handle different date formats
      DateTime date;
      if (dateStr.contains('T')) {
        // ISO format: 2023-12-07T08:20:39.620+00:00
        date = DateTime.parse(dateStr);
      } else if (dateStr.contains('-')) {
        // Simple format: 2023-12-07
        date = DateTime.parse(dateStr);
      } else {
        // Fallback
        return 'Recently';
      }
      
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Recently';
    }
  }
  
  void _navigateToDetails(Map<String, dynamic> favorite) {
    try {
      // Validate required data
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
            genres: ['Favorite'],
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
  
  Future<void> _removeFavorite(String animeId, int index) async {
    try {
      final success = await FavouriteHandler.removeFromFavorites(animeId);
      if (success) {
        setState(() => favorites.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to remove from favorites. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to remove favorite. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _navigateToPublicFavorites() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PublicFavoritesPage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open public favorites. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _navigateToSyncUsers() {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SyncUserPage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to open sync users. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Color(0xFFFF8C00),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
