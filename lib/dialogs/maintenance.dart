import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MaintenanceDialog extends StatelessWidget {
  final VoidCallback onGoWatch;

  const MaintenanceDialog({super.key, required this.onGoWatch});

  static Future<void> show(BuildContext context, VoidCallback onGoWatch) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, _, __) => MaintenanceDialog(onGoWatch: onGoWatch),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(28),
        elevation: 16,
        shadowColor: Colors.black.withOpacity(0.6),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, color: Color(0xFFFF3B5C), size: 48),
              const SizedBox(height: 20),
              const Text(
                'This Section is Under Maintenance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  fontFamily: 'MazzardH',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This side is under maintenance right now. Please continue watching your series or movie from the watch page.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.4,
                  fontFamily: 'MazzardH',
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => SystemNavigator.pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Close', style: TextStyle(fontSize: 16, fontFamily: 'MazzardH')),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onGoWatch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B5C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text('Go Watch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'MazzardH')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
