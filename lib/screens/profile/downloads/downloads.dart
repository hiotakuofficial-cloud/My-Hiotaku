import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'handler/download_handler.dart';
import '../../errors/loading_error.dart';
import '../../errors/no_internet.dart';
import 'widget/widget_download.dart';

class DownloadsScreen extends StatefulWidget {
  @override
  _DownloadsScreenState createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _elasticController;
  late AnimationController _searchController;
  late Animation<double> _elasticAnimation;
  late Animation<double> _searchAnimation;
  late Animation<Offset> _slideAnimation;
  
  final TextEditingController _searchTextController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isSearchVisible = false;
  bool _isLoading = true;
  String _selectedCategory = DownloadHandler.hindiDub;
  
  List<AnimeItem> _animeList = [];
  List<AnimeItem> _searchResults = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    
    _elasticController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _searchController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _elasticAnimation = Tween<double>(begin: 0.8, end: 1.0)
        .animate(CurvedAnimation(parent: _elasticController, curve: Curves.easeOutCubic));
    
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _searchController, curve: Curves.easeInOut));
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _elasticController, curve: Curves.easeOutCubic));
    
    _elasticController.forward();
    _loadContent();
    _searchTextController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _elasticController.dispose();
    _searchController.dispose();
    _searchTextController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchTextController.text.trim();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() => _searchResults.clear());
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.length < 2) return;
    
    try {
      final response = await DownloadHandler.searchAnime(query);
      if (response.success && response.data != null) {
        setState(() => _searchResults = response.data!);
      }
    } catch (e) {
      // Handle search error silently
    }
  }

  Future<void> _loadContent() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await DownloadHandler.getHomeContent(type: _selectedCategory);
      
      if (response.success && response.data != null) {
        setState(() {
          _animeList = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await _loadContent();
  }

  void _toggleSearch() {
    setState(() => _isSearchVisible = !_isSearchVisible);
    if (_isSearchVisible) {
      _searchController.forward();
    } else {
      _searchController.reverse();
      _searchTextController.clear();
      setState(() {
        _searchResults.clear();
        _searchQuery = '';
      });
    }
    HapticFeedback.lightImpact();
  }

  void _onCategoryChanged(String category) {
    if (category != _selectedCategory) {
      setState(() => _selectedCategory = category);
      _loadContent();
      HapticFeedback.selectionClick();
    }
  }

  void _onAnimeCardTap(AnimeItem anime) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DownloadDetailsScreen(anime: anime),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Color(0xFF121212),
        body: ScaleTransition(
          scale: _elasticAnimation,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            backgroundColor: Color(0xFF1E1E1E),
            color: Color(0xFFFF8C00),
            child: CustomScrollView(
              controller: _scrollController,
              physics: BouncingScrollPhysics(),
              slivers: [
                _buildHeader(),
                _buildSearchSection(),
                _buildCategoryTabs(),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF121212),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Downloads',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearchVisible ? Icons.close : Icons.search,
            color: Colors.white,
            size: 22,
          ),
          onPressed: _toggleSearch,
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _searchAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -50 * (1 - _searchAnimation.value)),
            child: Opacity(
              opacity: _searchAnimation.value,
              child: _isSearchVisible ? Container(
                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _searchTextController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search anime...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search, color: Color(0xFFFF8C00)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    autofocus: true,
                  ),
                ),
              ) : SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50,
        margin: EdgeInsets.symmetric(vertical: 10),
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildCategoryTab('Hindi Dub', DownloadHandler.hindiDub),
            _buildCategoryTab('Movies', DownloadHandler.movie),
            _buildCategoryTab('Hindi Sub', DownloadHandler.hindiSub),
            _buildCategoryTab('Eng Sub', DownloadHandler.engSub),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTab(String title, String category) {
    final isSelected = _selectedCategory == category;
    
    return GestureDetector(
      onTap: () => _onCategoryChanged(category),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.only(right: 10),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFF8C00) : Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFFFF8C00) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/loading.json',
                width: 100,
                height: 100,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 12),
              Text(
                'Loading content...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayList = _isSearchVisible && _searchQuery.isNotEmpty 
        ? _searchResults 
        : _animeList;

    if (displayList.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.white.withOpacity(0.3)),
              SizedBox(height: 16),
              Text(
                _isSearchVisible ? 'No results found' : 'No content available',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.all(20),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final anime = displayList[index];
            return _buildAnimeCard(anime, index);
          },
          childCount: displayList.length,
        ),
      ),
    );
  }

  Widget _buildAnimeCard(AnimeItem anime, int index) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _elasticController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.elasticOut,
          ),
        ),
      ),
      child: Hero(
        tag: 'anime_${anime.id}',
        child: GestureDetector(
          onTap: () => _onAnimeCardTap(anime),
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      anime.thumbnail,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/fallback/notfound.png',
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      anime.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

class DownloadDetailsScreen extends StatefulWidget {
  final AnimeItem anime;

  const DownloadDetailsScreen({Key? key, required this.anime}) : super(key: key);

  @override
  _DownloadDetailsScreenState createState() => _DownloadDetailsScreenState();
}

class _DownloadDetailsScreenState extends State<DownloadDetailsScreen> {
  bool _isLoading = true;
  AnimeDetails? _animeDetails;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnimeDetails();
  }

  Future<void> _loadAnimeDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DownloadHandler.getAnimeDetails(widget.anime.id);
      
      if (response.success && response.data != null) {
        setState(() {
          _animeDetails = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load details';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  String _cleanText(String text) {
    return text
        .replaceAll('&#038;', '')
        .replaceAll('&amp;', '')
        .replaceAll('&lt;', '')
        .replaceAll('&gt;', '')
        .replaceAll('&quot;', '')
        .replaceAll('&#8217;', '')
        .replaceAll('&nbsp;', '')
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Color(0xFF121212),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Color(0xFFFF8C00), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'anime_${widget.anime.id}',
                child: Image.network(
                  widget.anime.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/fallback/notfound.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cleanText(widget.anime.title),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                  else if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red),
                      ),
                    )
                  else if (_animeDetails != null) ...[
                    // Download Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Show download links widget
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => DownloadWidget(
                              animeId: widget.anime.id,
                              animeTitle: widget.anime.title,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.download, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Download',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            _cleanText(_animeDetails!.content ?? 'No description available'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
