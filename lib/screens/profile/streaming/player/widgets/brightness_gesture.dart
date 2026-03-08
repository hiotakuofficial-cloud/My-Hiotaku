import 'package:flutter/material.dart';
import 'package:screen_brightness/screen_brightness.dart';

class BrightnessGesture extends StatefulWidget {
  final bool showControls;

  const BrightnessGesture({
    Key? key,
    required this.showControls,
  }) : super(key: key);

  @override
  State<BrightnessGesture> createState() => _BrightnessGestureState();
}

class _BrightnessGestureState extends State<BrightnessGesture> {
  double? _brightness;
  bool _showIndicator = false;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width / 2,
      child: GestureDetector(
        onVerticalDragUpdate: (details) async {
          if (widget.showControls) return;
          
          try {
            final currentBrightness = await ScreenBrightness().current;
            final delta = -details.delta.dy / 500;
            final newBrightness = (currentBrightness + delta).clamp(0.0, 1.0);
            
            await ScreenBrightness().setScreenBrightness(newBrightness);
            setState(() {
              _brightness = newBrightness;
              _showIndicator = true;
            });
          } catch (e) {
            debugPrint('Brightness error: $e');
          }
        },
        onVerticalDragEnd: (_) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) setState(() => _showIndicator = false);
          });
        },
        child: _showIndicator && _brightness != null
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
                      const Icon(Icons.brightness_6, color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '${(_brightness! * 100).toInt()}%',
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
