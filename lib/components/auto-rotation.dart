import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';

class AutoRotationReminder {
  static Timer? _timer;
  static bool _hasShown = false;
  static const platform = MethodChannel('com.hiotaku.app/auto_rotation');

  static void checkAndShow(BuildContext context) {
    if (_hasShown) return;
    
    // Check after 5 seconds
    _timer = Timer(Duration(seconds: 5), () {
      _checkAutoRotation(context);
    });
  }

  static void _checkAutoRotation(BuildContext context) async {
    try {
      // Check if auto-rotation is enabled using native method
      final isAutoRotationEnabled = await platform.invokeMethod('isAutoRotationEnabled');
      
      if (!isAutoRotationEnabled && context.mounted) {
        _hasShown = true;
        _showAutoRotationDialog(context);
      }
    } catch (e) {
      // Silent error handling
    }
  }

  static void _showAutoRotationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF8C00).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.screen_rotation,
                      color: Color(0xFFFF8C00),
                      size: 32,
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Auto Rotation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Message
                  Text(
                    'For FullScreen Experience We Recommend you to Turn On Auto Rotation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white.withOpacity(0.8),
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 12),
                      
                      // Turn On Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _openAutoRotationSettings();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF8C00),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                          ),
                          child: Text(
                            'Turn On',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void _openAutoRotationSettings() async {
    try {
      // Use native method to open settings
      await platform.invokeMethod('openAutoRotationSettings');
    } catch (e) {
      // Silent error handling
    }
  }

  static void dispose() {
    _timer?.cancel();
    _timer = null;
    _hasShown = false;
  }
}
