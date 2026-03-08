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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
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
          onSelect: (selected) {
            final index = options.indexOf(selected);
            if (index >= 0 && index < _audioTracks.length) {
              final track = _audioTracks[index];
              widget.onAudioSelect(
                track['subjectId'] ?? '',
                track['detailPath'] ?? '',
                track['lanName'] ?? 'Unknown',
              );
            }
            widget.onTap();
          },
        ),
        // Badge showing count
        if (_audioTracks.isNotEmpty)
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
                '${_audioTracks.length}',
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
