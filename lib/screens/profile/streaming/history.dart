import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../search/search.dart';

class WatchHistoryScreen extends StatefulWidget {
  const WatchHistoryScreen({Key? key}) : super(key: key);

  @override
  State<WatchHistoryScreen> createState() => _WatchHistoryScreenState();
}

class _WatchHistoryScreenState extends State<WatchHistoryScreen> {
  List<HistoryItem> _historyItems = [];
  bool _isLoading = true;
  ViewType _viewType = ViewType.listView;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      final List<HistoryItem> items = [];
      
      for (final key in keys) {
        if (key.contains('_position')) {
          final parts = key.split('_');
          if (parts.length >= 4) {
            final subjectId = parts[0];
            final season = int.tryParse(parts[1].replaceAll('s', '')) ?? 0;
            final episode = int.tryParse(parts[2].replaceAll('e', '')) ?? 0;
            final position = prefs.getInt(key) ?? 0;
            
            // Get metadata if saved
            final metaKey = '${subjectId}_s${season}_e${episode}_meta';
            final metaJson = prefs.getString(metaKey);
            
            String title = 'Unknown';
            String posterUrl = '';
            int duration = 0;
            
            if (metaJson != null) {
              final meta = json.decode(metaJson);
              title = meta['title'] ?? 'Unknown';
              posterUrl = meta['posterUrl'] ?? '';
              duration = meta['duration'] ?? 0;
            }
            
            items.add(HistoryItem(
              id: key,
              subjectId: subjectId,
              title: title,
              posterUrl: posterUrl,
              season: season,
              episode: episode,
              position: position,
              duration: duration,
              lastWatched: DateTime.now(),
            ));
          }
        }
      }
      
      // Sort by last watched (most recent first)
      items.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
      
      if (mounted) {
        setState(() {
          _historyItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load history error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(id);
      
      // Remove metadata too
      final parts = id.split('_');
      if (parts.length >= 4) {
        final metaKey = '${parts[0]}_s${parts[1].replaceAll('s', '')}_e${parts[2].replaceAll('e', '')}_meta';
        await prefs.remove(metaKey);
      }
      
      setState(() {
        _historyItems.removeWhere((item) => item.id == id);
      });
    } catch (e) {
      debugPrint('Remove item error: $e');
    }
  }

  Future<void> _clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final item in _historyItems) {
        await prefs.remove(item.id);
      }
      setState(() => _historyItems.clear());
    } catch (e) {
      debugPrint('Clear all error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
              'Watch History',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'MazzardH',
              ),
            ),
            Text(
              'Continue watching your anime journey',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontFamily: 'MazzardH',
              ),
            ),
          ],
        ),
        actions: [
          if (_historyItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E1E1E),
                    title: const Text(
                      'Clear History',
                      style: TextStyle(color: Colors.white, fontFamily: 'MazzardH'),
                    ),
                    content: const Text(
                      'Remove all watch history?',
                      style: TextStyle(color: Colors.white70, fontFamily: 'MazzardH'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(fontFamily: 'MazzardH')),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _clearAll();
                        },
                        child: const Text(
                          'Clear',
                          style: TextStyle(color: Color(0xFFDC143C), fontFamily: 'MazzardH'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _historyItems.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  color: const Color(0xFFDC143C),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeInOut,
                    switchOutCurve: Curves.easeInOut,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                    child: _viewType == ViewType.listView
                        ? _buildListView()
                        : _buildGridView(),
                  ),
                ),
      floatingActionButton: _historyItems.isNotEmpty
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFDC143C),
              onPressed: () {
                setState(() {
                  _viewType = _viewType == ViewType.listView
                      ? ViewType.gridViewCompact
                      : _viewType == ViewType.gridViewCompact
                          ? ViewType.gridViewComfortable
                          : ViewType.listView;
                });
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  _viewType == ViewType.listView
                      ? Icons.grid_on
                      : _viewType == ViewType.gridViewCompact
                          ? Icons.apps
                          : Icons.list,
                  key: ValueKey(_viewType),
                  color: Colors.white,
                ),
              ),
            )
          : null,
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
                  width: 100,
                  height: 140,
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
                        width: 100,
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
                      const SizedBox(height: 12),
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(3),
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
            Icons.history,
            size: 100,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'No watch history yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'MazzardH',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start watching anime and your history will appear here',
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
                MaterialPageRoute(builder: (context) => SearchPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC143C),
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

  Widget _buildListView() {
    return ListView.builder(
      key: const ValueKey('list_view'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _historyItems.length,
      itemBuilder: (context, index) {
        final item = _historyItems[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFDC143C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _removeItem(item.id),
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
                        child: item.posterUrl.isNotEmpty
                            ? Image.network(
                                item.posterUrl,
                                width: 100,
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 100,
                                  height: 140,
                                  color: const Color(0xFF2A2A2A),
                                  child: const Icon(Icons.movie, color: Colors.white54),
                                ),
                              )
                            : Container(
                                width: 100,
                                height: 140,
                                color: const Color(0xFF2A2A2A),
                                child: const Icon(Icons.movie, color: Colors.white54),
                              ),
                      ),
                      if (item.duration > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: item.position / item.duration,
                            backgroundColor: Colors.black54,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFDC143C)),
                            minHeight: 4,
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
                          'S${item.season} E${item.episode}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontFamily: 'MazzardH',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(item.position / 60).floor()} min watched',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                            fontFamily: 'MazzardH',
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (item.duration > 0)
                          LinearProgressIndicator(
                            value: item.position / item.duration,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFDC143C)),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill, color: Color(0xFFDC143C), size: 32),
                    onPressed: () {
                      // Navigate to player
                      debugPrint('Play: ${item.title}');
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    final crossAxisCount = _viewType == ViewType.gridViewCompact ? 3 : 2;
    final childAspectRatio = _viewType == ViewType.gridViewCompact ? 0.6 : 0.7;

    return GridView.builder(
      key: ValueKey('grid_view_${_viewType.name}'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: _historyItems.length,
      itemBuilder: (context, index) {
        final item = _historyItems[index];
        return GestureDetector(
          onTap: () => debugPrint('Play: ${item.title}'),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: item.posterUrl.isNotEmpty
                            ? Image.network(
                                item.posterUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF2A2A2A),
                                  child: const Icon(Icons.movie, color: Colors.white54),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF2A2A2A),
                                child: const Icon(Icons.movie, color: Colors.white54),
                              ),
                      ),
                      if (item.duration > 0)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: LinearProgressIndicator(
                            value: item.position / item.duration,
                            backgroundColor: Colors.black54,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFFDC143C)),
                            minHeight: 4,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'MazzardH',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'S${item.season} E${item.episode}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                          fontFamily: 'MazzardH',
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
}

enum ViewType {
  listView,
  gridViewCompact,
  gridViewComfortable,
}

class HistoryItem {
  final String id;
  final String subjectId;
  final String title;
  final String posterUrl;
  final int season;
  final int episode;
  final int position;
  final int duration;
  final DateTime lastWatched;

  HistoryItem({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.posterUrl,
    required this.season,
    required this.episode,
    required this.position,
    required this.duration,
    required this.lastWatched,
  });
}
