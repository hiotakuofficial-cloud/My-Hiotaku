import 'package:flutter/material.dart';

class FullscreenButton extends StatelessWidget {
  final bool isFullscreen;
  final VoidCallback onToggle;

  const FullscreenButton({
    Key? key,
    required this.isFullscreen,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
        color: isFullscreen ? const Color(0xFFE5003C) : Colors.white,
        size: 20,
      ),
      onPressed: onToggle,
    );
  }
}
