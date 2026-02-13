import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/api_models.dart';

class SearchHandler {
  static Future<List<AnimeItem>> searchInSection({
    required String query,
    required String section,
  }) async {
    if (query.trim().isEmpty) return [];

    try {
      List<AnimeItem> allItems = [];
      
      switch (section.toLowerCase()) {
        case 'popular':
          final data = await ApiService.getPopular(1);
          allItems = data.data;
          break;
        case 'upcoming':
          final data = await ApiService.getTopUpcoming(1);
          allItems = data.data;
          break;
        case 'movies':
          final data = await ApiService.getMovies(1);
          allItems = data.data;
          break;
        case 'hindi':
          final data = await ApiService.getHindiAnime(1);
          allItems = data.data;
          break;
        case 'recent':
          final data = await ApiService.getSubbed(1);
          allItems = data.data;
          break;
        case 'continue':
          final data = await ApiService.getHome();
          allItems = data.data;
          break;
        default:
          return [];
      }

      // Filter items based on query
      return allItems.where((item) {
        return item.title.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      return [];
    }
  }

  static Widget buildSearchResults({
    required List<AnimeItem> results,
    required String query,
    required String section,
    required Widget Function(AnimeItem, int) itemBuilder,
  }) {
    if (results.isEmpty) {
      return _buildNoResults(query, section);
    }

    return GridView.builder(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return itemBuilder(results[index], index);
      },
    );
  }

  static Widget _buildNoResults(String query, String section) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.white54,
          ),
          SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(color: Colors.white70, fontSize: 16),
              children: [
                TextSpan(text: 'No matches for "'),
                TextSpan(
                  text: query,
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(text: '" in '),
                TextSpan(
                  text: _getSectionDisplayName(section),
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              'Try different keywords',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _getSectionDisplayName(String section) {
    switch (section.toLowerCase()) {
      case 'popular':
        return 'Popular Now';
      case 'upcoming':
        return 'Top Upcoming';
      case 'movies':
        return 'Anime Movies';
      case 'hindi':
        return 'Hindi Dubbed';
      case 'recent':
        return 'Recently Added';
      case 'continue':
        return 'Continue Watching';
      default:
        return section;
    }
  }

  static Widget buildSearchBox({
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onClose,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          SizedBox(width: 16),
          Icon(Icons.search, color: Colors.white70, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.white54, fontSize: 16),
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.close, color: Colors.white70, size: 20),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }
}
