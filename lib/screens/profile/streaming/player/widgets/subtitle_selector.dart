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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Image.asset(
            'assets/player/subtitles.png',
            width: 20,
            height: 20,
            color: Colors.white,
            errorBuilder: (_, __, ___) => const Icon(Icons.closed_caption, color: Colors.white, size: 20),
          ),
          onPressed: () {
            if (_subtitles.isEmpty) return;
        
        final options = ['Off', ..._subtitles.map((s) => s['lanName'] ?? s['lan'] ?? 'Unknown')];
        
        GlassmorphicBottomSheet.show(
          context: context,
          title: 'Subtitles',
          options: options.cast<String>(),
          onSelect: (selected) async {
            if (selected == 'Off') {
              widget.onSubtitleSelect('', 'Off');
              widget.onTap();
              return;
            }
            
            final sub = _subtitles.firstWhere(
              (s) => (s['lanName'] ?? s['lan']) == selected,
              orElse: () => {},
            );
            
            if (sub.isNotEmpty) {
              widget.onSubtitleSelect(sub['url'] ?? '', selected);
            }
            widget.onTap();
          },
        ),
        // Badge showing count
        if (_subtitles.isNotEmpty)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFE5003C),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '${_subtitles.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MazzardH',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
