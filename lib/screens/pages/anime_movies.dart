import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/api_models.dart';
import 'handler/search_handler.dart';
import '../details/details.dart';

class AnimeMoviesPage extends StatefulWidget {
  @override
  _AnimeMoviesPageState createState() => _AnimeMoviesPageState();
}

class _AnimeMoviesPageState extends State<AnimeMoviesPage> with TickerProviderStateMixin {
  List<AnimeItem> animeList = [];
  List<AnimeItem> searchResults = [];
  bool isLoading = true;
  bool isSearching = false;
  late AnimationController _animationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _searchAnimation;
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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      final data = await ApiService.getMovies(1);
      print('Movies loaded: ${data.data.length} items'); // Debug
      setState(() {
        animeList = data.data;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print('Error loading movies: $e'); // Debug
      setState(() => isLoading = false);
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
                  child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
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
                          hintText: 'Search in Anime Movies...',
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
                            'Anime Movies',
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
      section: 'movies',
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
          Text('Loading Anime Movies...', style: TextStyle(color: Colors.white)),
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
          section: 'movies',
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
          return FadeTransition(
            opacity: _fadeAnimation,
            child: _buildAnimeCard(animeList[index], index),
          );
        },
        childCount: animeList.length,
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
              genres: (anime.type?.isNotEmpty ?? false) ? [anime.type!] : ['Movie'],
              rating: 0.0,
              year: 'Unknown',
              animeId: anime.id,
              animeType: anime.type ?? 'Movie',
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300 + (index * 50)),
        curve: Curves.elasticOut,
        child: Hero(
          tag: 'movie_${anime.id}',
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
                  // Movie Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'MOVIE',
                        style: TextStyle(
                          color: Colors.white,
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
                            SizedBox(height: 4),
                            Text(
                              'Movie',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
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
    _searchController.dispose();
    super.dispose();
  }
}
