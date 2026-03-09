import 'package:flutter/material.dart';
import '../../../../../services/moviebox_service.dart';

class RecommendationController extends ChangeNotifier {
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = false;
  
  List<Map<String, dynamic>> get recommendations => _recommendations;
  bool get isLoading => _isLoading;

  Future<void> loadRecommendations(String subjectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await MovieBoxService.getRecommendations(
        id: subjectId,
        perPage: 9,
      );

      final items = response['data']?['items'] as List? ?? [];
      _recommendations = items.map((item) {
        return {
          'subjectId': item['subjectId'] ?? '',
          'title': item['title'] ?? '',
          'imageUrl': item['cover']?['url'] ?? '',
          'rating': double.tryParse(item['imdbRatingValue']?.toString() ?? '0') ?? 0.0,
          'subjectType': item['subjectType'] ?? 2,
          'detailPath': item['detailPath'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('Recommendations load error: $e');
      _recommendations = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}
