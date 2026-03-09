import 'package:flutter/material.dart';
import '../../../../../services/moviebox_service.dart';

class SeasonEpisodeController extends ChangeNotifier {
  List<Map<String, dynamic>> _seasons = [];
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> get seasons => _seasons;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSeasons(String subjectId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    debugPrint('Loading seasons for subjectId: $subjectId');

    try {
      final response = await MovieBoxService.getDetail(id: subjectId);
      debugPrint('Detail API response received');
      
      final resource = response['data']?['subject']?['resource'];
      debugPrint('Resource data: $resource');
      
      if (resource != null && resource['seasons'] != null) {
        _seasons = (resource['seasons'] as List)
            .map((s) => s as Map<String, dynamic>)
            .toList();
        debugPrint('Seasons loaded: ${_seasons.length}');
        debugPrint('Seasons: $_seasons');
      } else {
        debugPrint('No seasons found in response');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading seasons: $e');
    }

    _isLoading = false;
    notifyListeners();
    debugPrint('Loading complete. Seasons count: ${_seasons.length}');
  }

  List<int> getEpisodesForSeason(int season) {
    debugPrint('Getting episodes for season: $season');
    debugPrint('Available seasons: ${_seasons.map((s) => s['se']).toList()}');
    
    final seasonData = _seasons.firstWhere(
      (s) => s['se'] == season,
      orElse: () => {'maxEp': 0},
    );
    final maxEp = seasonData['maxEp'] ?? 0;
    debugPrint('Max episodes for season $season: $maxEp');
    
    return List.generate(maxEp, (index) => index + 1);
  }
}
