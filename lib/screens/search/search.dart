import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'handler/search_handler.dart';
import '../../services/api_service.dart';
import '../../models/api_models.dart';
import '../details/details.dart';

// Simple cancel token for search operations
class CancelToken {
  bool _isCancelled = false;
  
  bool get isCancelled => _isCancelled;
  
  void cancel() {
    _isCancelled = true;
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  CancelToken? _currentSearchToken;
  
  List<SearchResult> _englishResults = [];
  List<SearchResult> _hindiResults = [];
  List<AnimeItem> _trendingAnime = [];
  bool _isLoading = false;
  bool _hasSearched = false;
  bool _loadingTrending = true;
  bool _hasNetworkConnection = true;
  String? _error;
  String? _trendingError;
  String _lastValidQuery = '';
  
  // Search cache for better performance
  final Map<String, CombinedSearchResponse> _searchCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);

  @override
  void initState() {
    super.initState();
    _checkNetworkAndLoadTrending();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    _currentSearchToken?.cancel();
    _searchCache.clear(); // Clear cache on dispose
    super.dispose();
  }

  // Network connectivity check
  Future<bool> _checkNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> _checkNetworkAndLoadTrending() async {
    final hasNetwork = await _checkNetworkConnection();
    setState(() {
      _hasNetworkConnection = hasNetwork;
    });
    
    if (hasNetwork) {
      _loadTrendingAnime();
    } else {
      setState(() {
        _loadingTrending = false;
        _trendingError = 'No internet connection';
      });
    }
  }

