import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../widgets/feedback.dart';
import '../widgets/download_options.dart';
import '../controller/download_controller.dart';

class ActionButtonController {
  /// Share content with Android share dialog
  static Future<void> share({
    required String title,
    required String type, // 'Movie' or 'Series'
  }) async {
    final message = '''
🎬 Watch $type: $title

📱 Download Hiotaku App
🔗 https://www.hiotaku.in/

📋 Instructions:
1. Download and install the app
2. Go to Profile section
3. Select Streaming
4. Search for "$title"
5. Enjoy watching! 🍿
''';

    await Share.share(
      message,
      subject: 'Watch $title on Hiotaku',
    );
  }

  /// Show feedback dialog
  static void feedback(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FeedbackWidget(),
    );
  }

  /// Start download
  static void download(
    BuildContext context, {
    required String videoUrl,
    required String title,
    required int season,
    required int episode,
    required List<String> availableQualities,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DownloadOptionsBottomSheet(
        title: title,
        availableQualities: availableQualities,
        onDownload: (quality) async {
          final controller = DownloadController();
          await controller.downloadEpisode(
            videoUrl: videoUrl,
            title: title,
            season: season,
            episode: episode,
            context: context,
          );
        },
      ),
    );
  }

  /// Open downloads folder (placeholder)
  static void viewDownloads() {
    // TODO: Implement view downloads functionality
  }
}
