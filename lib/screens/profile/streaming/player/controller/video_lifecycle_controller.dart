import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Handles video player lifecycle events
/// - Auto PiP on app minimize
/// - Audio focus management for calls
class VideoLifecycleController extends WidgetsBindingObserver {
  final VoidCallback onEnterPiP;
  final VoidCallback onPauseForCall;
  final VoidCallback onResumeAfterCall;
  final bool Function() isPlaying; // Check if video is actually playing
  
  bool _wasPlayingBeforeInactive = false;

  VideoLifecycleController({
    required this.onEnterPiP,
    required this.onPauseForCall,
    required this.onResumeAfterCall,
    required this.isPlaying,
  });

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state: $state');
    
    switch (state) {
      case AppLifecycleState.inactive:
        // Don't set flag here - wait for actual pause
        break;
        
      case AppLifecycleState.paused:
        // Only mark if video was actually playing
        try {
          _wasPlayingBeforeInactive = isPlaying();
          if (_wasPlayingBeforeInactive) {
            onPauseForCall();
          }
        } catch (e) {
          debugPrint('Error pausing video: $e');
          _wasPlayingBeforeInactive = false;
        }
        break;
        
      case AppLifecycleState.resumed:
        // App resumed - restore audio if was playing
        try {
          if (_wasPlayingBeforeInactive) {
            onResumeAfterCall();
            _wasPlayingBeforeInactive = false;
          }
        } catch (e) {
          debugPrint('Error resuming video: $e');
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
