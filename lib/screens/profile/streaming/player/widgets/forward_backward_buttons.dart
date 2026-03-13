import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class ForwardBackwardButtons extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;

  const ForwardBackwardButtons({
    Key? key,
    required this.player,
    required this.onTap,
  }) : super(key: key);

  void _seekBackward() {
    final currentPosition = player.state.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    player.seek(newPosition.isNegative ? Duration.zero : newPosition);
    onTap();
  }

  void _seekForward() {
    final currentPosition = player.state.position;
    final duration = player.state.duration;
    final newPosition = currentPosition + const Duration(seconds: 10);
    player.seek(newPosition > duration ? duration : newPosition);
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Backward 10s
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
            onPressed: _seekBackward,
          ),
        ),
        const SizedBox(width: 40),
        // Forward 10s
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
            onPressed: _seekForward,
          ),
        ),
      ],
    );
  }
}