  Future<void> _loadTrendingAnime() async {
    setState(() {
      _loadingTrending = true;
      _trendingError = null;
    });

    try {
      final response = await ApiService.getPopular(1).timeout(Duration(seconds: 15));
      
      if (mounted) {
        if (response.data.isEmpty) {
          setState(() {
            _trendingAnime = [];
            _loadingTrending = false;
            _trendingError = 'No trending content available';
          });
        } else {
          setState(() {
            _trendingAnime = response.data.take(10).toList();
            _loadingTrending = false;
            _trendingError = null;
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _loadingTrending = false;
          _trendingError = 'Request timeout. Please try again.';
        });
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _loadingTrending = false;
          _trendingError = 'No internet connection';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTrending = false;
          _trendingError = 'Failed to load trending anime';
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    
    // Input validation
    final trimmedQuery = query.trim();
    
    if (trimmedQuery.isEmpty) {
      setState(() {
        _englishResults = [];
        _hindiResults = [];
        _hasSearched = false;
        _error = null;
      });
      return;
    }

    // Minimum character validation
    if (trimmedQuery.length < 2) {
      setState(() {
        _error = 'Please enter at least 2 characters';
        _hasSearched = true;
        _englishResults = [];
        _hindiResults = [];
      });
      return;
    }

    // Special character validation
    if (RegExp(r'[<>"\\]').hasMatch(trimmedQuery)) {
      setState(() {
        _error = 'Special characters not allowed';
        _hasSearched = true;
        _englishResults = [];
        _hindiResults = [];
      });
      return;
    }

    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      _performSearch(trimmedQuery);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    
    // Check cache first
    final cacheKey = query.toLowerCase().trim();
    if (_searchCache.containsKey(cacheKey)) {
      final cachedResponse = _searchCache[cacheKey]!;
      setState(() {
        _englishResults = cachedResponse.englishResults;
        _hindiResults = cachedResponse.hindiResults;
        _isLoading = false;
        _hasSearched = true;
        _error = cachedResponse.error;
      });
      return;
    }
    
    // Cancel previous search
    _currentSearchToken?.cancel();
    _currentSearchToken = CancelToken();
    
    // Network check before search
    if (!_hasNetworkConnection) {
      final hasNetwork = await _checkNetworkConnection();
      if (!hasNetwork) {
        setState(() {
          _error = 'No internet connection. Please check your network.';
          _hasSearched = true;
          _isLoading = false;
        });
        return;
      } else {
        setState(() {
          _hasNetworkConnection = true;
        });
      }
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
      _lastValidQuery = query;
    });

    try {
      final response = await SearchHandler.searchAnime(query).timeout(Duration(seconds: 30));
      
      // Check if search was cancelled
      if (_currentSearchToken?.isCancelled == true) return;
      
      if (mounted) {
        if (response.success) {
          // Cache successful results
          _searchCache[query.toLowerCase().trim()] = response;
          
          setState(() {
            _englishResults = response.englishResults;
            _hindiResults = response.hindiResults;
            _isLoading = false;
            _hasSearched = true;
            _error = response.englishResults.isEmpty && response.hindiResults.isEmpty 
                ? 'No results found for "$query"' 
                : null;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasSearched = true;
            _error = response.error ?? 'Search failed. Please try again.';
          });
        }
      }
    } on TimeoutException {
      if (mounted && _currentSearchToken?.isCancelled != true) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
          _error = 'Search timeout. Please try again with a shorter query.';
        });
      }
    } on SocketException {
      if (mounted && _currentSearchToken?.isCancelled != true) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
          _error = 'Network error. Please check your connection.';
          _hasNetworkConnection = false;
        });
      }
    } catch (e) {
      if (mounted && _currentSearchToken?.isCancelled != true) {
        setState(() {
          _isLoading = false;
          _hasSearched = true;
          _error = 'Search failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: SafeArea(
          child: Column(
            children: [
              _buildSearchHeader(),
              _buildSearchBar(),
              SizedBox(height: 20),
              Expanded(
                child: _buildSearchResults(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Text(
            'Search Anime',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF8C00),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchFocusNode.hasFocus 
              ? Color(0xFFFF8C00) 
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(color: Colors.white, fontSize: 16),
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search for anime...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 16,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.white.withOpacity(0.6),
            size: 24,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (!_hasSearched && !_isLoading) {
      return _buildInitialState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_englishResults.isEmpty && _hindiResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 60,
                  color: Colors.white.withOpacity(0.3),
                ),
                SizedBox(height: 16),
                Text(
                  'Search for your favorite anime',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find both English and Hindi dubbed content',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
          if (!_loadingTrending && _trendingAnime.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFFFF8C00),
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Trending Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ..._trendingAnime.map((anime) => _buildTrendingCard(anime)),
          ],
          if (_loadingTrending) ...[
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF8C00),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Loading trending anime...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
          if (_trendingError != null) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red[300],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _trendingError!,
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_trendingError!.contains('internet') || _trendingError!.contains('connection')) {
                        _checkNetworkAndLoadTrending();
                      } else {
                        _loadTrendingAnime();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF8C00),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendingCard(AnimeItem anime) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailsPage(
                  title: anime.title,
                  poster: anime.poster ?? '',
                  description: anime.description ?? 'No description available.',
                  genres: (anime.type?.isNotEmpty ?? false) ? [anime.type!] : ['Trending'],
                  rating: 0.0,
                  year: 'Unknown',
                  animeId: anime.id,
                  animeType: anime.type ?? 'Unknown',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    anime.poster ?? '',
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 80,
                        color: Colors.grey[800],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 60,
                        height: 80,
                        color: Colors.grey[800],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF8C00),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        anime.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF8C00).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TRENDING',
                          style: TextStyle(
                            color: Color(0xFFFF8C00),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFFFF8C00),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Searching...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80,
            color: Colors.red.withOpacity(0.7),
          ),
          SizedBox(height: 20),
          Text(
            _error ?? 'Something went wrong',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_lastValidQuery.isNotEmpty) {
                _performSearch(_lastValidQuery);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF8C00),
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          SizedBox(height: 20),
          Text(
            'No results found',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_englishResults.isNotEmpty) ...[
            _buildSectionHeader('English Anime', _englishResults.length),
            SizedBox(height: 12),
            ..._englishResults.map((result) => _buildResultCard(result)),
            SizedBox(height: 20),
          ],
          if (_hindiResults.isNotEmpty) ...[
            _buildSectionHeader('Hindi Dubbed', _hindiResults.length),
            SizedBox(height: 12),
            ..._hindiResults.map((result) => _buildResultCard(result)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Color(0xFFFF8C00),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnimeDetailsPage(
                  title: result.title,
                  poster: result.poster,
                  description: result.description ?? 'No description available.',
                  genres: (result.type.isNotEmpty) ? [result.type] : ['Unknown'],
                  rating: 0.0,
                  year: 'Unknown',
                  animeId: result.id,
                  animeType: result.type,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    result.poster,
                    width: 60,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 80,
                        color: Colors.grey[800],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 60,
                        height: 80,
                        color: Colors.grey[800],
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF8C00),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: result.type == 'hindi' 
                              ? Colors.green.withOpacity(0.2)
                              : Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          result.type == 'hindi' ? 'HINDI' : 'ENGLISH',
                          style: TextStyle(
                            color: result.type == 'hindi' 
                                ? Colors.green[300]
                                : Colors.blue[300],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (result.description != null) ...[
                        SizedBox(height: 6),
                        Text(
                          result.description!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
