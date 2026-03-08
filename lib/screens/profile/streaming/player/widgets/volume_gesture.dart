import 'package:flutter/material.dart';
import 'package:volume_controller/volume_controller.dart';

class VolumeGesture extends StatefulWidget {
  final bool showControls;

  const VolumeGesture({
    Key? key,
    required this.showControls,
  }) : super(key: key);

  @override
  State<VolumeGesture> createState() => _VolumeGestureState();
}

class _VolumeGestureState extends State<VolumeGesture> {
  double? _volume;
  bool _showIndicator = false;
  final VolumeController _volumeController = VolumeController();

  @override
  void initState() {
    super.initState();
    // Initialize volume controller
    _volumeController.showSystemUI = false;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (details) async {
          if (widget.showControls) return;
          
          try {
            final currentVolume = await _volumeController.getVolume();
            final delta = -details.delta.dy / 300;
            final newVolume = (currentVolume + delta).clamp(0.0, 1.0);
            
            // Only update if there's actual change
            if ((newVolume - currentVolume).abs() > 0.01) {
              _volumeController.setVolume(newVolume, showSystemUI: false);
              setState(() {
                _volume = newVolume;
                _showIndicator = true;
              });
            }
          } catch (e) {
            debugPrint('Volume error: $e');
          }
        },
        onVerticalDragStart: (_) async {
          // Store initial volume
          try {
            final currentVolume = await _volumeController.getVolume();
            setState(() => _volume = currentVolume);
          } catch (e) {
            debugPrint('Volume init error: $e');
          }
        },
        onVerticalDragEnd: (_) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) setState(() => _showIndicator = false);
          });
        },
        child: _showIndicator && _volume != null
            ? Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _volume! > 0 ? Icons.volume_up : Icons.volume_off,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_volume! * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'MazzardH',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
