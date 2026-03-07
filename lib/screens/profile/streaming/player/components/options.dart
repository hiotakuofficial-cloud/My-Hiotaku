import 'package:flutter/material.dart';

class ButtonData {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const ButtonData({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}

class PlayerOptions extends StatelessWidget {
  final List<ButtonData> actions;

  const PlayerOptions({
    Key? key,
    required this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: actions.map((buttonData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: buttonData.onPressed,
              icon: Icon(buttonData.icon, size: 20),
              label: Text(buttonData.label),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(130, 48),
                backgroundColor: const Color(0xFF1a1a1a),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'MazzardH',
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
