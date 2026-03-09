import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'network_controller.dart';
import '../dialogs/file_exists_dialog.dart';

class DownloadController extends ChangeNotifier {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: Duration.zero,
      sendTimeout: const Duration(seconds: 30),
    ),
  );
  
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final NetworkController _networkController = NetworkController();
  
  bool isDownloading = false;
  bool isPaused = false;
  double downloadProgress = 0.0;
  String? downloadError;
  CancelToken? _cancelToken;
  
  // Speed tracking
  int _lastReceivedBytes = 0;
  DateTime _lastUpdateTime = DateTime.now();
  double downloadSpeed = 0.0; // bytes per second
  
  // Current download info
  String? _currentVideoUrl;
  String? _currentFilePath;
  String? _currentTitle;
  int? _currentSeason;
  int? _currentEpisode;

  DownloadController() {
    _initNotifications();
    _networkController.setOnConnectionRestored(() {
      if (isPaused && _currentVideoUrl != null) {
        resumeDownload();
      }
    });
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }
      return status.isGranted;
    }
    return true;
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload == 'cancel') {
          cancelDownload();
        } else if (details.payload == 'pause') {
          pauseDownload();
        } else if (details.payload == 'resume') {
          resumeDownload();
        }
      },
    );
  }

  Future<void> _showDownloadNotification() async {
    final speedMB = (downloadSpeed / 1024 / 1024).toStringAsFixed(2);
    final progressPercent = (downloadProgress * 100).toStringAsFixed(1);
    final progressInt = (downloadProgress * 100).toInt();
    
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Downloads',
      channelDescription: 'Episode download progress',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progressInt,
      ongoing: true,
      autoCancel: false,
    );

    await _notifications.show(
      0,
      'Downloading Episode',
      '$progressPercent% • $speedMB MB/s',
      NotificationDetails(android: androidDetails),
      payload: 'download',
    );
  }

  void _calculateSpeed(int received) {
    final now = DateTime.now();
    final timeDiff = now.difference(_lastUpdateTime).inMilliseconds;
    
    if (timeDiff > 500) { // Update every 500ms
      final bytesDiff = received - _lastReceivedBytes;
      downloadSpeed = (bytesDiff / timeDiff) * 1000; // bytes per second
      _lastReceivedBytes = received;
      _lastUpdateTime = now;
    }
  }

  Future<String?> downloadEpisode({
    required String videoUrl,
    required String title,
    required int season,
    required int episode,
    required BuildContext context,
  }) async {
    if (isDownloading) return null;

    // Save current download info
    _currentVideoUrl = videoUrl;
    _currentTitle = title;
    _currentSeason = season;
    _currentEpisode = episode;

    // Request permission
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      downloadError = 'Storage permission denied';
      notifyListeners();
      return null;
    }

    try {
      // Get public Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      // Create anime folder structure
      final animeFolderName = title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final animeFolderPath = '${downloadsDir!.path}/$animeFolderName';
      final animeFolder = Directory(animeFolderPath);
      
      if (!await animeFolder.exists()) {
        await animeFolder.create(recursive: true);
      }

      // Create filename
      final fileName = '$animeFolderName - EP$episode.mp4';
      _currentFilePath = '$animeFolderPath/$fileName';

      // Check if file already exists
      final file = File(_currentFilePath!);
      if (await file.exists()) {
        // Show dialog
        final shouldDownload = await showFileExistsDialog(context, _currentFilePath!);
        if (shouldDownload != true) {
          return null; // User cancelled
        }
        // Rename existing file with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final newPath = _currentFilePath!.replaceAll('.mp4', '_$timestamp.mp4');
        await file.rename(newPath);
      }

      isDownloading = true;
      isPaused = false;
      downloadProgress = 0.0;
      _lastReceivedBytes = 0;
      _lastUpdateTime = DateTime.now();
      downloadError = null;
      _cancelToken = CancelToken();
      notifyListeners();

      // Check for partial download (resume support)
      int downloadedBytes = 0;
      final existingFile = File(_currentFilePath!);
      if (await existingFile.exists()) {
        downloadedBytes = await existingFile.length();
        _lastReceivedBytes = downloadedBytes;
      }

      // Download with resume support
      await _dio.download(
        videoUrl,
        _currentFilePath!,
        cancelToken: _cancelToken,
        options: Options(
          headers: {
            'Referer': 'https://themoviebox.org/',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36',
            'Connection': 'keep-alive',
            if (downloadedBytes > 0) 'Range': 'bytes=$downloadedBytes-',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final totalBytes = downloadedBytes + total;
            final receivedBytes = downloadedBytes + received;
            downloadProgress = receivedBytes / totalBytes;
            
            _calculateSpeed(receivedBytes);
            _showDownloadNotification();
            notifyListeners();
          }
        },
        deleteOnError: false,
      );

      isDownloading = false;
      await _notifications.cancel(0);
      notifyListeners();
      return _currentFilePath;
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        // Network error - pause for auto-resume
        isPaused = true;
        isDownloading = false;
      } else {
        isDownloading = false;
        downloadError = e.toString();
      }
      notifyListeners();
      return null;
    }
  }

  void pauseDownload() {
    _cancelToken?.cancel('Paused by user');
    isPaused = true;
    isDownloading = false;
    notifyListeners();
  }

  Future<void> resumeDownload() async {
    if (_currentVideoUrl == null || _currentFilePath == null) return;
    
    isDownloading = true;
    isPaused = false;
    _lastUpdateTime = DateTime.now();
    _cancelToken = CancelToken();
    notifyListeners();

    try {
      // Check partial file for resume
      int downloadedBytes = 0;
      final file = File(_currentFilePath!);
      if (await file.exists()) {
        downloadedBytes = await file.length();
        _lastReceivedBytes = downloadedBytes;
      }

      // Resume download
      await _dio.download(
        _currentVideoUrl!,
        _currentFilePath!,
        cancelToken: _cancelToken,
        options: Options(
          headers: {
            'Referer': 'https://themoviebox.org/',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36',
            'Connection': 'keep-alive',
            if (downloadedBytes > 0) 'Range': 'bytes=$downloadedBytes-',
          },
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final totalBytes = downloadedBytes + total;
            final receivedBytes = downloadedBytes + received;
            downloadProgress = receivedBytes / totalBytes;
            
            _calculateSpeed(receivedBytes);
            _showDownloadNotification();
            notifyListeners();
          }
        },
        deleteOnError: false,
      );

      isDownloading = false;
      await _notifications.cancel(0);
      notifyListeners();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        isPaused = true;
        isDownloading = false;
      } else {
        isDownloading = false;
        downloadError = e.toString();
      }
      notifyListeners();
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel('Download cancelled by user');
    isDownloading = false;
    isPaused = false;
    downloadProgress = 0.0;
    
    // Delete partial file
    if (_currentFilePath != null) {
      final file = File(_currentFilePath!);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
    
    _notifications.cancel(0);
    notifyListeners();
  }

  @override
  void dispose() {
    _dio.close();
    _networkController.dispose();
    _notifications.cancel(0);
    super.dispose();
  }
}
