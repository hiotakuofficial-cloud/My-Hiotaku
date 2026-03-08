import 'package:flutter/material.dart';
import '../../../../../services/moviebox_service.dart';

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
        _showSubtitleDialog(context);
      },
    );
  }

  void _showSubtitleDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Subtitles',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'MazzardH',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text(
                'Off',
                style: TextStyle(color: Colors.white, fontFamily: 'MazzardH'),
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onTap();
              },
            ),
            ..._subtitles.map((sub) => ListTile(
              title: Text(
                sub['lanName'] ?? sub['lan'] ?? 'Unknown',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'MazzardH',
                ),
              ),
              onTap: () {
                widget.onSubtitleSelect(
                  sub['url'] ?? '',
                  sub['lanName'] ?? sub['lan'] ?? '',
                );
                Navigator.pop(context);
                widget.onTap();
              },
            )),
          ],
        ),
      ),
    );
  }
}
