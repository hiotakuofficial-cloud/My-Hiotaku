import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class PipButton extends StatelessWidget {
  final Player player;
  final VoidCallback onTap;

  const PipButton({
    Key? key,
    required this.player,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.picture_in_picture_alt, color: Colors.white, size: 20),
      onPressed: () {
        // TODO: Implement PiP mode
        onTap();
      },
    );
  }
}
