import 'dart:async';
import 'package:flutter/material.dart';

/// Data model for context menu item
class MenuItemData {
  final IconData icon;
  final String text;
  final Color iconColor;
  final Color textColor;
  final VoidCallback? onPressed;

  MenuItemData({
    required this.icon,
    required this.text,
    this.iconColor = Colors.white,
    this.textColor = Colors.white,
    this.onPressed,
  });
}

/// Custom context menu item widget
class CustomContextMenuItem extends PopupMenuEntry<String> {
  final MenuItemData itemData;
  final ValueChanged<String> onSelected;

  const CustomContextMenuItem({
    super.key,
    required this.itemData,
    required this.onSelected,
  });

  @override
  double get height => kMinInteractiveDimension + 8.0;

  @override
  bool represents(String? value) => value == itemData.text;

  @override
  State<CustomContextMenuItem> createState() => _CustomContextMenuItemState();
}

class _CustomContextMenuItemState extends State<CustomContextMenuItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.itemData.onPressed?.call();
        widget.onSelected(widget.itemData.text);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(widget.itemData.icon, color: widget.itemData.iconColor),
            const SizedBox(width: 16.0),
            Text(
              widget.itemData.text,
              style: TextStyle(color: widget.itemData.textColor, fontSize: 16.0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Context menu manager mixin
mixin ContextMenuMixin<T extends StatefulWidget> on State<T>, SingleTickerProviderStateMixin<T> {
  late AnimationController animationController;
  late Animation<double> fadeAnimation;
  late Animation<double> scaleAnimation;
  OverlayEntry? overlayEntry;
  Completer<String?>? menuCompleter;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );
    scaleAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    overlayEntry?.remove();
    if (menuCompleter != null && !menuCompleter!.isCompleted) {
      menuCompleter!.complete(null);
      menuCompleter = null;
    }
    super.dispose();
  }

  /// Show animated context menu at position
  Future<String?> showAnimatedContextMenu(
    BuildContext context,
    Offset globalPosition,
    List<MenuItemData> menuItems,
  ) async {
    if (overlayEntry != null) {
      dismissOverlay(null);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    menuCompleter = Completer<String?>();

    overlayEntry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => dismissOverlay(null),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            Positioned(
              left: globalPosition.dx,
              top: globalPosition.dy,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (BuildContext context, Widget? child) {
                    final double currentScale = (animationController.status == AnimationStatus.forward ||
                            animationController.status == AnimationStatus.completed)
                        ? scaleAnimation.value
                        : 1.0;

                    return Transform.scale(
                      scale: currentScale,
                      alignment: Alignment.topLeft,
                      child: child,
                    );
                  },
                  child: Material(
                    color: const Color(0xFF121212),
                    elevation: 8.0,
                    borderRadius: BorderRadius.circular(8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: menuItems
                          .map(
                            (item) => CustomContextMenuItem(
                              itemData: item,
                              onSelected: (value) => dismissOverlay(value),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(overlayEntry!);
    animationController.reset();
    animationController.forward();

    return menuCompleter!.future;
  }

  /// Dismiss context menu
  void dismissOverlay(String? selectedValue) {
    if (overlayEntry == null) return;

    if (animationController.status == AnimationStatus.reverse ||
        animationController.status == AnimationStatus.dismissed) {
      if (menuCompleter != null && !menuCompleter!.isCompleted) {
        menuCompleter!.complete(selectedValue);
        menuCompleter = null;
      }
      overlayEntry?.remove();
      overlayEntry = null;
      return;
    }

    animationController.reverse().then((_) {
      if (overlayEntry != null) {
        overlayEntry?.remove();
        overlayEntry = null;
      }
      if (menuCompleter != null && !menuCompleter!.isCompleted) {
        menuCompleter!.complete(selectedValue);
        menuCompleter = null;
      }
    });
  }
}
