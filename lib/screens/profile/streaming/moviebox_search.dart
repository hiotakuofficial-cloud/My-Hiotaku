import 'package:flutter/material.dart';
import '../../../services/moviebox_service.dart';

class MovieBoxSearch extends StatefulWidget {
  const MovieBoxSearch({Key? key}) : super(key: key);

  @override
  State<MovieBoxSearch> createState() => _MovieBoxSearchState();
}

class _MovieBoxSearchState extends State<MovieBoxSearch> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  List<dynamic> _trendingMovies = [];
  List<String> _recentSearches = [];
  List<String> _trendingSearches = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final trending = await MovieBoxService.getTrending(perPage: 20);
      final trendingList = trending['data']?['subjectList'] as List? ?? [];
      
      setState(() {
        _trendingMovies = trendingList.take(6).toList();
        _trendingSearches = trendingList.take(8).map((m) => m['title'] as String).toList();
      });
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final results = await MovieBoxService.search(keyword: query, perPage: 20);
      setState(() {
        _searchResults = results['data']?['items'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: _buildSearchAppBar(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B5C)))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(16.0),
                child: _isSearching
                    ? _buildSearchResults()
                    : _buildDefaultContent(),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF121212),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontFamily: 'MazzardH'),
              decoration: InputDecoration(
                hintText: 'Search for movies, TV shows...',
                hintStyle: const TextStyle(color: Color(0xFFB0B0B0), fontFamily: 'MazzardH'),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFB0B0B0)),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  _search(value);
                } else if (value.isEmpty) {
                  _search('');
                }
              },
            ),
          ),
          const SizedBox(width: 16.0),
        ],
      ),
    );
  }

  Widget _buildDefaultContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentSearches.isNotEmpty) _buildRecentSearches(),
        _buildTrendingSearches(),
        _buildTrendingNow(),
        const SizedBox(height: 16.0),
      ],
    );
  }

  Widget _buildRecentSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.history, 'Recent Searches'),
        ChipTag(
          text: _recentSearches.first,
          hasCloseIcon: true,
          textStyle: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 14, fontFamily: 'MazzardH'),
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  Widget _buildTrendingSearches() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.local_fire_department, 'Trending Searches'),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: _trendingSearches.map((search) => ChipTag(
            text: search,
            textStyle: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'MazzardH'),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          )).toList(),
        ),
        const SizedBox(height: 24.0),
      ],
    );
  }

  Widget _buildTrendingNow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(Icons.local_fire_department, 'Trending Now', titleColor: Colors.red),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 2 / 3,
          ),
          itemCount: _trendingMovies.length,
          itemBuilder: (context, index) {
            return _buildMovieCard(_trendingMovies[index]);
          },
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Icon(Icons.search_off, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'No results found',
              style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 16, fontFamily: 'MazzardH'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 2 / 3,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildMovieCard(_searchResults[index]);
      },
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {Color? titleColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: titleColor ?? Colors.white, size: 20),
          const SizedBox(width: 8.0),
          Text(
            title,
            style: TextStyle(
              color: titleColor ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'MazzardH',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie) {
    final cover = movie['cover'] ?? {};
    final imageUrl = cover['url'] ?? '';
    final title = movie['title'] ?? '';
    final rating = movie['imdbRatingValue'] ?? '0.0';
    final year = movie['releaseDate']?.toString().split('-')[0] ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 2 / 3,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade800,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, color: Colors.white70),
                );
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.4, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8.0,
            left: 8.0,
            right: 8.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'MazzardH',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFC107), size: 16),
                    const SizedBox(width: 4.0),
                    Text(
                      rating,
                      style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12, fontFamily: 'MazzardH'),
                    ),
                    const Spacer(),
                    Text(
                      year,
                      style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12, fontFamily: 'MazzardH'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChipTag extends StatelessWidget {
  final String text;
  final bool hasCloseIcon;
  final TextStyle textStyle;
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;

  const ChipTag({
    required this.text,
    this.hasCloseIcon = false,
    required this.textStyle,
    this.backgroundColor = const Color(0xFF2A2A2A),
    this.padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: textStyle),
          if (hasCloseIcon) ...[
            const SizedBox(width: 4.0),
            Icon(Icons.close, color: textStyle.color, size: 16),
          ],
        ],
      ),
    );
  }
}
