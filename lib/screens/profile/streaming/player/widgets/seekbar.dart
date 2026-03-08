import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

class Seekbar extends StatefulWidget {
  final Player player;
  final VoidCallback onSeek;

  const Seekbar({
    Key? key,
    required this.player,
    required this.onSeek,
  }) : super(key: key);

  @override
  State<Seekbar> createState() => _SeekbarState();
}

class _SeekbarState extends State<Seekbar> {
  double? _seekValue;
  bool _isSeeking = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.player.stream.position,
      builder: (context, posSnapshot) {
        return StreamBuilder<Duration>(
          stream: widget.player.stream.duration,
          builder: (context, durSnapshot) {
            final position = posSnapshot.data?.inSeconds.toDouble() ?? 0;
            final duration = durSnapshot.data?.inSeconds.toDouble() ?? 1;

            if (duration < 1) return const SizedBox.shrink();

            final displayPosition = _isSeeking ? (_seekValue ?? position) : position;

            return Column(
              children: [
                // Time Labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(displayPosition),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontFamily: 'MazzardH',
                      ),
                    ),
                    Text(
                      '-${_formatTime(duration - displayPosition)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontFamily: 'MazzardH',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Slider
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: const Color(0xFFE5003C),
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    thumbColor: const Color(0xFFE5003C),
                    overlayColor: const Color(0xFFE5003C).withOpacity(0.3),
                  ),
                  child: Slider(
                    value: displayPosition.clamp(0.0, duration),
                    max: duration,
                    onChanged: (value) {
                      setState(() {
                        _isSeeking = true;
                        _seekValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      widget.player.seek(Duration(seconds: value.toInt()));
                      setState(() {
                        _isSeeking = false;
                        _seekValue = null;
                      });
                      widget.onSeek();
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTime(double seconds) {
    final min = (seconds / 60).floor();
    final sec = (seconds % 60).floor();
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
