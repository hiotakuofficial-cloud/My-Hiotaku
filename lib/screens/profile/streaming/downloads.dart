import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'moviebox_search.dart';
import 'moviebox_detail.dart';
import 'player/play.dart';
import 'components/bottom_nav.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({Key? key}) : super(key: key);

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<DownloadItem> _downloads = [];
  bool _isLoading = true;
  String _searchQuery = '';
  double _totalStorageGB = 0.0;
  double _usedStorageGB = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString('downloads_list') ?? '[]';
      final List<dynamic> downloadsList = json.decode(downloadsJson);
      
      final List<DownloadItem> items = [];
      double totalSize = 0;
      
      for (final d in downloadsList) {
        final filePath = d['filePath'] as String?;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            final size = await file.length();
            totalSize += size;
            
            items.add(DownloadItem(
              title: d['title'] ?? 'Unknown',
              season: d['season'] ?? 1,
              episode: d['episode'] ?? 1,
              filePath: filePath,
              fileSize: size,
              quality: '720p',
              language: 'Sub',
              downloadedAt: DateTime.parse(d['downloadedAt'] ?? DateTime.now().toIso8601String()),
            ));
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _downloads = items;
          _usedStorageGB = totalSize / (1024 * 1024 * 1024);
          _totalStorageGB = 10.0; // Can be fetched from device
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load downloads error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteDownload(DownloadItem item) async {
    try {
      final file = File(item.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString('downloads_list') ?? '[]';
      final List<dynamic> downloads = json.decode(downloadsJson);
      
      downloads.removeWhere((d) => 
        d['title'] == item.title && 
        d['season'] == item.season && 
        d['episode'] == item.episode
      );
      
      await prefs.setString('downloads_list', json.encode(downloads));
      
      setState(() {
        _downloads.removeWhere((d) => d.filePath == item.filePath);
        _usedStorageGB = _downloads.fold(0.0, (sum, d) => sum + d.fileSize) / (1024 * 1024 * 1024);
      });
    } catch (e) {
      debugPrint('Delete download error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDownloads = _searchQuery.isEmpty
        ? _downloads
        : _downloads.where((d) => d.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0B0B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Downloads',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'MazzardH',
              ),
            ),
            Text(
              'Watch your anime offline anytime',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'MazzardH',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: DownloadSearchDelegate(_downloads),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_downloads.isNotEmpty) _buildStorageIndicator(),
          Expanded(
            child: _isLoading
                ? _buildShimmerLoading()
                : filteredDownloads.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadDownloads,
                        color: const Color(0xFFFF3B5C),
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredDownloads.length,
                          itemBuilder: (context, index) {
                            return _buildDownloadCard(filteredDownloads[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: StreamingBottomNav(
        currentIndex: 2,
        onTap: (index) {
          if (index != 2) Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildStorageIndicator() {
    final percentage = _totalStorageGB > 0 ? _usedStorageGB / _totalStorageGB : 0.0;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Storage Used',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  fontFamily: 'MazzardH',
                ),
              ),
              Text(
                '${_usedStorageGB.toStringAsFixed(2)} GB of ${_totalStorageGB.toStringAsFixed(0)} GB',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MazzardH',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFFF3B5C)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(DownloadItem item) {
    return Dismissible(
      key: ValueKey(item.filePath),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B5C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteDownload(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 90,
                      height: 130,
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(Icons.movie, color: Colors.white54),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.download_done,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'MazzardH',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Episode ${item.episode} • ${item.title}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontFamily: 'MazzardH',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quality} • ${item.language}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontFamily: 'MazzardH',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Downloaded',
                            style: TextStyle(
                              color: Color(0xFF00C853),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'MazzardH',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(item.fileSize / (1024 * 1024)).toStringAsFixed(0)} MB',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontFamily: 'MazzardH',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill, color: Color(0xFFFF3B5C), size: 32),
                    onPressed: () {
                      // Play offline video
                      debugPrint('Play offline: ${item.filePath}');
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                    color: const Color(0xFF1E1E1E),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(item);
                      } else if (value == 'details') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => MovieBoxDetail(subjectId: ''),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Color(0xFFFF3B5C)),
                            SizedBox(width: 12),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Color(0xFFFF3B5C),
                                fontFamily: 'MazzardH',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'details',
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.white70),
                            SizedBox(width: 12),
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'MazzardH',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(DownloadItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Delete Download',
          style: TextStyle(color: Colors.white, fontFamily: 'MazzardH'),
        ),
        content: Text(
          'Delete ${item.title} Episode ${item.episode}?',
          style: const TextStyle(color: Colors.white70, fontFamily: 'MazzardH'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'MazzardH')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDownload(item);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFFF3B5C), fontFamily: 'MazzardH'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 90,
                  height: 130,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 14,
                        width: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_outlined,
            size: 100,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'No downloads yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'MazzardH',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download episodes to watch offline anytime',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontFamily: 'MazzardH',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MovieBoxSearch()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B5C),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Browse Anime',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'MazzardH',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DownloadSearchDelegate extends SearchDelegate<String> {
  final List<DownloadItem> downloads;

  DownloadSearchDelegate(this.downloads);

  @override
  String get searchFieldLabel => 'Search downloads';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0B0B),
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54, fontFamily: 'MazzardH'),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontFamily: 'MazzardH'),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.white),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = downloads
        .where((d) => d.title.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: const Color(0xFF0B0B0B),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final item = results[index];
          return ListTile(
            title: Text(
              item.title,
              style: const TextStyle(color: Colors.white, fontFamily: 'MazzardH'),
            ),
            subtitle: Text(
              'S${item.season} E${item.episode}',
              style: const TextStyle(color: Colors.white70, fontFamily: 'MazzardH'),
            ),
            onTap: () {
              close(context, item.title);
            },
          );
        },
      ),
    );
  }
}

class DownloadItem {
  final String title;
  final int season;
  final int episode;
  final String filePath;
  final int fileSize;
  final String quality;
  final String language;
  final DateTime downloadedAt;

  DownloadItem({
    required this.title,
    required this.season,
    required this.episode,
    required this.filePath,
    required this.fileSize,
    required this.quality,
    required this.language,
    required this.downloadedAt,
  });
}
