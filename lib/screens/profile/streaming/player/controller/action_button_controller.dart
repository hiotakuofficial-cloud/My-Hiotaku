import 'package:share_plus/share_plus.dart';

class ActionButtonController {
  /// Share content with Android share dialog
  static Future<void> share({
    required String title,
    required String type, // 'Movie' or 'Series'
  }) async {
    final message = '''
🎬 Watch $type: $title

📱 Download HiOtaku App
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
      subject: 'Watch $title on HiOtaku',
    );
  }

  /// Show feedback dialog (placeholder)
  static void feedback() {
    // TODO: Implement feedback functionality
  }

  /// Start download (placeholder)
  static void download() {
    // TODO: Implement download functionality
  }

  /// Open downloads folder (placeholder)
  static void viewDownloads() {
    // TODO: Implement view downloads functionality
  }
}
