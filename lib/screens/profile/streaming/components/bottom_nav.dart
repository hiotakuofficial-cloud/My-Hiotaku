import 'dart:ui';
import 'package:flutter/material.dart';

class StreamingBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const StreamingBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<StreamingBottomNav> createState() => _StreamingBottomNavState();
}

class _StreamingBottomNavState extends State<StreamingBottomNav> with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  late Animation<double> _dotAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _dotAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dotController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(StreamingBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _dotController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                // Animated dot indicator
                AnimatedBuilder(
                  animation: _dotAnimation,
                  builder: (context, child) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final navWidth = screenWidth - 40; // minus margins (20 + 20)
                    final itemWidth = navWidth / 4;
                    final startPos = _previousIndex * itemWidth + itemWidth / 2;
                    final endPos = widget.currentIndex * itemWidth + itemWidth / 2;
                    final currentPos = startPos + (endPos - startPos) * _dotAnimation.value;
                    
                    return Positioned(
                      bottom: 8,
                      left: currentPos - 2,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF3B5C),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
                // Nav items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isActive: widget.currentIndex == 0,
                      onTap: () => widget.onTap(0),
                    ),
                    _NavItem(
                      icon: Icons.play_circle_rounded,
                      label: 'Streaming',
                      isActive: widget.currentIndex == 1,
                      onTap: () => widget.onTap(1),
                    ),
                    _NavItem(
                      icon: Icons.download_rounded,
                      label: 'Downloads',
                      isActive: widget.currentIndex == 2,
                      onTap: () => widget.onTap(2),
                    ),
                    _NavItem(
                      icon: Icons.history_rounded,
                      label: 'History',
                      isActive: widget.currentIndex == 3,
                      onTap: () => widget.onTap(3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isActive
                        ? const Color(0xFFFF3B5C)
                        : Colors.white.withOpacity(0.5),
                    size: 26,
                  ),
                  if (widget.isActive) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Color(0xFFFF3B5C),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'MazzardH',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
