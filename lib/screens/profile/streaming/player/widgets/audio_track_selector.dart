import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class AudioTrackSelector extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;

  const AudioTrackSelector({
    Key? key,
    required this.player,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.audiotrack, color: Colors.white, size: 20),
      onPressed: () {
        // TODO: Show audio track selection dialog
        onTap();
      },
    );
  }
}
