import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class BufferIndicator extends StatelessWidget {
  final Player player;

  const BufferIndicator({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: player.stream.buffering,
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE5003C),
              strokeWidth: 3,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
