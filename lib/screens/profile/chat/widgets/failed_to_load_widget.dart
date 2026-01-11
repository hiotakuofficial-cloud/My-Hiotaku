import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class FailedToLoadChatWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? errorMessage;
  final String? customTitle;

  const FailedToLoadChatWidget({
    Key? key,
    this.onRetry,
    this.errorMessage,
    this.customTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            child: Lottie.asset(
              'assets/animations/Empty.json',
              fit: BoxFit.contain,
              repeat: false,
            ),
          ),
          SizedBox(height: 20),
          Text(
            customTitle ?? 'Failed to Load Chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            errorMessage ?? 'Something went wrong while loading the chat.\nPlease try again.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 28),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.white.withOpacity(0.8),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
