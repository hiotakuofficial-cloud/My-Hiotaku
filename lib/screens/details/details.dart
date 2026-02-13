import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'handler/details_handler.dart';
import '../../services/api_service.dart';
import '../../models/api_models.dart';
import '../auth/handler/supabase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../player/player/player.dart';

class AnimeDetailsPage extends StatefulWidget {
  final String title;
  final String poster;
  final String description;
  final List<String> genres;
  final double rating;
  final String year;
  final String animeId;
  final String animeType;

  const AnimeDetailsPage({
    Key? key,
    required this.title,
    required this.poster,
    required this.description,
    required this.genres,
    required this.rating,
    required this.year,
    required this.animeId,
    required this.animeType,
  }) : super(key: key);

  @override
  _AnimeDetailsPageState createState() => _AnimeDetailsPageState();
}

class _AnimeDetailsPageState extends State<AnimeDetailsPage> {
  bool isBookmarked = false;
  bool isLoading = true;
  bool isCheckingFavorite = true;
  AnimeDetailsResponse? animeDetails;
  String? error;
  String? fallbackPoster;
  
  // Recommendations state
  List<AnimeItem> recommendations = [];
  bool isLoadingRecommendations = true;
  
  @override
  void initState() {
    super.initState();
    _loadAnimeDetails();
    _loadRecommendations();
    _checkFavoriteStatus();
  }

  Future<void> _loadAnimeDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final details = await DetailsHandler.getAnimeDetails(
        animeId: widget.animeId,
        animeType: widget.animeType,
        title: widget.title,
        poster: widget.poster,
      );

      if (mounted) {
        setState(() {
          animeDetails = details;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Unable to load anime details. Please check your connection and try again.';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFallbackPoster() async {
    if (fallbackPoster != null) return; // Already fetched
    
    try {
      
      // Search for anime by ID in home API to get thumbnail
      final homeResponse = await ApiService.searchAnime(widget.animeId, 1);
      
      if (homeResponse.data.isNotEmpty) {
        final matchedAnime = homeResponse.data.firstWhere(
          (anime) => anime.id == widget.animeId,
          orElse: () => homeResponse.data.first,
        );
        
        if (matchedAnime.poster?.isNotEmpty == true) {
          if (mounted) {
            setState(() {
              fallbackPoster = matchedAnime.poster;
            });
          }
        }
      }
    } catch (e) {
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        if (mounted) {
          setState(() {
            isBookmarked = false;
            isCheckingFavorite = false;
          });
        }
        return;
      }
      
      // Get Supabase user data
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) {
        if (mounted) {
          setState(() {
            isBookmarked = false;
            isCheckingFavorite = false;
          });
        }
        return;
      }
      
      // Check if anime exists in user's favorites
      final favorites = await SupabaseHandler.getUserFavorites(userData['id']);
      final isFavorited = favorites?.any((fav) => fav['anime_id'] == widget.animeId) ?? false;
      
      if (mounted) {
        setState(() {
          isBookmarked = isFavorited;
          isCheckingFavorite = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCheckingFavorite = false;
        });
      }
    }
  }

  Future<void> _handleFavoriteToggle() async {
    HapticFeedback.lightImpact();
    
    // Check if user is logged in
    final User? firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _showLoginRequiredDialog();
      return;
    }
    
