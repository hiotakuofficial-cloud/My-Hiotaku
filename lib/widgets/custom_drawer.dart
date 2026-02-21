
import 'package:flutter/material.dart';

class CustomDrawer extends StatefulWidget {
  final Widget mainScreen;
  final Widget drawerScreen;

  const CustomDrawer({
    super.key,
    required this.mainScreen,
    required this.drawerScreen,
  });

  @override
  CustomDrawerState createState() => CustomDrawerState();
}

class CustomDrawerState extends State<CustomDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final double _drawerWidthFraction = 0.75;
  bool _isDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addStatusListener((status) {
      setState(() {
        _isDrawerOpen = status == AnimationStatus.completed;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggle() {
    if (_animationController.isCompleted) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double maxSlide = screenWidth * _drawerWidthFraction;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        double delta = details.primaryDelta! / maxSlide;
        _animationController.value += delta;
      },
      onHorizontalDragEnd: (details) {
        if (_animationController.value < 0.5) {
          _animationController.reverse();
        } else {
          _animationController.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, _) {
          double slide = maxSlide * _animationController.value;

          return Stack(
            children: [
              // Drawer Screen
              Transform.translate(
                offset: Offset(
                    -screenWidth * (1 - _drawerWidthFraction) * (1 - _animationController.value),
                    0),
                child: SizedBox(
                  width: maxSlide,
                  child: widget.drawerScreen,
                ),
              ),
              // Main Screen
              Transform(
                transform: Matrix4.identity()..translate(slide),
                alignment: Alignment.centerLeft,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                                0.3 * _animationController.value),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: widget.mainScreen,
                    ),
                    // Gradient overlay
                    if (_animationController.value > 0)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.0),
                                  Colors.white.withOpacity(
                                      0.4 * _animationController.value),
                                ],
                                stops: const [0.5, 1.0],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Click outside to close
                    if (_isDrawerOpen)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: toggle,
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
