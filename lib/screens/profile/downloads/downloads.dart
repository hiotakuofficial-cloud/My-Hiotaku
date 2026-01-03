import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'handler/download_handler.dart';

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
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _searchController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _elasticAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _elasticController, curve: Curves.elasticOut));
    
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _searchController, curve: Curves.easeInOut));
    
    _slideAnimation = Tween<Offset>(begin: Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _elasticController, curve: Curves.easeOutCubic));
    
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
        _elasticController.forward();
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
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: RefreshIndicator(
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
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _elasticAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF121212),
                  Color(0xFF121212).withOpacity(0.8),
                ],
              ),
            ),
            child: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 20, bottom: 16),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                      ),
                    ),
                    child: Icon(Icons.download_rounded, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Downloads',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Icon(
                        _isSearchVisible ? Icons.close : Icons.search,
                        color: Colors.white.withOpacity(0.8),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
      child: ScaleTransition(
        scale: _elasticAnimation,
        child: Container(
          height: 50,
          margin: EdgeInsets.symmetric(vertical: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildCategoryTab('Hindi Dub', DownloadHandler.hindiDub),
              _buildCategoryTab('Movies', DownloadHandler.movie),
              _buildCategoryTab('Hindi Sub', DownloadHandler.hindiSub),
              _buildCategoryTab('Eng Sub', DownloadHandler.engSub),
            ],
          ),
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
        margin: EdgeInsets.only(right: 12),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFF8C00) : Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Color(0xFFFF8C00) : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF8C00)),
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
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Color(0xFF2A2A2A),
                        child: Icon(Icons.image_not_supported, 
                            color: Colors.white.withOpacity(0.3)),
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

class DownloadDetailsScreen extends StatelessWidget {
  final AnimeItem anime;

  const DownloadDetailsScreen({Key? key, required this.anime}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Color(0xFF121212),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'anime_${anime.id}',
                child: Image.network(
                  anime.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Color(0xFF2A2A2A),
                    child: Icon(Icons.image_not_supported, 
                        color: Colors.white.withOpacity(0.3), size: 64),
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
                    anime.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
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
                    child: Text(
                      'Download links will be loaded here...',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
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
}
