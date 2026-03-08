import 'package:flutter/material.dart';
import '../../../../../services/moviebox_service.dart';
import 'glassmorphic_bottom_sheet.dart';

class AudioTrackSelector extends StatefulWidget {
  final String subjectId;
  final String detailPath;
  final Function(String subjectId, String detailPath, String language) onAudioSelect;
  final VoidCallback onTap;

  const AudioTrackSelector({
    Key? key,
    required this.subjectId,
    required this.detailPath,
    required this.onAudioSelect,
    required this.onTap,
  }) : super(key: key);

  @override
  State<AudioTrackSelector> createState() => _AudioTrackSelectorState();
}

class _AudioTrackSelectorState extends State<AudioTrackSelector> {
  List<Map<String, dynamic>> _audioTracks = [];
  bool _loading = false;
  String? _currentAudio;

  @override
  void initState() {
    super.initState();
    _loadAudioTracks();
  }

  Future<void> _loadAudioTracks() async {
    setState(() => _loading = true);
    try {
      final response = await MovieBoxService.getDetail(
        id: widget.subjectId,
        path: widget.detailPath,
      );
      
      final dubs = response['data']?['subject']?['dubs'] as List? ?? [];
      setState(() {
        _audioTracks = dubs.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Audio tracks load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.audiotrack, color: Colors.white, size: 20),
      onPressed: () {
        if (_audioTracks.isEmpty) return;
        
        final options = _audioTracks.map((track) {
          final lanName = track['lanName'] ?? 'Unknown';
          final type = track['type'] == 0 ? 'DUB' : 'SUB';
          return '$lanName ($type)';
        }).toList();
        
        GlassmorphicBottomSheet.show(
          context: context,
          title: 'Audio Track',
          options: options.cast<String>(),
          currentSelection: _currentAudio,
          onSelect: (selected) {
            final index = options.indexOf(selected);
            if (index >= 0 && index < _audioTracks.length) {
              final track = _audioTracks[index];
              setState(() => _currentAudio = selected);
              widget.onAudioSelect(
                track['subjectId'] ?? '',
                track['detailPath'] ?? '',
                track['lanName'] ?? 'Unknown',
              );
            }
            widget.onTap();
          },
        );
      },
    );
  }
}
