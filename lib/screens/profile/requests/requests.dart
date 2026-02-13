import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:lottie/lottie.dart';
import 'handler/requests_handler.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({Key? key}) : super(key: key);

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _sentRequests = [];
  List<Map<String, dynamic>> _receivedRequests = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedTab = 0;
  String? _processingRequestId; // Track which request is being processed

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
    _loadRequests();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final sentRequests = await RequestsHandler.getSentRequests();
      final receivedRequests = await RequestsHandler.getReceivedRequests();
      
      if (mounted) {
        setState(() {
          _sentRequests = sentRequests;
          _receivedRequests = receivedRequests;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load requests. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    _animationController.reset();
    await _loadRequests();
  }

  void _switchTab(int tab) {
    if (_selectedTab != tab) {
      HapticFeedback.selectionClick();
      setState(() => _selectedTab = tab);
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _showRequestOptions(Map<String, dynamic> request) {
    final status = RequestsHandler.getRequestStatus(request);
    final isAccepted = status == 'accepted';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
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
            ListTile(
              leading: Icon(
                isAccepted ? Icons.link_off : Icons.delete_outline, 
                color: Colors.red
              ),
              title: Text(
                isAccepted ? 'Disconnect' : 'Remove Request', 
                style: const TextStyle(color: Colors.red)
              ),
              onTap: () {
                Navigator.pop(context);
                if (isAccepted) {
                  _confirmDisconnect(request);
                } else {
                  _confirmRemoveRequest(request);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDisconnect(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Disconnect', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to disconnect? This will remove the connection and shared favorites between you.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _disconnectRequest(request);
            },
            child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _disconnectRequest(Map<String, dynamic> request) async {
    HapticFeedback.mediumImpact();
    final requestId = request['id'].toString();
    final success = await RequestsHandler.disconnectUsers(requestId);
    
    if (success) {
      setState(() {
        _sentRequests.removeWhere((r) => r['id'] == request['id']);
        _receivedRequests.removeWhere((r) => r['id'] == request['id']);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connection removed successfully'),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to remove connection'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmRemoveRequest(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Request', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove this request? This action cannot be undone.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeRequest(request);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _removeRequest(Map<String, dynamic> request) async {
    HapticFeedback.lightImpact();
    
    final requestId = request['id'].toString();
    final success = await RequestsHandler.deleteRequest(requestId);
    
    if (success) {
      setState(() {
        if (_selectedTab == 0) {
          _sentRequests.removeWhere((r) => r['id'] == request['id']);
        } else {
          _receivedRequests.removeWhere((r) => r['id'] == request['id']);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request removed successfully'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to remove request'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showAcceptRejectDialog(Map<String, dynamic> request) {
    final senderName = request['sender_username']?.toString() ?? 'Unknown User';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sync Request', style: TextStyle(color: Colors.white)),
        content: Text(
          'Accept sync request from $senderName?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectRequest(request);
            },
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptRequest(request);
            },
            child: Text('Accept', style: TextStyle(color: Colors.green[400])),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(Map<String, dynamic> request) async {
    HapticFeedback.lightImpact();
    final requestId = request['id'].toString();
    
    // Set loading state for this specific request
    setState(() {
      _processingRequestId = requestId;
    });
    
    // Show merge start toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Syncing favorites...'),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    
    final result = await RequestsHandler.acceptRequest(requestId);
    
    // Clear loading state
    setState(() {
      _processingRequestId = null;
    });
    
    if (result['success']) {
      setState(() {
        final index = _receivedRequests.indexWhere((r) => r['id'] == request['id']);
        if (index != -1) {
          _receivedRequests[index]['status'] = 'accepted';
        }
      });
      
      // Show success message
      final mergeCount = result['merge_count'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mergeCount > 0 
            ? 'Sync completed! $mergeCount favorites merged'
            : 'Sync completed successfully'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // Handle different error types
      String errorMessage = 'Sync request failed';
      
      if (result['error'] == 'limit_exceeded') {
        // Show limit exceeded dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Connection Limit Reached', style: TextStyle(color: Colors.white)),
            content: Text(
              result['message'] ?? 'You have reached your limit of connected experiences. To continue, please remove one connection.',
              style: TextStyle(color: Colors.grey[300]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
        );
        return;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to merge favorites. Please try again.'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _rejectRequest(Map<String, dynamic> request) async {
    HapticFeedback.lightImpact();
    final requestId = request['id'].toString();
    final success = await RequestsHandler.rejectRequest(requestId);
    
    if (success) {
      setState(() {
        final index = _receivedRequests.indexWhere((r) => r['id'] == request['id']);
        if (index != -1) {
          _receivedRequests[index]['status'] = 'rejected';
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request declined'),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildRequestItem(Map<String, dynamic> request, int index) {
    final status = RequestsHandler.getRequestStatus(request);
    final isReceived = _selectedTab == 1;
    final isPending = status == 'pending';
    
    final displayName = isReceived 
        ? (request['sender_username']?.toString() ?? 'Unknown User')
        : (request['receiver_username']?.toString() ?? 'Unknown User');
    
    final message = request['message']?.toString() ?? 'Sync request';
    final createdAt = request['created_at'] as String?;
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
              onTapDown: (_) => HapticFeedback.lightImpact(),
              onTap: isReceived && isPending ? () {
                HapticFeedback.mediumImpact();
                _showAcceptRejectDialog(request);
              } : null,
              onLongPress: () {
                HapticFeedback.heavyImpact();
                _showRequestOptions(request);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPending && isReceived 
                        ? Colors.orange.withOpacity(0.3) 
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
                        color: RequestsHandler.getStatusColor(status).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        RequestsHandler.getStatusIcon(status),
                        color: RequestsHandler.getStatusColor(status),
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
                                  '${isReceived ? 'From' : 'To'}: $displayName',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: RequestsHandler.getStatusColor(status).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  RequestsHandler.getStatusText(status),
                                  style: TextStyle(
                                    color: RequestsHandler.getStatusColor(status),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isReceived && isPending) ...[
                      const SizedBox(width: 8),
                      Icon(
                        CupertinoIcons.chevron_right,
                        color: Colors.grey[500],
                        size: 16,
                      ),
                    ],
                    const SizedBox(width: 8),
                    // Show loading indicator if this request is being processed
                    if (_processingRequestId == request['id'].toString()) ...[
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: Lottie.asset(
                          'assets/animations/loading.json',
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showRequestOptions(request);
                        },
                        child: Icon(
                          Icons.more_vert,
                          color: Colors.grey[500],
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return 'Unknown';
    
    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(created);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildEmptyState() {
    final isReceived = _selectedTab == 1;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              isReceived ? Icons.inbox_outlined : Icons.send_outlined,
              size: 40,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isReceived ? 'No Requests Received' : 'No Requests Sent',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isReceived 
                ? 'Sync requests from other users will appear here'
                : 'Your sent sync requests will appear here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red[900]?.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.red[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error occurred',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadRequests,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRequests = _selectedTab == 0 ? _sentRequests : _receivedRequests;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.orange[600],
        backgroundColor: const Color(0xFF1E1E1E),
        strokeWidth: 2.5,
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! > 0) {
                // Swipe right - go to Sent tab
                if (_selectedTab == 1) _switchTab(0);
              } else if (details.primaryVelocity! < 0) {
                // Swipe left - go to Received tab  
                if (_selectedTab == 0) _switchTab(1);
              }
            }
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 40,
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildTabSelector(),
                    const SizedBox(height: 20),
                    _buildContent(currentRequests),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTapDown: (_) => HapticFeedback.lightImpact(),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 18,
          ),
        ),
        const Text(
          'Requests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 36),
      ],
    );
  }

  Widget _buildTabSelector() {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabWidth = (screenWidth - 40) / 2; // Account for padding
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Background indicator
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: _selectedTab == 0 ? 2 : tabWidth + 2,
            top: 2,
            bottom: 2,
            width: tabWidth - 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange[600],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Tab buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTapDown: (_) => HapticFeedback.lightImpact(),
                  onTap: () => _switchTab(0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Sent (${_sentRequests.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 0 ? Colors.white : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTapDown: (_) => HapticFeedback.lightImpact(),
                  onTap: () => _switchTab(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Received (${_receivedRequests.length})',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _selectedTab == 1 ? Colors.white : Colors.grey[400],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> currentRequests) {
    if (_isLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Center(
          child: Lottie.asset(
            'assets/animations/loading.json',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
      );
    }
    
    if (_error != null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: _buildErrorState(),
      );
    }
    
    if (currentRequests.isEmpty) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: _buildEmptyState(),
      );
    }
    
    // Use flexible layout for cards
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...currentRequests.asMap().entries.map((entry) {
          return _buildRequestItem(entry.value, entry.key);
        }).toList(),
        // Add bottom padding for better scroll experience
        const SizedBox(height: 100),
      ],
    );
  }
}
