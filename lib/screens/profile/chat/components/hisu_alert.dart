import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// iOS-style smooth alert dialog for Hisu AI privacy notice
class HisuAlert {
  /// Show privacy notice dialog
  static Future<void> showPrivacyNotice(BuildContext context) async {
    return showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const _HisuPrivacyDialog();
      },
    );
  }
}

class _HisuPrivacyDialog extends StatelessWidget {
  const _HisuPrivacyDialog();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Column(
        children: [
          Icon(
            CupertinoIcons.lock_shield,
            size: 48,
            color: CupertinoColors.systemBlue,
          ),
          SizedBox(height: 12),
          Text(
            'Privacy & Security',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      content: const Padding(
        padding: EdgeInsets.only(top: 12),
        child: Text(
          'Hisu AI does not save any personal or sensitive data. '
          'We do not use your conversations to train our models.\n\n'
          'Your privacy is our priority - feel free to talk about anything with Hisu.\n\n'
          '⚠️ Reminder: Your chats will be deleted if you uninstall Hiotaku or clear app data.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Got it',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }
}

/// Material Design version (fallback for Android)
class HisuAlertMaterial {
  static Future<void> showPrivacyNotice(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1e1e1e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.lock_outline,
                size: 48,
                color: Colors.blue,
              ),
              SizedBox(height: 12),
              Text(
                'Privacy & Security',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Hisu AI does not save any personal or sensitive data. '
            'We do not use your conversations to train our models.\n\n'
            'Your privacy is our priority - feel free to talk about anything with Hisu.\n\n'
            '⚠️ Reminder: Your chats will be deleted if you uninstall Hiotaku or clear app data.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Got it',
                style: TextStyle(
                  color: Colors.blue,
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
}
