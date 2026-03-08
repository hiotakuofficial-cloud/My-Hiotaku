import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Handles video player lifecycle events
/// - Auto PiP on app minimize
/// - Audio focus management for calls
class VideoLifecycleController extends WidgetsBindingObserver {
  final VoidCallback onEnterPiP;
  final VoidCallback onPauseForCall;
  final VoidCallback onResumeAfterCall;
  
  bool _wasPlayingBeforeInactive = false;

  VideoLifecycleController({
    required this.onEnterPiP,
    required this.onPauseForCall,
    required this.onResumeAfterCall,
  });

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // App going to background - enter PiP
        _wasPlayingBeforeInactive = true;
        _enterPiPMode();
        break;
        
      case AppLifecycleState.paused:
        // App fully paused (call incoming or switched app)
        onPauseForCall();
        break;
        
      case AppLifecycleState.resumed:
        // App resumed - restore audio if was playing
        if (_wasPlayingBeforeInactive) {
          onResumeAfterCall();
          _wasPlayingBeforeInactive = false;
        }
        break;
        
      case AppLifecycleState.detached:
        // App closing
        break;
        
      case AppLifecycleState.hidden:
        // App hidden
        break;
    }
  }

  Future<void> _enterPiPMode() async {
    try {
      const platform = MethodChannel('com.hiotaku.app/pip');
      await platform.invokeMethod('enterPiP');
      onEnterPiP();
    } catch (e) {
      debugPrint('PiP error: $e');
    }
  }
}
