import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const ChatBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ChatBottomNav> createState() => _ChatBottomNavState();
}

class _ChatBottomNavState extends State<ChatBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    _scaleAnimations = _controllers
        .map((controller) => Tween<double>(begin: 1.0, end: 0.85)
            .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)))
        .toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_filled,
              label: 'Home',
              isSelected: widget.currentIndex == 0,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.forum_rounded,
              label: 'Chats',
              isSelected: widget.currentIndex == 1,
            ),
            _buildNavItem(
              index: 2,
              customIcon: 'assets/icons/hisu.png',
              label: 'Hisu',
              isSelected: widget.currentIndex == 2,
              isSpecial: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    IconData? icon,
    String? customIcon,
    required String label,
    required bool isSelected,
    bool isSpecial = false,
  }) {
    return Expanded(
      child: AnimatedBuilder(
        animation: _scaleAnimations[index],
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimations[index].value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTapDown: (_) {
                  _controllers[index].forward();
                },
                onTapUp: (_) {
                  _controllers[index].reverse();
                },
                onTapCancel: () {
                  _controllers[index].reverse();
                },
                onTap: () {
                  HapticFeedback.mediumImpact();
                  widget.onTap(index);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: 80,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isSpecial 
                            ? Color(0xFF6C5CE7).withOpacity(0.15)
                            : Color(0xFF2196F3).withOpacity(0.15))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(
                            color: isSpecial 
                                ? Color(0xFF6C5CE7).withOpacity(0.3)
                                : Color(0xFF2196F3).withOpacity(0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        width: isSelected ? 32 : 28,
                        height: isSelected ? 32 : 28,
                        decoration: isSelected && isSpecial
                            ? BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : null,
                        child: customIcon != null
                            ? Padding(
                                padding: EdgeInsets.all(isSelected && isSpecial ? 6 : 0),
                                child: Image.asset(
                                  customIcon,
                                  width: isSelected ? 20 : 24,
                                  height: isSelected ? 20 : 24,
                                  color: isSelected && isSpecial
                                      ? Colors.white
                                      : isSelected
                                          ? Color(0xFF2196F3)
                                          : Colors.white.withOpacity(0.6),
                                ),
                              )
                            : Icon(
                                icon,
                                size: isSelected ? 26 : 24,
                                color: isSelected
                                    ? Color(0xFF2196F3)
                                    : Colors.white.withOpacity(0.6),
                              ),
                      ),
                      SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: Duration(milliseconds: 300),
                        style: TextStyle(
                          color: isSelected
                              ? (isSpecial 
                                  ? Color(0xFF6C5CE7)
                                  : Color(0xFF2196F3))
                              : Colors.white.withOpacity(0.6),
                          fontSize: isSelected ? 12 : 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        child: Text(label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
