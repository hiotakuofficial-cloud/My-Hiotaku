import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Announcement checker - fetches from Supabase using server time
class AnnouncementChecker {
  static Future<void> checkForAnnouncements(BuildContext context) async {
    try {
      // Fetch active announcements using server-side view (server time check)
      final response = await Supabase.instance.client
          .from('active_announcements')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return;

      if (context.mounted) {
        _showAnnouncementDialog(context, response);
      }
    } catch (e) {
      debugPrint('Announcement check failed: $e');
    }
  }

  static void _showAnnouncementDialog(BuildContext context, Map<String, dynamic> data) {
    // Delay to ensure screen is fully rendered
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!context.mounted) return;
      
      showAnnouncementDialog(
        context,
        title: data['title'] ?? 'Announcement',
        description: data['description'] ?? '',
        buttonText: 'Got it',
      );
    });
  }
}

/// Show announcement dialog with dark theme
void showAnnouncementDialog(BuildContext context, {
  required String title,
  required String description,
  String buttonText = 'Got it',
}) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      );
    },
  );
}
