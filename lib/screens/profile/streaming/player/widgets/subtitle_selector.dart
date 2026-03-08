import 'package:flutter/material.dart';
import '../../../../../services/moviebox_service.dart';
import 'glassmorphic_bottom_sheet.dart';

class SubtitleSelector extends StatefulWidget {
  final String subjectId;
  final String detailPath;
  final Function(String url, String language) onSubtitleSelect;
  final VoidCallback onTap;

  const SubtitleSelector({
    Key? key,
    required this.subjectId,
    required this.detailPath,
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
      final response = await MovieBoxService.getCaptions(
        id: widget.subjectId,
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
      icon: const Icon(Icons.closed_caption, color: Colors.white, size: 20),
      onPressed: () {
        if (_subtitles.isEmpty) return;
        
        final options = ['Off', ..._subtitles.map((s) => s['lanName'] ?? s['lan'] ?? 'Unknown')];
        
        GlassmorphicBottomSheet.show(
          context: context,
          title: 'Subtitles',
          options: options.cast<String>(),
          onSelect: (selected) {
            if (selected == 'Off') {
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
        );
      },
    );
  }
}
