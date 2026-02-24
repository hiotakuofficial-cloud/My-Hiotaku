import 'package:flutter/material.dart';
import 'dart:async';
import '../hisu_handler.dart';
import '../../../details/details.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Fast async anime suggestion card with auto-sizing based on image
class AnimeSuggestionCard extends StatefulWidget {
  final String animeId;
  final VoidCallback? onTap;

  const AnimeSuggestionCard({
    super.key,
    required this.animeId,
    this.onTap,
  });

  @override
  State<AnimeSuggestionCard> createState() => _AnimeSuggestionCardState();
}

class _AnimeSuggestionCardState extends State<AnimeSuggestionCard> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _imageUrl;
  String? _title;
  String? _description;
  String? _type;
  double _aspectRatio = 0.7; // Default anime poster ratio
  int _retryCount = 0;
  static const int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _fetchAnimeData();
  }

  Future<void> _fetchAnimeData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use HisuHandler to fetch anime details
      final data = await HisuHandler.fetchAnimeDetails(widget.animeId);

      if (!mounted) return;

      // Try multiple image field names
      final imageUrl = data['thumbnail'] ?? 
                       data['poster'] ?? 
                       data['image'] ?? 
                       data['cover'] ?? 
                       data['img'];
      
      final title = data['title'] ?? data['name'] ?? 'Unknown';
      final description = data['description'] ?? 
                         data['synopsis'] ?? 
                         data['genre'] ?? 
                         data['summary'] ?? 
                         'No description';
      
      final type = data['type'] ?? data['status'] ?? 'Unknown';

      if (imageUrl != null && imageUrl.toString().isNotEmpty) {
        // Preload image to get dimensions
        await _preloadImage(imageUrl.toString());
        
        if (mounted) {
          setState(() {
            _imageUrl = imageUrl.toString();
            _title = title.toString();
            _description = description.toString();
            _type = type.toString();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('No image URL found');
      }
    } catch (e) {
      if (!mounted) return;

      // Retry logic
      if (_retryCount < _maxRetries) {
        _retryCount++;
        await Future.delayed(Duration(milliseconds: 500 * _retryCount));
        _fetchAnimeData();
      } else {
        // Show toast on final failure
        if (mounted) {
          Fluttertoast.showToast(
            msg: "Card load failed: ${widget.animeId}",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red.shade900,
            textColor: Colors.white,
            fontSize: 14.0,
          );
        }
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _preloadImage(String url) async {
    try {
      final image = NetworkImage(url);
      final completer = Completer<void>();
      
      final stream = image.resolve(const ImageConfiguration());
      stream.addListener(
        ImageStreamListener(
          (ImageInfo info, bool _) {
            // Calculate aspect ratio from image
            final width = info.image.width.toDouble();
            final height = info.image.height.toDouble();
            if (mounted) {
              setState(() {
                _aspectRatio = width / height;
              });
            }
            completer.complete();
          },
          onError: (dynamic exception, StackTrace? stackTrace) {
            completer.completeError(exception);
          },
        ),
      );
      
      await completer.future.timeout(const Duration(seconds: 3));
    } catch (e) {
      // Use default ratio on error
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_hasError) {
      return _buildErrorCard();
    }

    return _buildAnimeCard();
  }

  Widget _buildLoadingCard() {
    return Container(
      width: 120,
      height: 170,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return GestureDetector(
      onTap: () {
        _retryCount = 0;
        _fetchAnimeData();
      },
      child: Container(
        width: 120,
        height: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 32),
            const SizedBox(height: 8),
            Text(
              'Tap to retry',
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimeCard() {
    // Calculate card dimensions based on aspect ratio
    final cardWidth = _aspectRatio > 1 ? 160.0 : 120.0;
    final cardHeight = cardWidth / _aspectRatio;
    final clampedHeight = cardHeight.clamp(140.0, 200.0);

    return GestureDetector(
      onTap: () {
        if (_imageUrl != null && _title != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AnimeDetailsPage(
                title: _title!,
                poster: _imageUrl!,
                description: _description ?? 'No description available',
                genres: _type != null ? [_type!] : ['Unknown'],
                rating: 0.0,
                year: 'Unknown',
                animeId: widget.animeId,
                animeType: _type ?? 'Unknown',
              ),
            ),
          );
        }
        widget.onTap?.call();
      },
      child: Container(
        width: cardWidth,
        height: clampedHeight,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.network(
                _imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.white.withOpacity(0.05),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white30),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white.withOpacity(0.05),
                    child: const Icon(Icons.broken_image, color: Colors.white30),
                  );
                },
              ),
              // Gradient overlay for title
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Text(
                    _title ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
