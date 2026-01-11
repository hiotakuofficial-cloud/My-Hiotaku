import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ChatLoadingWidget extends StatelessWidget {
  final String? message;
  final bool showAnimation;

  const ChatLoadingWidget({
    Key? key,
    this.message,
    this.showAnimation = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showAnimation) ...[
            Container(
              width: 80,
              height: 80,
              child: Lottie.asset(
                'assets/animations/loading.json',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 20),
          ] else ...[
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.7),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
          Text(
            message ?? 'Loading chat...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ChatEmptyWidget extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;

  const ChatEmptyWidget({
    Key? key,
    this.title,
    this.subtitle,
    this.icon,
    this.onAction,
    this.actionText,
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
            ),
          ),
          SizedBox(height: 20),
          Text(
            title ?? 'No Messages Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            subtitle ?? 'Start a conversation by sending\nyour first message',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionText != null) ...[
            SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(0xFF2196F3).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    actionText!,
                    style: TextStyle(
                      color: Color(0xFF2196F3),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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

class ChatErrorWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final bool isMinimal;

  const ChatErrorWidget({
    Key? key,
    this.title,
    this.message,
    this.onRetry,
    this.isMinimal = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isMinimal) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.red.withOpacity(0.7),
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message ?? 'Something went wrong',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: Colors.white.withOpacity(0.6),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.red.withOpacity(0.7),
              size: 28,
            ),
          ),
          SizedBox(height: 16),
          Text(
            title ?? 'Error',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            message ?? 'Something went wrong',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
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
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Try Again',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
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
