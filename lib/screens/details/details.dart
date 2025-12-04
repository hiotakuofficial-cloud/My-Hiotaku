import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'handler/details_handler.dart';
import '../../services/api_service.dart';
import '../../models/api_models.dart';

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
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFallbackPoster() async {
    if (fallbackPoster != null) return; // Already fetched
    
    try {
      print('🔄 Fetching fallback poster for ID: ${widget.animeId}');
      
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
            print('✅ Fallback poster found: ${matchedAnime.poster}');
          }
        }
      }
    } catch (e) {
      print('❌ Failed to fetch fallback poster: $e');
    }
  }

  Future<void> _loadRecommendations() async {
    try {
      print('🔄 Loading recommendations for: ${widget.animeId}');
      
      final response = await ApiService.getRecommendations(widget.animeId);
      
      if (mounted) {
        setState(() {
          recommendations = response.data.take(6).toList(); // Limit to 6 items
          isLoadingRecommendations = false;
        });
        print('✅ Loaded ${recommendations.length} recommendations');
      }
    } catch (e) {
      print('❌ Failed to load recommendations: $e');
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
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
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
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        isBookmarked = !isBookmarked;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? Color(0xFFFF8C00) : Colors.white,
                        size: 22,
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
                          (animeDetails?.rating ?? widget.rating).toString(),
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
                _showPlayDialog();
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
        _buildInfoRow('Rating', '${animeDetails?.rating ?? widget.rating}/10'),
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

  void _showPlayDialog() {
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
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_outline_rounded,
                    color: Color(0xFFFF8C00),
                    size: 48,
                  ),
                  
                  SizedBox(height: 16),
                  
                  Text(
                    'Coming Soon!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    'Video player feature will be available soon. Stay tuned!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Got it'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
