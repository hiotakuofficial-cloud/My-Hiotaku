import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/api_models.dart';
import 'handler/search_handler.dart';
import '../details/details.dart';

class PopularPage extends StatefulWidget {
  @override
  _PopularPageState createState() => _PopularPageState();
}

class _PopularPageState extends State<PopularPage> with TickerProviderStateMixin {
  List<AnimeItem> animeList = [];
  List<AnimeItem> searchResults = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool isSearching = false;
  int currentPage = 1;
  bool hasMore = true;
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _searchAnimation;
  ScrollController _scrollController = ScrollController();
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _searchAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOutCubic),
    );
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!isLoadingMore && hasMore) {
        _loadMoreData();
      }
    }
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      final data = await ApiService.getPopular(1);
      setState(() {
        animeList = data.data;
        currentPage = 1;
        hasMore = data.data.length >= 20; // Assume 20 items per page
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMoreData() async {
    if (isLoadingMore || !hasMore) return;
    
    try {
      setState(() => isLoadingMore = true);
      final data = await ApiService.getPopular(currentPage + 1);
      setState(() {
        animeList.addAll(data.data);
        currentPage++;
        hasMore = data.data.length >= 20;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() => isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: Color(0xFFFF8C00),
          backgroundColor: Color(0xFF1E1E1E),
          child: CustomScrollView(
            controller: _scrollController,
            physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                sliver: isLoading ? 
                  SliverToBoxAdapter(child: _buildLoading()) :
                  _buildContent(),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 10),
      child: AnimatedBuilder(
        animation: _searchAnimation,
        builder: (context, child) {
          return Row(
            children: [
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (isSearching) {
                    _closeSearch();
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSearching ? Icons.arrow_back : Icons.arrow_back,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: isSearching
                    ? SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).animate(_searchAnimation),
                        child: SearchHandler.buildSearchBox(
                          controller: _searchController,
                          hintText: 'Search in Popular Now...',
                          onClose: _closeSearch,
                          onChanged: _onSearchChanged,
                        ),
                      )
                    : SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset.zero,
                          end: Offset(-1.0, 0.0),
                        ).animate(_searchAnimation),
                        child: Center(
                          child: Text(
                            'Popular Now',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ),
              SizedBox(width: 16),
              if (!isSearching)
                GestureDetector(
                  onTap: _openSearch,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.search, color: Colors.white, size: 24),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    setState(() => isSearching = true);
    _searchAnimationController.forward();
  }

  void _closeSearch() {
    HapticFeedback.lightImpact();
    _searchAnimationController.reverse().then((_) {
      setState(() {
        isSearching = false;
        searchResults.clear();
        _searchController.clear();
      });
    });
  }

  void _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      setState(() => searchResults.clear());
      return;
    }

    final results = await SearchHandler.searchInSection(
      query: query,
      section: 'popular',
    );
    
    setState(() => searchResults = results);
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text('Loading Popular Anime...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isSearching) {
      return SliverToBoxAdapter(
        child: SearchHandler.buildSearchResults(
          results: searchResults,
          query: _searchController.text,
          section: 'popular',
          itemBuilder: _buildAnimeCard,
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= animeList.length) {
            return _buildLoadingCard();
          }
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildAnimeCard(animeList[index], index),
          );
        },
        childCount: animeList.length + (isLoadingMore ? 2 : 0),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildAnimeCard(AnimeItem anime, int index) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimeDetailsPage(
              title: anime.title,
              poster: anime.poster ?? '',
              description: anime.description ?? 'No description available.',
              genres: (anime.type?.isNotEmpty ?? false) ? [anime.type!] : ['Popular'],
              rating: 0.0,
              year: 'Unknown',
              animeId: anime.id,
              animeType: anime.type ?? 'Popular',
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 50)),
        curve: Curves.elasticOut,
        child: Hero(
          tag: 'popular_${anime.id}',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Image.network(
                    anime.poster ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: Icon(Icons.image, color: Colors.white54, size: 50),
                      );
                    },
                  ),
                  // Rating Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'PG-13',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Quality Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'HD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
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
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              anime.title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (anime.type != null) ...[
                              SizedBox(height: 4),
                              Text(
                                anime.type!,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
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

  @override
  void dispose() {
    _animationController.dispose();
    _searchAnimationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
