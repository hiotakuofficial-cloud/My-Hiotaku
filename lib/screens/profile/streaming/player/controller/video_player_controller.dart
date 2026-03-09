import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../../../services/moviebox_service.dart';
import 'video_lifecycle_controller.dart';
import 'audio_handler.dart';

class VideoPlayerController extends ChangeNotifier {
  final String initialVideoUrl;
  final String subjectId;
  final String detailPath;
  final int season;
  final int episode;
  final List<String> availableQualities;

  late Player player;
  late VideoController videoController;
  late VideoLifecycleController lifecycleController;
  
  bool isInitialized = false;
  bool isBuffering = true;
  bool showControls = false;
  bool isFullscreen = false;
  
  String currentVideoUrl = '';
  String? currentAudioLanguage;
  Timer? hideTimer;
  Timer? _progressTimer;
  double _savedVolume = 1.0;
  int _lastSavedSecond = 0;
  Function()? onEpisodeEnd;

  VideoPlayerController({
    required this.initialVideoUrl,
    required this.subjectId,
    required this.detailPath,
    required this.season,
    required this.episode,
    required this.availableQualities,
  }) {
    currentVideoUrl = initialVideoUrl;
    player = Player();
    videoController = VideoController(player);
    
    // Initialize lifecycle controller
    lifecycleController = VideoLifecycleController(
      onEnterPiP: () {
        debugPrint('Entered PiP mode');
      },
      onPauseForCall: () {
        // Lower volume for call (audio ducking)
        _savedVolume = player.state.volume;
        player.setVolume(_savedVolume * 0.2); // 20% volume during call
        debugPrint('Audio ducked for call');
      },
      onResumeAfterCall: () {
        // Restore full volume after call
        player.setVolume(_savedVolume);
        debugPrint('Audio restored after call');
      },
    );
    lifecycleController.initialize();
    
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await player.open(
        Media(
          currentVideoUrl,
          httpHeaders: {
            'Referer': 'https://themoviebox.org/',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36',
          },
        ),
      );

      // Listen to streams
      player.stream.buffering.listen((buffering) {
        isBuffering = buffering;
        notifyListeners();
      });

      player.stream.playing.listen((playing) {
        notifyListeners(); // Notify UI to update play/pause button
        if (playing && showControls) {
          startHideTimer();
        }
      });

      // Listen to position and save progress periodically
      _progressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (!isInitialized) {
          timer.cancel();
          return;
        }
        final currentSecond = player.state.position.inSeconds;
        if (currentSecond > 0) {
          _saveProgress(currentSecond);
        }
      });

      // Clear progress when video completes
      player.stream.completed.listen((completed) {
        if (completed) {
          _clearProgress();
          // Auto-play next episode
          if (onEpisodeEnd != null) {
            onEpisodeEnd!();
          }
        }
      });

      // Check for episode end (last 30 seconds)
      player.stream.position.listen((position) {
        final duration = player.state.duration;
        if (AudioHandler.hasEpisodeEnded(position, duration)) {
          // Trigger auto-play next episode
          if (onEpisodeEnd != null) {
            onEpisodeEnd!();
          }
        }
      });

      await player.play();

      // Resume from saved position after player is ready
      final prefs = await SharedPreferences.getInstance();
      final savedPosition = prefs.getInt('${subjectId}_s${season}_e${episode}_position') ?? 0;
      
      if (savedPosition > 5) {
        // Wait for player to be ready and buffering to complete
        await Future.delayed(const Duration(milliseconds: 3000));
        await player.pause();
        await player.seek(Duration(seconds: savedPosition));
        await Future.delayed(const Duration(milliseconds: 500));
        await player.play();
      }

      isInitialized = true;
      isBuffering = false;
      showControls = true;
      notifyListeners();

      startHideTimer();
    } catch (e) {
      isBuffering = false;
      notifyListeners();
      debugPrint('Player init error: $e');
    }
  }

  void toggleControls() {
    showControls = !showControls;
    if (showControls) startHideTimer();
    notifyListeners();
  }

  void startHideTimer() {
    hideTimer?.cancel();
    hideTimer = Timer(const Duration(seconds: 3), () {
      if (player.state.playing) {
        showControls = false;
        notifyListeners();
      }
    });
  }

  Future<void> changeQuality(String quality) async {
    isBuffering = true;
    notifyListeners();

    try {
      // Save quality preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_quality', quality.replaceAll('p', ''));
      
      final playData = await MovieBoxService.getPlayUrls(
        id: subjectId,
        path: detailPath,
        season: season,
        episode: episode,
      );

      final streams = playData['data']?['streams'] as List? ?? [];
      final stream = streams.firstWhere(
        (s) => s['resolutions'] == quality.replaceAll('p', ''),
        orElse: () => streams.first,
      );

      final newUrl = stream['url'] as String? ?? '';
      if (newUrl.isNotEmpty) {
        final currentPosition = player.state.position;

        await player.open(
          Media(
            newUrl,
            httpHeaders: {
              'Referer': 'https://themoviebox.org/',
              'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36',
            },
          ),
        );

        await player.play();
        await Future.delayed(const Duration(milliseconds: 2000));
        await player.pause();
        await player.seek(currentPosition);
        await player.play();

        currentVideoUrl = newUrl;
      }
    } catch (e) {
      debugPrint('Quality change error: $e');
    }

    isBuffering = false;
    notifyListeners();
  }

  Future<void> changeAudioTrack(String newSubjectId, String newDetailPath) async {
    isBuffering = true;
    notifyListeners();

    try {
      // Get preferred quality
      final prefs = await SharedPreferences.getInstance();
      final savedQuality = prefs.getString('preferred_quality') ?? '720';

      final playData = await MovieBoxService.getPlayUrls(
        id: newSubjectId,
        path: newDetailPath,
        season: season,
        episode: episode,
      );

      final streams = playData['data']?['streams'] as List? ?? [];
      if (streams.isEmpty) {
        isBuffering = false;
        notifyListeners();
        return;
      }

      final stream = streams.firstWhere(
        (s) => s['resolutions'] == savedQuality,
        orElse: () => streams.first,
      );

      final newUrl = stream['url'] as String? ?? '';
      if (newUrl.isNotEmpty) {
        final currentPosition = player.state.position;

        await player.open(
          Media(
            newUrl,
            httpHeaders: {
              'Referer': 'https://themoviebox.org/',
              'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36',
            },
          ),
        );

        await player.play();
        await Future.delayed(const Duration(milliseconds: 2000));
        await player.pause();
        await player.seek(currentPosition);
        await player.play();

        currentVideoUrl = newUrl;
      }
    } catch (e) {
      debugPrint('Audio track change error: $e');
    }

    isBuffering = false;
    notifyListeners();
  }

  Future<void> changeAudioTrackWithLanguage(String newSubjectId, String newDetailPath, String language) async {
    // Save preferred language
    await AudioHandler.savePreferredLanguage(language);
    currentAudioLanguage = language;
    
    // Change audio track
    await changeAudioTrack(newSubjectId, newDetailPath);
  }

  Future<String?> getPreferredAudioLanguage() async {
    return await AudioHandler.getPreferredLanguage();
  }

  Future<void> setSubtitle(String url, String language) async {
    try {
      if (url.isEmpty || language == 'Off') {
        await player.setSubtitleTrack(SubtitleTrack.no());
        debugPrint('Subtitles turned off');
      } else {
        await player.setSubtitleTrack(
          SubtitleTrack.uri(url, title: language, language: language),
        );
        debugPrint('Subtitle loaded: $language');
      }
    } catch (e) {
      debugPrint('Subtitle error: $e');
    }
  }

  Future<void> _saveProgress(int seconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${subjectId}_s${season}_e${episode}_position';
      await prefs.setInt(key, seconds);
    } catch (e) {
      debugPrint('Save progress error: $e');
    }
  }

  Future<void> _clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${subjectId}_s${season}_e${episode}_position');
    } catch (e) {
      debugPrint('Clear progress error: $e');
    }
  }

  @override
  void dispose() {
    hideTimer?.cancel();
    _progressTimer?.cancel();
    lifecycleController.dispose();
    player.dispose();
    super.dispose();
  }
}
