import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _debugInfo = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedTab = 0; // 0 = Sent, 1 = Received

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadRequests();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    print('_loadRequests called');
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _debugInfo = 'Loading...';
      });

      print('Loading both sent and received requests');
      final sentRequests = await RequestsHandler.getSentRequests();
      final receivedRequests = await RequestsHandler.getReceivedRequests();
      
      print('Got sent: ${sentRequests.length}, received: ${receivedRequests.length}');
      
      if (mounted) {
        setState(() {
          _sentRequests = sentRequests;
          _receivedRequests = receivedRequests;
          _isLoading = false;
          _debugInfo = 'Sent: ${sentRequests.length}, Received: ${receivedRequests.length}';
        });
        _animationController.forward();
        print('UI updated with requests');
      }
    } catch (e) {
      print('Error in _loadRequests: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load requests. Please check your connection and try again.';
          _isLoading = false;
          _debugInfo = 'Error: $e';
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await _loadRequests();
  }

  Future<void> _createTestRequest() async {
    HapticFeedback.lightImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating test request...'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    final success = await RequestsHandler.createTestRequest();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test request created!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create test request'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showRequestOptions(Map<String, dynamic> request) {
    final status = RequestsHandler.getRequestStatus(request);
    
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
            if (status == 'expired') ...[
              ListTile(
                leading: const Icon(Icons.info_outline, color: Colors.orange),
                title: const Text('View Details', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  RequestsHandler.handleExpiredRequest(context, request);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Remove', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _removeRequest(request);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeRequest(Map<String, dynamic> request) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedTab == 0) {
        _sentRequests.removeWhere((r) => r['id'] == request['id']);
      } else {
        _receivedRequests.removeWhere((r) => r['id'] == request['id']);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Request removed'),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildRequestItem(Map<String, dynamic> request, int index) {
    final status = RequestsHandler.getRequestStatus(request);
    final isReceived = _selectedTab == 1;
    
    final displayName = isReceived 
        ? (request['sender_username']?.toString() ?? 
           request['sender_email']?.toString() ?? 
           'Unknown User')
        : (request['receiver_username']?.toString() ?? 
           request['receiver_email']?.toString() ?? 
           'Unknown User');
    
    final message = request['message']?.toString() ?? 'Sync request';
    final createdAt = request['created_at'] as String?;
    final timeAgo = _getTimeAgo(createdAt);
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.elasticOut),
      )),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[800]!, width: 0.5),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: RequestsHandler.getStatusColor(status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              RequestsHandler.getStatusIcon(status),
              color: RequestsHandler.getStatusColor(status),
              size: 24,
            ),
          ),
          title: Text(
            'Sync Request',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${isReceived ? 'From' : 'To'}: $displayName',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: RequestsHandler.getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      RequestsHandler.getStatusText(status),
                      style: TextStyle(
                        color: RequestsHandler.getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[400]),
            onPressed: () => _showRequestOptions(request),
          ),
          onTap: status == 'expired' 
            ? () => RequestsHandler.handleExpiredRequest(context, request)
            : null,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sync_disabled,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'No Sync Requests',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your sent sync requests will appear here',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _debugInfo,
            style: TextStyle(
              color: Colors.orange[400],
              fontSize: 12,
            ),
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
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
                borderRadius: BorderRadius.circular(8),
              ),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SYNC REQUESTS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _handleRefresh,
            ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.orange),
            onPressed: _createTestRequest,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.orange[600] : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Sent (${_sentRequests.length})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTab == 0 ? Colors.white : Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.orange[600] : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Received (${_receivedRequests.length})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTab == 1 ? Colors.white : Colors.grey[400],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Colors.orange[600],
        backgroundColor: const Color(0xFF1E1E1E),
        child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
                strokeWidth: 2,
              ),
            )
          : _error != null
            ? _buildErrorState()
            : currentRequests.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: currentRequests.length,
                    itemBuilder: (context, index) => _buildRequestItem(currentRequests[index], index),
                  ),
                ),
      ),
    );
  }
}