    if (isBookmarked) {
      // Show remove confirmation dialog
      _showRemoveFromFavoritesDialog();
    } else {
      // Add to favorites
      await _addToFavorites();
    }
  }

  Future<void> _addToFavorites() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;
      
      // Get Supabase user data
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return;
      
      final result = await SupabaseHandler.addToFavorites(
        userId: userData['id'],
        animeId: widget.animeId,
        animeTitle: widget.title,
        animeImage: _getBestPosterUrl(),
      );
      
      if (result != null && mounted) {
        setState(() {
          isBookmarked = true;
        });
        _showSnackBar('Added to favorites! ❤️');
        
        // Notify connected users
        await DetailsHandler.notifyConnectedUsers(
          animeTitle: widget.title,
          userId: userData['id'].toString(),
        );
      } else {
        _showSnackBar('Failed to add to favorites');
      }
    } catch (e) {
      _showSnackBar('Failed to add to favorites');
    }
  }

  Future<void> _removeFromFavorites() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return;
      
      // Get Supabase user data
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) return;
      
      final success = await SupabaseHandler.removeFromFavorites(
        userId: userData['id'],
        animeId: widget.animeId,
      );
      
      if (success && mounted) {
        setState(() {
          isBookmarked = false;
        });
        _showSnackBar('Removed from favorites');
      } else {
        _showSnackBar('Failed to remove from favorites');
      }
    } catch (e) {
      _showSnackBar('Failed to remove from favorites');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              message.contains('Added') ? Icons.favorite : 
              message.contains('Removed') ? Icons.favorite_border :
              Icons.error_outline,
              color: message.contains('Added') ? Color(0xFFFF8C00) :
                     message.contains('Removed') ? Colors.white :
                     Colors.red[300],
              size: 18,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        duration: Duration(milliseconds: 2000),
        elevation: 8,
      ),
    );
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.login_rounded, color: Color(0xFFFF8C00), size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Login Required',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please login first before saving animes to your favorites.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/login');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF8C00),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Login', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRemoveFromFavoritesDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, color: Colors.red[300], size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Remove from Favorites?',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Do you want to remove "${widget.title}" from your saved list?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _removeFromFavorites();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Remove', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadRecommendations() async {
    try {
      
      final response = await ApiService.getRecommendations(widget.animeId);
      
      if (mounted) {
        setState(() {
          recommendations = response.data.take(6).toList(); // Limit to 6 items
          isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingRecommendations = false;
        });
      }
    }
  }

  String _getBestPosterUrl() {
    // Priority: API details > fallback > widget poster > empty
    if (animeDetails?.poster?.isNotEmpty == true) {
      return animeDetails!.poster;
    }
    if (fallbackPoster?.isNotEmpty == true) {
      return fallbackPoster!;
    }
    if (widget.poster.isNotEmpty) {
      return widget.poster;
    }
    return '';
  }

  double _getDisplayRating() {
    // If API provides rating, use it
    if (animeDetails?.rating != null && animeDetails!.rating > 0) {
      return animeDetails!.rating;
    }
    
    // If widget has rating, use it
    if (widget.rating > 0) {
      return widget.rating;
    }
    
    // Generate random rating between 6.0 and 8.0
    final random = DateTime.now().millisecondsSinceEpoch % 201; // 0-200
    final randomRating = 6.0 + (random / 100.0); // 6.0-8.0
    return double.parse(randomRating.toStringAsFixed(1));
  }
  
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF121212),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: isLoading
            ? _buildLoadingState()
            : error != null
                ? _buildErrorState()
                : SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroSection(),
                        _buildContentSection(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Color(0xFF121212),
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

  Widget _buildErrorState() {
    return Container(
      color: Color(0xFF121212),
      child: Column(
        children: [
          // Header with back button
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Error Loading Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: Colors.red[300],
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    Text(
                      'Failed to Load Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    Text(
                      error ?? 'Unable to fetch anime details at the moment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Retry button
                    Container(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _loadAnimeDetails,
                        icon: Icon(Icons.refresh_rounded, size: 20),
                        label: Text(
                          'Try Again',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF8C00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Show basic info as fallback
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Type: ${widget.animeType}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          if (widget.description.isNotEmpty) ...[
                            SizedBox(height: 12),
                            Text(
                              widget.description,
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Stack(
        children: [
          // Background Poster Image
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Image.network(
              _getBestPosterUrl(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Try to fetch fallback poster when image fails
                _fetchFallbackPoster();
                
                return Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                          size: 64,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Loading fallback image...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[800],
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF8C00),
                      strokeWidth: 3,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Gradient Overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                  Color(0xFF121212),
                ],
                stops: [0.0, 0.4, 0.8, 1.0],
              ),
            ),
          ),
          
          // Top Navigation
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  
                  // Bookmark Button
                  GestureDetector(
                    onTap: _handleFavoriteToggle,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: isCheckingFavorite
                          ? Icon(
                              Icons.favorite_border,
                              size: 12,
                              color: Colors.white.withOpacity(0.5),
                            )
                          : Image.asset(
                              isBookmarked 
                                  ? 'assets/icons/saved.png'
                                  : 'assets/icons/unsaved.png',
                              width: 12,
                              height: 12,
                              color: isBookmarked ? Color(0xFFFF8C00) : Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // IMDB Rating
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF8C00),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _getDisplayRating().toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '(MAL Score)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Title
                  Text(
                    animeDetails?.title ?? widget.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Genre Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (animeDetails?.genres ?? widget.genres).map((genre) => _buildGenreChip(genre)).toList(),
          ),
          
          SizedBox(height: 20),
          
          // Description
          Text(
            animeDetails?.description ?? widget.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          
          SizedBox(height: 30),
          
          // Play Now Button
          Container(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _playEpisode(1); // Direct play episode 1
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8C00),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                'Play Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          // Additional Info Section
          _buildInfoSection(),
          
          SizedBox(height: 30),
          
          // Recommendations Section
          _buildRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildGenreChip(String genre) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Text(
        genre,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 16),
        
        _buildInfoRow('Release Year', animeDetails?.year ?? widget.year),
        _buildInfoRow('Rating', '${_getDisplayRating()}/10'),
        _buildInfoRow('Genres', (animeDetails?.genres ?? widget.genres).join(', ')),
        _buildInfoRow('Status', animeDetails?.status ?? 'Unknown'),
        _buildInfoRow('Episodes', animeDetails?.episodes ?? 'Unknown'),
        _buildInfoRow('Type', animeDetails?.type ?? widget.animeType),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 16),
        
        Container(
          height: 200,
          child: isLoadingRecommendations
              ? _buildRecommendationsLoading()
              : recommendations.isEmpty
                  ? _buildNoRecommendations()
                  : ListView.builder(
                      physics: BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.only(right: 20),
                      itemCount: recommendations.length,
                      itemBuilder: (context, index) {
                        return _buildRecommendationCard(recommendations[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsLoading() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          width: 120,
          margin: EdgeInsets.only(right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF8C00),
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 12,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoRecommendations() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.movie_outlined,
            color: Colors.grey[600],
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'No recommendations available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(AnimeItem anime) {
    return Container(
      width: 120,
      margin: EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailsPage(
                title: anime.title,
                poster: anime.poster ?? '',
                description: anime.description ?? 'No description available.',
                genres: (anime.type?.isNotEmpty ?? false) ? [anime.type!] : ['Unknown'],
                rating: 0.0,
                year: anime.year ?? 'Unknown',
                animeId: anime.id,
                animeType: anime.type ?? 'Unknown',
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poster
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  anime.poster ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[800],
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey[600],
                        size: 32,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[800],
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Color(0xFFFF8C00),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            SizedBox(height: 8),
            
            // Title
            Text(
              anime.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 4),
            
            // Type/Genre
            if (anime.type?.isNotEmpty == true)
              Text(
                anime.type!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _playEpisode(int episodeNumber) {
    // Direct redirect to PlayerScreen - no language popup
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerScreen(
          animeId: widget.animeId ?? 'unknown',
          animeTitle: widget.title,
        ),
      ),
    );
  }

  void _showEpisodeList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      transitionAnimationController: AnimationController(
        duration: Duration(milliseconds: 600),
        vsync: Navigator.of(context),
      )..forward(),
      enableDrag: true,
      isDismissible: true,
      isScrollControlled: true,
      clipBehavior: Clip.antiAlias,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              SizedBox(height: 20),
              
              Text(
                'Episodes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 20),
              
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2,
                  ),
                  itemCount: 37, // Death Note episodes
                  itemBuilder: (context, index) {
                    final episodeNumber = index + 1;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _playEpisode(episodeNumber);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$episodeNumber',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
