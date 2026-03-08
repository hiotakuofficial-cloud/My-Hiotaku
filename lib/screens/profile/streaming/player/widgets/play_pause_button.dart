import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class PlayPauseButton extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;

  const PlayPauseButton({
    Key? key,
    required this.player,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.playing,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return GestureDetector(
          onTap: () {
            player.playOrPause();
            onTap();
          },
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 150),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 64,
            ),
          ),
        );
      },
    );
  }
}
