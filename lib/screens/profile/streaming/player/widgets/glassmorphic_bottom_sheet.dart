import 'package:flutter/material.dart';
import 'dart:ui';

/// Reusable glassmorphic bottom sheet for selections
class GlassmorphicBottomSheet extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? currentSelection;
  final Function(String) onSelect;

  const GlassmorphicBottomSheet({
    Key? key,
    required this.title,
    required this.options,
    this.currentSelection,
    required this.onSelect,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<String> options,
    String? currentSelection,
    required Function(String) onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassmorphicBottomSheet(
        title: title,
        options: options,
        currentSelection: currentSelection,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * 0.45;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: const Color(0xCC0E0E10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 24),
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0B0B0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 29,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'MazzardH',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Options List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: options.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final option = options[index];
                      final isSelected = option == currentSelection;
                      
                      return InkWell(
                        onTap: () {
                          onSelect(option);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                option,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? const Color(0xFFE5003C) : Colors.white,
                                  fontFamily: 'MazzardH',
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check,
                                  size: 24,
                                  color: Color(0xFFE5003C),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
