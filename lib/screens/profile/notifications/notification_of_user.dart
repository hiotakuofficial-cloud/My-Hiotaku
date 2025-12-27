import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'handler/notification_of_user_handler.dart';
import '../../errors/loading_error.dart';

class NotificationOfUser extends StatefulWidget {
  const NotificationOfUser({Key? key}) : super(key: key);

  @override
  State<NotificationOfUser> createState() => _NotificationOfUserState();
}

class _NotificationOfUserState extends State<NotificationOfUser> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _loadNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final notifications = await NotificationOfUserHandler.getUserNotifications();
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load notifications';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    await NotificationOfUserHandler.markAsRead(notificationId);
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['is_read'] = true;
      }
    });
  }

  Future<void> _deleteNotification(String notificationId) async {
    final success = await NotificationOfUserHandler.deleteNotification(notificationId);
    if (success) {
      setState(() {
        _notifications.removeWhere((n) => n['id'] == notificationId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification deleted'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to delete notification'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showNotificationOptions(Map<String, dynamic> notification) {
    final isPublic = notification['is_public'] == true;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (notification['is_read'] != true)
              ListTile(
                leading: const Icon(Icons.mark_email_read, color: Colors.blue),
                title: const Text('Mark as Read', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _markAsRead(notification['id'].toString());
                },
              ),
            if (!isPublic)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteNotification(notification['id'].toString());
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(String? dateString) {
    if (dateString == null) return '';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'sync_request':
        return Icons.sync;
      case 'sync_accepted':
        return Icons.check_circle;
      case 'new_episode':
        return Icons.play_circle;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'sync_request':
        return Colors.orange;
      case 'sync_accepted':
        return Colors.green;
      case 'new_episode':
        return Colors.blue;
      case 'announcement':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final title = notification['title']?.toString() ?? 'Notification';
    final message = notification['message']?.toString() ?? '';
    final type = notification['type']?.toString();
    final isRead = notification['is_read'] == true;
    final isPublic = notification['is_public'] == true;
    final createdAt = notification['created_at'] as String?;
    final timeAgo = _getTimeAgo(createdAt);
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                if (!isRead) {
                  _markAsRead(notification['id'].toString());
                }
              },
              onLongPress: () {
                HapticFeedback.heavyImpact();
                _showNotificationOptions(notification);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: !isRead 
                        ? _getNotificationColor(type).withOpacity(0.3)
                        : Colors.grey[800]!, 
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getNotificationColor(type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getNotificationIcon(type),
                        color: _getNotificationColor(type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isPublic)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'PUBLIC',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (message.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (timeAgo.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              timeAgo,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Color(0xFFFF8C00),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/Empty.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications here when you receive them',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: _isLoading
              ? Center(
                  child: Lottie.asset(
                    'assets/animations/loading.json',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                )
              : _error != null
                  ? LoadingErrorScreen(
                      errorMessage: _error,
                      onRetry: _loadNotifications,
                    )
                  : _notifications.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          child: Column(
                            children: [
                              // Header
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Notifications',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 48), // Balance the back button
                                  ],
                                ),
                              ),
                              // Empty state
                              Container(
                                height: MediaQuery.of(context).size.height - 200,
                                child: _buildEmptyState(),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadNotifications,
                          color: Color(0xFFFF8C00),
                          backgroundColor: const Color(0xFF1E1E1E),
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                            slivers: [
                              // Header
                              SliverToBoxAdapter(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Notifications',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 48), // Balance the back button
                                    ],
                                  ),
                                ),
                              ),
                              // Notifications list
                              SliverPadding(
                                padding: const EdgeInsets.all(16),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      return _buildNotificationItem(_notifications[index]);
                                    },
                                    childCount: _notifications.length,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
        ),
      ),
    );
  }
}
