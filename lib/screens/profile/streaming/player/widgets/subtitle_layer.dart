import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../../../../../services/moviebox_service.dart';

class SubtitleLayer extends StatefulWidget {
  final Player player;
  final String subjectId;
  final String detailPath;
  final int season;
  final int episode;

  const SubtitleLayer({
    Key? key,
    required this.player,
    required this.subjectId,
    required this.detailPath,
    required this.season,
    required this.episode,
  }) : super(key: key);

  @override
  State<SubtitleLayer> createState() => _SubtitleLayerState();
}

class _SubtitleLayerState extends State<SubtitleLayer> {
  List<Map<String, dynamic>> _subtitles = [];
  String? _selectedSubtitle;

  @override
  void initState() {
    super.initState();
    _loadSubtitles();
  }

  Future<void> _loadSubtitles() async {
    try {
      final response = await MovieBoxService.getCaptions(
        id: widget.subjectId,
        subjectId: widget.subjectId,
        path: widget.detailPath,
      );
      
      final captions = response['data']?['captions'] as List? ?? [];
      setState(() {
        _subtitles = captions.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('Subtitle load error: $e');
    }
  }

  void _selectSubtitle(String url) {
    setState(() => _selectedSubtitle = url);
    widget.player.setSubtitleTrack(
      SubtitleTrack.uri(url),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Subtitles are rendered by media_kit automatically
    return const SizedBox.shrink();
  }
}
