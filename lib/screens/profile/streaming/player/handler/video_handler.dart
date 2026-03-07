import 'package:flutter/material.dart';
import '../../../../../services/moviebox_service.dart';

class VideoHandler extends ChangeNotifier {
  // Video Data
  String? _currentVideoUrl;
  List<VideoQuality> _qualities = [];
  VideoQuality? _selectedQuality;
  
  // Episode/Season Data
  List<Season> _seasons = [];
  int _currentSeason = 1;
  int _currentEpisode = 1;
  
  // Loading States
  bool _isLoading = false;
  String? _error;
  
  // Movie Info
  final String subjectId;
  final String detailPath;
  
  VideoHandler({
    required this.subjectId,
    required this.detailPath,
  });

  // Getters
  String? get currentVideoUrl => _currentVideoUrl;
  List<VideoQuality> get qualities => _qualities;
  VideoQuality? get selectedQuality => _selectedQuality;
  List<Season> get seasons => _seasons;
  int get currentSeason => _currentSeason;
  int get currentEpisode => _currentEpisode;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load video URLs for current episode
  Future<void> loadVideo() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await MovieBoxService.getPlayUrls(
        id: subjectId,
        path: detailPath,
        season: _currentSeason,
        episode: _currentEpisode,
      );

      final streams = response['data']?['streams'] as List? ?? [];
      
      _qualities = streams.map((stream) {
        return VideoQuality(
          resolution: stream['resolutions']?.toString() ?? '',
          url: stream['url']?.toString() ?? '',
          size: stream['size']?.toString() ?? '',
          format: stream['format']?.toString() ?? 'MP4',
        );
      }).toList();

      // Sort by resolution (highest first)
      _qualities.sort((a, b) {
        final aRes = int.tryParse(a.resolution.replaceAll('p', '')) ?? 0;
        final bRes = int.tryParse(b.resolution.replaceAll('p', '')) ?? 0;
        return bRes.compareTo(aRes);
      });

      // Select best quality by default
      if (_qualities.isNotEmpty) {
        _selectedQuality = _qualities.first;
        _currentVideoUrl = _selectedQuality!.url;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load seasons and episodes
  Future<void> loadSeasons() async {
    try {
      final detail = await MovieBoxService.getDetail(id: subjectId, path: detailPath);
      
      // Parse seasons from API (structure may vary)
      // For now, create dummy structure - adjust based on actual API response
      _seasons = [
        Season(number: 1, episodes: List.generate(10, (i) => i + 1)),
        Season(number: 2, episodes: List.generate(10, (i) => i + 1)),
      ];
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading seasons: $e');
    }
  }

  // Switch quality
  void switchQuality(VideoQuality quality) {
    _selectedQuality = quality;
    _currentVideoUrl = quality.url;
    notifyListeners();
  }

  // Change episode
  Future<void> changeEpisode(int season, int episode) async {
    if (_currentSeason == season && _currentEpisode == episode) return;
    
    _currentSeason = season;
    _currentEpisode = episode;
    notifyListeners();
    
    await loadVideo();
  }

  // Next episode
  Future<void> nextEpisode() async {
    final currentSeasonData = _seasons.firstWhere(
      (s) => s.number == _currentSeason,
      orElse: () => Season(number: _currentSeason, episodes: []),
    );

    if (_currentEpisode < currentSeasonData.episodes.length) {
      await changeEpisode(_currentSeason, _currentEpisode + 1);
    } else if (_currentSeason < _seasons.length) {
      await changeEpisode(_currentSeason + 1, 1);
    }
  }

  // Previous episode
  Future<void> previousEpisode() async {
    if (_currentEpisode > 1) {
      await changeEpisode(_currentSeason, _currentEpisode - 1);
    } else if (_currentSeason > 1) {
      final prevSeasonData = _seasons.firstWhere(
        (s) => s.number == _currentSeason - 1,
        orElse: () => Season(number: _currentSeason - 1, episodes: []),
      );
      await changeEpisode(_currentSeason - 1, prevSeasonData.episodes.length);
    }
  }
}

// Video Quality Model
class VideoQuality {
  final String resolution;
  final String url;
  final String size;
  final String format;

  VideoQuality({
    required this.resolution,
    required this.url,
    required this.size,
    required this.format,
  });

  String get displayName => '$resolution ($format)';
  
  String get sizeInMB {
    final bytes = int.tryParse(size) ?? 0;
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }
}

// Season Model
class Season {
  final int number;
  final List<int> episodes;

  Season({
    required this.number,
    required this.episodes,
  });

  String get displayName => 'Season $number';
}
