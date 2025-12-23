import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
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
  late AnimationController _tabController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _tabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
    _loadRequests();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
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
      _tabController.forward().then((_) => _tabController.reverse());
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _showRequestOptions(Map<String, dynamic> request) {
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
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove Request', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmRemoveRequest(request);
              },
            ),
          ],
        ),
      ),
    );
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
          content: const Text('Failed to remove request'),
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
    final success = await RequestsHandler.acceptRequest(requestId);
    
    if (success) {
      setState(() {
        final index = _receivedRequests.indexWhere((r) => r['id'] == request['id']);
        if (index != -1) {
          _receivedRequests[index]['status'] = 'accepted';
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request accepted!'),
          backgroundColor: Colors.green[600],
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
          content: const Text('Request rejected'),
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
              isReceived ? CupertinoIcons.tray : CupertinoIcons.paperplane,
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
              CupertinoIcons.exclamationmark_triangle,
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 36),
        const Text(
          'Requests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTapDown: (_) => HapticFeedback.lightImpact(),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.pop(context);
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[800]?.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.back,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTapDown: (_) => HapticFeedback.lightImpact(),
              onTap: () => _switchTab(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.orange[600] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.orange[600] : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
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
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> currentRequests) {
    if (_isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
            strokeWidth: 2.5,
          ),
        ),
      );
    }
    
    if (_error != null) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        child: _buildErrorState(),
      );
    }
    
    if (currentRequests.isEmpty) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.5,
        child: _buildEmptyState(),
      );
    }
    
    return Column(
      children: currentRequests.asMap().entries.map((entry) {
        return _buildRequestItem(entry.value, entry.key);
      }).toList(),
    );
  }
}
