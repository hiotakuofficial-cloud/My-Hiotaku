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

    try {
      final response = await MovieBoxService.getDetail(id: subjectId);
      final resource = response['data']?['subject']?['resource'];
      
      if (resource != null && resource['seasons'] != null) {
        _seasons = (resource['seasons'] as List)
            .map((s) => s as Map<String, dynamic>)
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  List<int> getEpisodesForSeason(int season) {
    final seasonData = _seasons.firstWhere(
      (s) => s['se'] == season,
      orElse: () => {'maxEp': 0},
    );
    final maxEp = seasonData['maxEp'] ?? 0;
    return List.generate(maxEp, (index) => index + 1);
  }
}
