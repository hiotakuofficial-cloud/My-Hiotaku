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
      section: json['section'] ?? 'home',
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      hasMore: json['hasMore'] ?? false,
      data: (json['data'] as List?)?.map((e) => AnimeItem.fromJson(e)).toList() ?? [],
    );
  }
}

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
