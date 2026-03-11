import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SeasonEpisodeSelector extends StatefulWidget {
  final List<Map<String, dynamic>> seasons;
  final int currentSeason;
  final int currentEpisode;
  final Function(int season, int episode) onSelect;

  const SeasonEpisodeSelector({
    Key? key,
    required this.seasons,
    required this.currentSeason,
    required this.currentEpisode,
    required this.onSelect,
  }) : super(key: key);

  @override
  State<SeasonEpisodeSelector> createState() => _SeasonEpisodeSelectorState();
}

class _SeasonEpisodeSelectorState extends State<SeasonEpisodeSelector> {
  late int _selectedSeason;
  int? _loadingEpisode; // Track which episode is loading
  int? _loadingSeason; // Track which season is loading for episode
  int? _loadingSeasonPill; // Track which season pill is loading
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedSeason = widget.currentSeason;
    _loadingEpisode = null;
    _loadingSeason = null;
    _loadingSeasonPill = null;
    _loadData();
  }
  
  @override
  void didUpdateWidget(SeasonEpisodeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clear loading state when episode actually changes
    if (oldWidget.currentEpisode != widget.currentEpisode || 
        oldWidget.currentSeason != widget.currentSeason) {
      setState(() {
        _loadingEpisode = null;
        _loadingSeason = null;
        _loadingSeasonPill = null;
      });
    }
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<int> _getEpisodesForSeason(int season) {
    final seasonData = widget.seasons.firstWhere(
      (s) => s['se'] == season,
      orElse: () => {'maxEp': 0},
    );
    final maxEp = seasonData['maxEp'] ?? 0;
    return List.generate(maxEp, (index) => index + 1);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final desiredHeight = screenHeight * 0.80;

    return DraggableScrollableSheet(
      initialChildSize: desiredHeight / screenHeight,
      minChildSize: desiredHeight / screenHeight,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          height: desiredHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isLoading
                      ? _buildShimmerLoading()
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSeasonSelector(),
                            const SizedBox(width: 16),
                            _buildEpisodeGrid(scrollController),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Episodes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'MazzardH',
            ),
          ),
          Container(
            width: 180,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontFamily: 'MazzardH'),
              decoration: InputDecoration(
                hintText: 'Search episode',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontFamily: 'MazzardH'),
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFDC143C),
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonSelector() {
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              'Season',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'MazzardH',
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: widget.seasons.length,
              itemBuilder: (context, index) {
                final season = widget.seasons[index]['se'] as int;
                final isActive = season == _selectedSeason;
                final isDisabled = _loadingEpisode != null || _loadingSeasonPill != null;

                return GestureDetector(
                  onTap: isDisabled ? null : () {
                    setState(() {
                      _selectedSeason = season;
                      _loadingSeasonPill = season;
                      _loadingEpisode = null;
                      _loadingSeason = null;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDC143C) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? Colors.transparent : const Color(0xFF121212).withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Season $season',
                      style: TextStyle(
                        color: isDisabled 
                            ? Colors.white.withOpacity(0.3)
                            : isActive 
                                ? Colors.white 
                                : Colors.white.withOpacity(0.8),
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: 15,
                        fontFamily: 'MazzardH',
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
  }

  Widget _buildEpisodeGrid(ScrollController scrollController) {
    final episodes = _getEpisodesForSeason(_selectedSeason);

    return Expanded(
      child: GridView.builder(
        controller: scrollController,
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
        ),
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          final episode = episodes[index];
          final isCurrentlyPlaying = episode == widget.currentEpisode && _selectedSeason == widget.currentSeason;
          final isDisabled = _loadingEpisode != null || _loadingSeasonPill != null;

          return GestureDetector(
            onTap: isDisabled ? null : () {
              setState(() {
                _loadingEpisode = episode;
                _loadingSeason = _selectedSeason;
                _loadingSeasonPill = null;
              });
              widget.onSelect(_selectedSeason, episode);
              Navigator.pop(context);
            },
            child: RepaintBoundary(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: isCurrentlyPlaying 
                      ? const Color(0xFFDC143C) 
                      : isDisabled
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrentlyPlaying ? Colors.transparent : const Color(0xFF121212).withOpacity(0.6),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'EP $episode',
                  style: TextStyle(
                    color: isDisabled 
                        ? const Color(0x4DFFFFFF)  // Direct hex color, no withOpacity
                        : isCurrentlyPlaying 
                            ? Colors.white 
                            : const Color(0xCCFFFFFF),  // Direct hex color
                          fontWeight: isCurrentlyPlaying ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                          fontFamily: 'MazzardH',
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Season shimmer
        SizedBox(
          width: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Shimmer.fromColors(
                  baseColor: const Color(0xFF1E1E1E),
                  highlightColor: const Color(0xFF2A2A2A),
                  child: Container(
                    width: 60,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Shimmer.fromColors(
                        baseColor: const Color(0xFF1E1E1E),
                        highlightColor: const Color(0xFF2A2A2A),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Episode grid shimmer
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: const Color(0xFF1E1E1E),
                highlightColor: const Color(0xFF2A2A2A),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
