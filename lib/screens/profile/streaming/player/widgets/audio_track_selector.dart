import 'package:flutter/material.dart';
import '../../../../../services/moviebox_service.dart';

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
    return IconButton(
      icon: const Icon(Icons.audiotrack, color: Colors.white, size: 20),
      onPressed: () {
        if (_audioTracks.isEmpty) return;
        _showAudioDialog(context);
      },
    );
  }

  void _showAudioDialog(BuildContext context) {
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
              'Audio Track',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'MazzardH',
              ),
            ),
            const SizedBox(height: 16),
            ..._audioTracks.map((track) {
              final lanName = track['lanName'] ?? 'Unknown';
              final isOriginal = track['original'] == true;
              final type = track['type'] == 0 ? 'dub' : 'sub';
              
              return ListTile(
                title: Text(
                  lanName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'MazzardH',
                  ),
                ),
                trailing: isOriginal
                    ? const Icon(Icons.check, color: Color(0xFFE5003C), size: 20)
                    : null,
                subtitle: Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                    fontFamily: 'MazzardH',
                  ),
                ),
                onTap: () {
                  widget.onAudioSelect(
                    track['subjectId'] ?? '',
                    track['detailPath'] ?? '',
                    lanName,
                  );
                  Navigator.pop(context);
                  widget.onTap();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
