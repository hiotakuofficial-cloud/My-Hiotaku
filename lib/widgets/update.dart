import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';

class UpdateChecker {
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await Supabase.instance.client
          .from('updates')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return;

      final latestVersion = response['version'] as String;
      
      if (_isNewerVersion(currentVersion, latestVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, response);
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, Map<String, dynamic> updateData) {
    // Delay to ensure home screen is fully rendered
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!context.mounted) return;
      
      showGeneralDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: false,
        barrierLabel: 'Update',
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return ChangeNotifierProvider<DownloadProgressData>(
            create: (context) => DownloadProgressData(),
            builder: (context, child) => UpdateDialog(updateData: updateData),
          );
        },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, childWidget) {
            return Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: animation.value * 6.0,
                      sigmaY: animation.value * 6.0,
                    ),
                    child: Container(
                      color: Colors.black.withOpacity(animation.value * 0.3),
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                  child: childWidget,
                ),
              ],
            );
          },
          child: child,
        );
      },
    );
    });
  }
}

class DownloadProgressData extends ChangeNotifier {
  bool _isDownloading = false;
  double _progress = 0.0;
  bool _isDownloadComplete = false;
  String? _filePath;

  bool get isDownloading => _isDownloading;
  double get progress => _progress;
  bool get isDownloadComplete => _isDownloadComplete;
  String? get filePath => _filePath;

  Future<void> startDownload(String url) async {
    if (_isDownloading) return;

    _isDownloading = true;
    _progress = 0.0;
    _isDownloadComplete = false;
    notifyListeners();

    try {
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir!.path}/hiotaku_update.apk';
      
      // Delete old APK if exists
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }
      
      final dio = Dio();
      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            _progress = received / total;
            notifyListeners();
          }
        },
        options: Options(
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      _filePath = savePath;
      _isDownloading = false;
      _isDownloadComplete = true;
      notifyListeners();
    } catch (e) {
      _isDownloading = false;
      _progress = 0.0;
      notifyListeners();
      debugPrint('Download failed: $e');
    }
  }

  Future<void> installApk() async {
    if (_filePath != null) {
      await OpenFile.open(_filePath!);
    }
  }
}

class UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateData;

  const UpdateDialog({super.key, required this.updateData});

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _buttonPulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _buttonPulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 1.0, curve: Curves.linear),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double _clampValue(double v) => v.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final double dialogBorderRadius = 28.0;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(dialogBorderRadius),
        ),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: -50,
              right: -50,
              top: -50,
              bottom: -50,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(50),
                  gradient: RadialGradient(
                    colors: [
                      Colors.blueAccent.withOpacity(0.4),
                      Colors.purpleAccent.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    center: Alignment.center,
                    radius: 0.8,
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(dialogBorderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(dialogBorderRadius),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        spreadRadius: -10,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: -5,
                        offset: const Offset(0, -5),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.10),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/update_logo.svg',
                        height: 180,
                        width: 180,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        widget.updateData['update_name'] ?? "New Update Available!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.blueAccent.withOpacity(0.8),
                              blurRadius: 15,
                              offset: Offset.zero,
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.updateData['description'] ?? "A new version is available!",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Version ${widget.updateData['version']}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                side: BorderSide(color: Colors.white.withOpacity(0.4)),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () async {
                                final url = Uri.parse(widget.updateData['link']);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url, mode: LaunchMode.externalApplication);
                                }
                              },
                              child: const Text(
                                "Manually",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Consumer<DownloadProgressData>(
                              builder: (context, downloadData, child) {
                                Color buttonStartColor;
                                Color buttonEndColor;
                                Color buttonShadowColor;
                                String buttonText;
                                Function()? onPressedCallback;
                                double effectivePulseValue;

                                if (downloadData.isDownloading) {
                                  buttonText = "Downloading...";
                                  onPressedCallback = null;
                                  buttonStartColor = Colors.grey.shade600;
                                  buttonEndColor = Colors.grey.shade700;
                                  buttonShadowColor = Colors.grey.shade400;
                                  effectivePulseValue = 1.0;
                                } else if (downloadData.isDownloadComplete) {
                                  buttonText = "Install Now";
                                  onPressedCallback = () async {
                                    await downloadData.installApk();
                                  };
                                  buttonStartColor = Colors.green.shade600;
                                  buttonEndColor = Colors.green.shade400;
                                  buttonShadowColor = Colors.greenAccent;
                                  effectivePulseValue = _buttonPulseAnimation.value;
                                } else {
                                  buttonText = "Download";
                                  onPressedCallback = () {
                                    downloadData.startDownload(widget.updateData['link']);
                                  };
                                  buttonStartColor = const Color(0xFF4A90E2);
                                  buttonEndColor = const Color(0xFF00C6FF);
                                  buttonShadowColor = Colors.blueAccent;
                                  effectivePulseValue = _buttonPulseAnimation.value;
                                }

                                return AnimatedBuilder(
                                  animation: downloadData.isDownloading || downloadData.isDownloadComplete
                                      ? const AlwaysStoppedAnimation<double>(1.0)
                                      : _buttonPulseAnimation,
                                  builder: (context, childWidget) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        gradient: LinearGradient(
                                          colors: [buttonStartColor, buttonEndColor],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: buttonShadowColor.withOpacity(0.6 * effectivePulseValue),
                                            blurRadius: 20 * effectivePulseValue,
                                            spreadRadius: 1 * effectivePulseValue,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: onPressedCallback,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                AnimatedBuilder(
                                                  animation: _shimmerAnimation,
                                                  builder: (context, shimmerChild) {
                                                    if (downloadData.isDownloading || downloadData.isDownloadComplete) {
                                                      return shimmerChild!;
                                                    }
                                                    return ShaderMask(
                                                      shaderCallback: (bounds) {
                                                        return LinearGradient(
                                                          colors: const [Colors.white54, Colors.white, Colors.white54],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                          stops: [
                                                            _clampValue(_shimmerAnimation.value - 0.3),
                                                            _clampValue(_shimmerAnimation.value),
                                                            _clampValue(_shimmerAnimation.value + 0.3),
                                                          ],
                                                        ).createShader(bounds);
                                                      },
                                                      child: shimmerChild,
                                                    );
                                                  },
                                                  child: Text(
                                                    buttonText,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                                if (downloadData.isDownloading) ...[
                                                  const SizedBox(height: 8),
                                                  Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                                    child: LinearProgressIndicator(
                                                      value: downloadData.progress,
                                                      backgroundColor: Colors.white.withOpacity(0.3),
                                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  ),
                                                ],
                                                if (downloadData.isDownloadComplete) ...[
                                                  const SizedBox(height: 8),
                                                  const Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: <Widget>[
                                                        Icon(Icons.check_circle, color: Colors.white, size: 18),
                                                        SizedBox(width: 6),
                                                        Text("Tap to Install", style: TextStyle(color: Colors.white, fontSize: 11)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
