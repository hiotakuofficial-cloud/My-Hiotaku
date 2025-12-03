import '../../../services/api_service.dart';
import '../../../models/api_models.dart';

class DetailsHandler {
  // Determine which API to use based on anime type and get details
  static Future<AnimeDetailsResponse> getAnimeDetails({
    required String animeId,
    required String animeType,
    String? title,
    String? poster,
  }) async {
    try {
      Map<String, dynamic> rawData;
      
      // Determine API based on anime type
      if (animeType.toLowerCase().contains('hindi') || 
          animeType.toLowerCase().contains('dubbed')) {
        // Use Hindi API
        rawData = await ApiService.getHindiAnimeDetails(animeId);
        return _parseHindiDetails(rawData, animeId, title, poster);
      } else {
        // Use English API
        rawData = await ApiService.getAnimeDetails(animeId);
        return _parseEnglishDetails(rawData, animeId, title, poster);
      }
    } catch (e) {
      throw Exception('Failed to get anime details: $e');
    }
  }

  // Parse English API response
  static AnimeDetailsResponse _parseEnglishDetails(
    Map<String, dynamic> data,
    String animeId,
    String? fallbackTitle,
    String? fallbackPoster,
  ) {
    try {
      // English API structure: direct object with anime details
      return AnimeDetailsResponse(
        id: animeId,
        title: data['title'] ?? fallbackTitle ?? 'Unknown Title',
        poster: data['poster'] ?? data['image'] ?? fallbackPoster ?? '',
        description: data['description'] ?? data['synopsis'] ?? 'No description available.',
        genres: _parseGenres(data['genres']),
        rating: _parseRating(data['rating']),
        year: data['year']?.toString() ?? data['release_year']?.toString() ?? 'Unknown',
        status: data['status'] ?? 'Unknown',
        episodes: data['episodes']?.toString() ?? 'Unknown',
        duration: data['duration'] ?? 'Unknown',
        studio: data['studio'] ?? 'Unknown',
        type: 'English',
        source: 'english_api',
      );
    } catch (e) {
      // Fallback with provided data
      return AnimeDetailsResponse(
        id: animeId,
        title: fallbackTitle ?? 'Unknown Title',
        poster: fallbackPoster ?? '',
        description: 'Details not available at the moment.',
        genres: ['Unknown'],
        rating: 0.0,
        year: 'Unknown',
        status: 'Unknown',
        episodes: 'Unknown',
        duration: 'Unknown',
        studio: 'Unknown',
        type: 'English',
        source: 'fallback',
      );
    }
  }

  // Parse Hindi API response
  static AnimeDetailsResponse _parseHindiDetails(
    Map<String, dynamic> data,
    String animeId,
    String? fallbackTitle,
    String? fallbackPoster,
  ) {
    try {
      // Hindi API structure: may have different field names
      return AnimeDetailsResponse(
        id: animeId,
        title: data['title'] ?? data['name'] ?? fallbackTitle ?? 'Unknown Title',
        poster: data['thumbnail'] ?? data['poster'] ?? data['image'] ?? fallbackPoster ?? '',
        description: data['description'] ?? data['synopsis'] ?? data['plot'] ?? 'No description available.',
        genres: _parseGenres(data['genres'] ?? data['category']),
        rating: _parseRating(data['rating'] ?? data['imdb_rating']),
        year: data['year']?.toString() ?? data['release_year']?.toString() ?? 'Unknown',
        status: data['status'] ?? 'Completed',
        episodes: data['episodes']?.toString() ?? data['total_episodes']?.toString() ?? 'Unknown',
        duration: data['duration'] ?? 'Unknown',
        studio: data['studio'] ?? 'Unknown',
        type: 'Hindi Dubbed',
        source: 'hindi_api',
      );
    } catch (e) {
      // Fallback with provided data
      return AnimeDetailsResponse(
        id: animeId,
        title: fallbackTitle ?? 'Unknown Title',
        poster: fallbackPoster ?? '',
        description: 'Details not available at the moment.',
        genres: ['Hindi Dubbed'],
        rating: 0.0,
        year: 'Unknown',
        status: 'Completed',
        episodes: 'Unknown',
        duration: 'Unknown',
        studio: 'Unknown',
        type: 'Hindi Dubbed',
        source: 'fallback',
      );
    }
  }

  // Parse genres from various formats
  static List<String> _parseGenres(dynamic genres) {
    if (genres == null) return ['Unknown'];
    
    if (genres is String) {
      // Handle comma-separated string
      return genres.split(',').map((g) => g.trim()).where((g) => g.isNotEmpty).toList();
    } else if (genres is List) {
      // Handle array of strings
      return genres.map((g) => g.toString().trim()).where((g) => g.isNotEmpty).toList();
    }
    
    return ['Unknown'];
  }

  // Parse rating from various formats
  static double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    
    if (rating is num) {
      return rating.toDouble();
    } else if (rating is String) {
      try {
        return double.parse(rating);
      } catch (e) {
        return 0.0;
      }
    }
    
    return 0.0;
  }

  // Get episodes list based on anime type
  static Future<List<EpisodeItem>> getEpisodes({
    required String animeId,
    required String animeType,
  }) async {
    try {
      if (animeType.toLowerCase().contains('hindi') || 
          animeType.toLowerCase().contains('dubbed')) {
        // Use Hindi API for episodes
        final rawData = await ApiService.getHindiEpisodes(animeId);
        return _parseHindiEpisodes(rawData);
      } else {
        // For English API, we would need to implement episode fetching
        // For now, return empty list as English API structure is not clear
        return [];
      }
    } catch (e) {
      throw Exception('Failed to get episodes: $e');
    }
  }

  // Parse Hindi episodes
  static List<EpisodeItem> _parseHindiEpisodes(List<Map<String, dynamic>> data) {
    return data.map((episode) {
      return EpisodeItem(
        id: episode['id']?.toString() ?? '',
        title: episode['title'] ?? 'Episode ${episode['episode_number'] ?? ''}',
        episodeNumber: episode['episode_number']?.toString() ?? '',
        thumbnail: episode['thumbnail'] ?? '',
        duration: episode['duration'] ?? 'Unknown',
      );
    }).toList();
  }
}

// Data models for details response
class AnimeDetailsResponse {
  final String id;
  final String title;
  final String poster;
  final String description;
  final List<String> genres;
  final double rating;
  final String year;
  final String status;
  final String episodes;
  final String duration;
  final String studio;
  final String type;
  final String source;

  AnimeDetailsResponse({
    required this.id,
    required this.title,
    required this.poster,
    required this.description,
    required this.genres,
    required this.rating,
    required this.year,
    required this.status,
    required this.episodes,
    required this.duration,
    required this.studio,
    required this.type,
    required this.source,
  });

  // Convert to map for easy usage in details page
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'poster': poster,
      'description': description,
      'genres': genres,
      'rating': rating,
      'year': year,
      'status': status,
      'episodes': episodes,
      'duration': duration,
      'studio': studio,
      'type': type,
      'source': source,
    };
  }
}

class EpisodeItem {
  final String id;
  final String title;
  final String episodeNumber;
  final String thumbnail;
  final String duration;

  EpisodeItem({
    required this.id,
    required this.title,
    required this.episodeNumber,
    required this.thumbnail,
    required this.duration,
  });
}
