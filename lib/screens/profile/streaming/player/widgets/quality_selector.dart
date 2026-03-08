import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'glassmorphic_bottom_sheet.dart';

class QualitySelector extends StatefulWidget {
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
  State<QualitySelector> createState() => _QualitySelectorState();
}

class _QualitySelectorState extends State<QualitySelector> {
  String? _currentQuality;

  @override
  void initState() {
    super.initState();
    _loadCurrentQuality();
  }

  Future<void> _loadCurrentQuality() async {
    final prefs = await SharedPreferences.getInstance();
    final savedQuality = prefs.getString('preferred_quality') ?? '360';
    setState(() => _currentQuality = '${savedQuality}p');
  }

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
          options: widget.availableQualities,
          currentSelection: _currentQuality,
          onSelect: (quality) {
            setState(() => _currentQuality = quality);
            widget.onQualityChange(quality);
            widget.onTap();
          },
        );
      },
    );
  }
}
