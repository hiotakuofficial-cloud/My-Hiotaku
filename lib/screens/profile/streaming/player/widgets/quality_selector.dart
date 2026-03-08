import 'package:flutter/material.dart';
import 'glassmorphic_bottom_sheet.dart';

class QualitySelector extends StatelessWidget {
  final List<String> availableQualities;
  final Function(String) onQualityChange;
  final VoidCallback onTap;

  const QualitySelector({
    Key? key,
    required this.availableQualities,
    required this.onQualityChange,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Image.asset(
        'assets/player/player_settings.png',
        width: 20,
        height: 20,
        color: Colors.white,
        errorBuilder: (_, __, ___) => const Icon(Icons.settings, color: Colors.white, size: 20),
      ),
      onPressed: () {
        GlassmorphicBottomSheet.show(
          context: context,
          title: 'Quality',
          options: availableQualities,
          onSelect: (quality) {
            onQualityChange(quality);
            onTap();
          },
        );
      },
    );
  }
}
