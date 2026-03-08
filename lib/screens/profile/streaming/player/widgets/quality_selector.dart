import 'package:flutter/material.dart';

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
      icon: const Icon(Icons.settings, color: Colors.white, size: 20),
      onPressed: () {
        _showQualityDialog(context);
      },
    );
  }

  void _showQualityDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E).withOpacity(0.95),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quality',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'MazzardH',
              ),
            ),
            const SizedBox(height: 16),
            ...availableQualities.map((quality) => ListTile(
              title: Text(
                quality,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'MazzardH',
                ),
              ),
              onTap: () {
                onQualityChange(quality);
                Navigator.pop(context);
                onTap();
              },
            )),
          ],
        ),
      ),
    );
  }
}
