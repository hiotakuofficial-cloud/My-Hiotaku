import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PipButton extends StatelessWidget {
  final VoidCallback onTap;

  const PipButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  Future<void> _enterPiP() async {
    try {
      const platform = MethodChannel('com.hiotaku.app/pip');
      await platform.invokeMethod('enterPiP');
    } catch (e) {
      debugPrint('PiP error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Image.asset(
        'assets/player/pip.png',
        width: 20,
        height: 20,
        color: Colors.white,
        errorBuilder: (_, __, ___) => const Icon(Icons.picture_in_picture_alt, color: Colors.white, size: 20),
      ),
      onPressed: () {
        _enterPiP();
        onTap();
      },
    );
  }
}
