import 'package:flutter/material.dart';

class PillButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String text;
  final bool autoStart;

  const PillButton({
    super.key,
    this.onPressed,
    required this.text,
    this.autoStart = true,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> with TickerProviderStateMixin {
  late AnimationController _borderAnimationController;
  late Animation<double> _borderWidthAnimation;
  late Animation<Color?> _borderColorAnimation;

  late AnimationController _dotAnimationController;
  late List<Animation<double>> _dotScaleAnimations;

  bool _isButtonAnimating = false;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController for the border animation
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Duration for one full pulse cycle
    );

    // Define the animation for the border width
    _borderWidthAnimation = Tween<double>(begin: 2.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _borderAnimationController,
        curve: Curves.easeInOutSine, // Provides a smooth, oscillating effect
      ),
    );

    // Define the animation for the border color
    _borderColorAnimation = ColorTween(
      begin: Colors.red.shade900, // Crimson red start color
      end: Colors.red.shade400, // Slightly lighter red for the pulse peak
    ).animate(
      CurvedAnimation(
        parent: _borderAnimationController,
        curve: Curves.easeInOutSine, // Matches the width animation curve
      ),
    );

    // Initialize the AnimationController for the three dots animation
    _dotAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900), // Duration for one full dot bounce cycle
    );

    // Define staggered scale animations for each of the three dots
    _dotScaleAnimations = List<Animation<double>>.generate(3, (int index) {
      return Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(
          parent: _dotAnimationController,
          curve: Interval(
            (index * 0.2), // Stagger the start time for each dot
            (index * 0.2) + 0.6, // Define the peak time for the bounce for each dot
            curve: Curves.easeInOutCubic, // Stronger, more noticeable bounce
          ),
        ),
      );
    });

    // Auto-start animation if enabled
    if (widget.autoStart) {
      _isButtonAnimating = true;
      _borderAnimationController.repeat(reverse: true);
      _dotAnimationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _dotAnimationController.dispose();
    super.dispose();
  }

  void _onButtonPressed() {
    setState(() {
      _isButtonAnimating = !_isButtonAnimating;
    });

    if (_isButtonAnimating) {
      // Start both animations to repeat in reverse for a continuous pulsating effect
      _borderAnimationController.repeat(reverse: true);
      _dotAnimationController.repeat(reverse: true);
    } else {
      // Stop both animations and reset them to their initial state
      _borderAnimationController.stop();
      _dotAnimationController.stop();
      _borderAnimationController.reset();
      _dotAnimationController.reset();
    }
    widget.onPressed?.call(); // Call the user-defined onPressed callback
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onButtonPressed,
      child: AnimatedBuilder(
        // Listen to both animation controllers to rebuild the UI when values change
        animation: Listenable.merge([_borderAnimationController, _dotAnimationController]),
        builder: (BuildContext context, Widget? child) {
          final double currentBorderWidth = _borderWidthAnimation.value;
          final Color? currentBorderColor = _borderColorAnimation.value;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.black, // Button's background color
              borderRadius: BorderRadius.circular(50.0), // Creates the pill shape
              border: Border.all(
                color: currentBorderColor ??
                    Colors.red.shade900, // Fallback to crimson red
                width: currentBorderWidth, // Animated border width
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                    scale: animation, child: child); // Scale transition for content switch
              },
              child: _isButtonAnimating
                  ? KeyedSubtree(
                      key: const ValueKey<bool>(true), // Unique key for AnimatedSwitcher
                      child: Row(
                        mainAxisSize: MainAxisSize.min, // Constrain row size to its children
                        children: List<Widget>.generate(3, (int index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: ScaleTransition(
                              scale: _dotScaleAnimations[index], // Animated scale for each dot
                              child: Container(
                                width: 8.0,
                                height: 8.0,
                                decoration: const BoxDecoration(
                                  color: Colors.white, // Color of the dots
                                  shape: BoxShape.circle, // Circular dots
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    )
                  : KeyedSubtree(
                      key: const ValueKey<bool>(false), // Unique key for AnimatedSwitcher
                      child: Text(
                        widget.text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18.0), // Button's text style
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
