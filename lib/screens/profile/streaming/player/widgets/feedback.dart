import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../dialogs/thanks_for_feedback.dart';

class FeedbackWidget extends StatefulWidget {
  const FeedbackWidget({Key? key}) : super(key: key);

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _sendFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) return;

    setState(() => _isSending = true);

    // Redirect to Telegram
    final telegramUrl = 'https://t.me/pihupiya?text=${Uri.encodeComponent(feedback)}';
    final uri = Uri.parse(telegramUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Wait 3 seconds then show thank you dialog
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() => _isSending = false);
      Navigator.pop(context); // Close feedback widget
      showThanksForFeedbackDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Feedback',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MazzardH',
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackController,
            maxLines: 5,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontFamily: 'MazzardH',
            ),
            decoration: InputDecoration(
              hintText: 'Share your thoughts...',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontFamily: 'MazzardH',
              ),
              filled: true,
              fillColor: const Color(0xFF2E2E2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC143C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: const Color(0xFFDC143C).withOpacity(0.5),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'MazzardH',
                      ),
                    ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
