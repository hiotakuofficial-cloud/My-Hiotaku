import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PipButton extends StatelessWidget {
  final VoidCallback onTap;

  const PipButton({
    Key? key,
    required this.onTap,
  }) : super(key: key);

  Future<void> _enterPiP(BuildContext context) async {
    try {
      const platform = MethodChannel('com.hiotaku.app/pip');
      final hasPermission = await platform.invokeMethod<bool>('checkPiPPermission') ?? false;
      
      if (!hasPermission) {
        await platform.invokeMethod('openPiPSettings');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable Picture-in-Picture permission'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      
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
        _enterPiP(context);
        onTap();
      },
    );
  }
}
