import 'package:flutter/material.dart';
import '../../../../../services/moviebox_service.dart';
import 'glassmorphic_bottom_sheet.dart';

class SubtitleSelector extends StatefulWidget {
  final String subjectId;
  final String detailPath;
  final int season;
  final int episode;
  final Function(String url, String language) onSubtitleSelect;
  final VoidCallback onTap;

  const SubtitleSelector({
    Key? key,
    required this.subjectId,
    required this.detailPath,
    required this.season,
    required this.episode,
    required this.onSubtitleSelect,
    required this.onTap,
  }) : super(key: key);

  @override
  State<SubtitleSelector> createState() => _SubtitleSelectorState();
}

class _SubtitleSelectorState extends State<SubtitleSelector> {
  List<Map<String, dynamic>> _subtitles = [];
  bool _loading = false;
  bool _isSubtitleActive = false;
  String _currentSubtitle = 'Off';

  @override
  void initState() {
    super.initState();
    _loadSubtitles();
  }

  Future<void> _loadSubtitles() async {
    setState(() => _loading = true);
    try {
      // First get episode ID from play API
      final playData = await MovieBoxService.getPlayUrls(
        id: widget.subjectId,
        path: widget.detailPath,
        season: widget.season,
        episode: widget.episode,
      );
      
      final streams = playData['data']?['streams'] as List? ?? [];
      if (streams.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      
      final episodeId = streams.first['id'] as String? ?? widget.subjectId;
      
      // Now get captions with episode ID
      final response = await MovieBoxService.getCaptions(
        id: episodeId,
        subjectId: widget.subjectId,
        path: widget.detailPath,
      );
      
      final captions = response['data']?['captions'] as List? ?? [];
      setState(() {
        _subtitles = captions.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Subtitle load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Image.asset(
        'assets/player/subtitles.png',
        width: 20,
        height: 20,
        color: _isSubtitleActive ? const Color(0xFFE5003C) : Colors.white,
        errorBuilder: (_, __, ___) => Icon(
          Icons.closed_caption,
          color: _isSubtitleActive ? const Color(0xFFE5003C) : Colors.white,
          size: 20,
        ),
      ),
      onPressed: () {
        if (_subtitles.isEmpty) return;
        
        final options = ['Off', ..._subtitles.map((s) => s['lanName'] ?? s['lan'] ?? 'Unknown')];
        
        GlassmorphicBottomSheet.show(
          context: context,
          title: 'Subtitles',
          options: options.cast<String>(),
          currentSelection: _currentSubtitle,
          onSelect: (selected) async {
            if (selected == 'Off') {
              setState(() {
                _isSubtitleActive = false;
                _currentSubtitle = 'Off';
              });
              widget.onSubtitleSelect('', 'Off');
              widget.onTap();
              return;
            }
            
            final sub = _subtitles.firstWhere(
              (s) => (s['lanName'] ?? s['lan']) == selected,
              orElse: () => {},
            );
            
            if (sub.isNotEmpty) {
              setState(() {
                _isSubtitleActive = true;
                _currentSubtitle = selected;
              });
              widget.onSubtitleSelect(sub['url'] ?? '', selected);
            }
            widget.onTap();
          },
        );
      },
    );
  }
}
