// API Response Models based on your API structure

class ApiResponse<T> {
  final bool success;
  final String? error;
  final T? data;

  ApiResponse({required this.success, this.error, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic)? fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      error: json['error'],
      data: fromJsonT != null && json['data'] != null ? fromJsonT(json['data']) : json['data'],
    );
  }
}

// Info Response
class InfoResponse {
  final String api;
  final String version;
  final Map<String, String> endpoints;

  InfoResponse({required this.api, required this.version, required this.endpoints});

  factory InfoResponse.fromJson(Map<String, dynamic> json) {
    return InfoResponse(
      api: json['api'] ?? '',
      version: json['version'] ?? '',
      endpoints: Map<String, String>.from(json['endpoints'] ?? {}),
    );
  }
}

// Home Response
class HomeResponse {
  final String section;
  final int total;
  final int page;
  final bool hasMore;
  final List<AnimeItem> data;

  HomeResponse({
    required this.section,
    required this.total,
    required this.page,
    required this.hasMore,
    required this.data,
  });

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      section: json['section'] ?? '',
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      hasMore: json['hasMore'] ?? false,
      data: (json['data'] as List?)?.map((e) => AnimeItem.fromJson(e)).toList() ?? [],
    );
  }
}

// Anime Item
class AnimeItem {
  final String id;
  final String title;
  final String? poster;
  final String? type;
  final String? status;
  final String? year;
  final String? description;

  AnimeItem({
    required this.id,
    required this.title,
    this.poster,
    this.type,
    this.status,
    this.year,
    this.description,
  });

  factory AnimeItem.fromJson(Map<String, dynamic> json) {
    return AnimeItem(
      id: json['id'] ?? json['anime_id'] ?? json['animeId'] ?? '',
      title: json['title'] ?? json['name'] ?? json['anime_title'] ?? '',
      poster: json['poster'] ?? json['image'] ?? json['thumbnail'] ?? json['cover'],
      type: json['type'] ?? json['category'] ?? json['genre'],
      status: json['status'] ?? json['state'],
      year: json['year'] ?? json['release_year'] ?? json['aired'],
      description: json['description'] ?? json['synopsis'] ?? json['summary'],
    );
  }
}

// Episodes Response
class EpisodesResponse {
  final String animeId;
  final String numericId;
  final int totalEpisodes;
  final List<Episode> episodes;

  EpisodesResponse({
    required this.animeId,
    required this.numericId,
    required this.totalEpisodes,
    required this.episodes,
  });

  factory EpisodesResponse.fromJson(Map<String, dynamic> json) {
    return EpisodesResponse(
      animeId: json['anime_id'] ?? '',
      numericId: json['numeric_id'] ?? '',
      totalEpisodes: json['total_episodes'] ?? 0,
      episodes: (json['episodes'] as List?)?.map((e) => Episode.fromJson(e)).toList() ?? [],
    );
  }
}

// Episode
class Episode {
  final int episodeNumber;
  final String episodeId;
  final String title;
  final String href;
  final bool? isFiller;
  final bool? available;

  Episode({
    required this.episodeNumber,
    required this.episodeId,
    required this.title,
    required this.href,
    this.isFiller,
    this.available,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      episodeNumber: json['episode_number'] ?? json['number'] ?? 0,
      episodeId: json['episode_id'] ?? json['episodeId'] ?? '',
      title: json['title'] ?? '',
      href: json['href'] ?? '',
      isFiller: json['is_filler'] ?? json['isFiller'],
      available: json['available'],
    );
  }
}

// Video Sources Response
class VideoSourcesResponse {
  final String animeId;
  final String episodeId;
  final VideoSources sources;
  final bool hasSub;
  final bool hasDub;

  VideoSourcesResponse({
    required this.animeId,
    required this.episodeId,
    required this.sources,
    required this.hasSub,
    required this.hasDub,
  });

  factory VideoSourcesResponse.fromJson(Map<String, dynamic> json) {
    return VideoSourcesResponse(
      animeId: json['anime_id'] ?? '',
      episodeId: json['episode_id'] ?? '',
      sources: VideoSources.fromJson(json['sources'] ?? {}),
      hasSub: json['has_sub'] ?? false,
      hasDub: json['has_dub'] ?? false,
    );
  }
}

// Video Sources
class VideoSources {
  final List<VideoSource> sub;
  final List<VideoSource> dub;

  VideoSources({required this.sub, required this.dub});

  factory VideoSources.fromJson(Map<String, dynamic> json) {
    return VideoSources(
      sub: (json['sub'] as List?)?.map((e) => VideoSource.fromJson(e)).toList() ?? [],
      dub: (json['dub'] as List?)?.map((e) => VideoSource.fromJson(e)).toList() ?? [],
    );
  }
}

// Video Source
class VideoSource {
  final String type;
  final String url;
  final String quality;
  final String? serverId;
  final String? serverName;

  VideoSource({
    required this.type,
    required this.url,
    required this.quality,
    this.serverId,
    this.serverName,
  });

  factory VideoSource.fromJson(Map<String, dynamic> json) {
    return VideoSource(
      type: json['type'] ?? '',
      url: json['url'] ?? '',
      quality: json['quality'] ?? '',
      serverId: json['server_id'],
      serverName: json['server_name'],
    );
  }
}

// Search Response
class SearchResponse {
  final String query;
  final int total;
  final List<AnimeItem> results;

  SearchResponse({
    required this.query,
    required this.total,
    required this.results,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      query: json['query'] ?? '',
      total: json['total'] ?? 0,
      results: (json['results'] as List?)?.map((e) => AnimeItem.fromJson(e)).toList() ?? 
               (json['data'] as List?)?.map((e) => AnimeItem.fromJson(e)).toList() ?? [],
    );
  }
}

// Anime Details Response
class AnimeDetailsResponse {
  final String id;
  final String title;
  final String? japaneseTitle;
  final String? poster;
  final String? description;
  final String? status;
  final String? aired;
  final String? duration;
  final String? premiered;
  final List<String>? genres;
  final double? rating;
  final List<Episode>? episodes;

  AnimeDetailsResponse({
    required this.id,
    required this.title,
    this.japaneseTitle,
    this.poster,
    this.description,
    this.status,
    this.aired,
    this.duration,
    this.premiered,
    this.genres,
    this.rating,
    this.episodes,
  });

  factory AnimeDetailsResponse.fromJson(Map<String, dynamic> json) {
    return AnimeDetailsResponse(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      japaneseTitle: json['japanese_title'],
      poster: json['poster'],
      description: json['description'],
      status: json['status'],
      aired: json['aired'],
      duration: json['duration'],
      premiered: json['premiered'],
      genres: (json['genres'] as List?)?.cast<String>(),
      rating: json['rating']?.toDouble(),
      episodes: (json['episodes'] as List?)?.map((e) => Episode.fromJson(e)).toList(),
    );
  }
}

// Generic Paginated Response
class PaginatedResponse<T> {
  final int page;
  final int total;
  final bool hasMore;
  final List<T> data;

  PaginatedResponse({
    required this.page,
    required this.total,
    required this.hasMore,
    required this.data,
  });

  factory PaginatedResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return PaginatedResponse<T>(
      page: json['page'] ?? 1,
      total: json['total'] ?? 0,
      hasMore: json['hasMore'] ?? json['has_more'] ?? false,
      data: (json['data'] as List?)?.map((e) => fromJsonT(e)).toList() ?? [],
    );
  }
}
