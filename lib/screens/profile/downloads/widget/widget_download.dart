import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../handler/download_handler.dart';

class DownloadWidget extends StatefulWidget {
  final int animeId;
  final String animeTitle;

  const DownloadWidget({
    Key? key,
    required this.animeId,
    required this.animeTitle,
  }) : super(key: key);

  @override
  _DownloadWidgetState createState() => _DownloadWidgetState();
}

class _DownloadWidgetState extends State<DownloadWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoading = true;
  bool _isWebViewMode = false;
  bool _showAllDownloads = false;
  String? _error;
  List<ZipDownload>? _zipDownloads;
  String _currentUrl = '';
  
  late WebViewController _webViewController;
  bool _isPageLoading = true;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    
    _loadZipDownloads();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadZipDownloads() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DownloadHandler.getZipDownloads(widget.animeId);
      
      if (response.success && response.data != null) {
        setState(() {
          _zipDownloads = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load ZIP downloads';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _openWebView(String url) {
    setState(() {
      _isWebViewMode = true;
      _currentUrl = url;
      _isPageLoading = true;
      _loadingProgress = 0;
    });
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isPageLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isPageLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // Block redirects - only allow the original URL
            if (request.url == _currentUrl) {
              return NavigationDecision.navigate;
            }
            // Block all other redirects/ads
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  void _closeWebView() {
    setState(() {
      _isWebViewMode = false;
      _currentUrl = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: _isWebViewMode 
          ? MediaQuery.of(context).size.height 
          : MediaQuery.of(context).size.height * 0.7,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: _isWebViewMode 
                ? BorderRadius.zero 
                : BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _isWebViewMode ? _buildWebView() : _buildDownloadLinks(),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: WillPopScope(
        onWillPop: () async {
          if (await _webViewController.canGoBack()) {
            _webViewController.goBack();
            return false;
          }
          return false; // Don't close bottom sheet on back press
        },
        child: Scaffold(
          backgroundColor: Color(0xFF121212),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarBrightness: Brightness.dark,
              statusBarIconBrightness: Brightness.light,
              statusBarColor: Colors.transparent,
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Color(0xFFFF8C00)),
              onPressed: _closeWebView,
            ),
            title: Text(
              'Download',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.white),
                color: Color(0xFF1E1E1E),
                onSelected: (value) async {
                  switch (value) {
                    case 'refresh':
                      _webViewController.reload();
                      break;
                    case 'chrome':
                      final Uri url = Uri.parse(_currentUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                      break;
                    case 'desktop':
                      _webViewController.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36');
                      _webViewController.reload();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text('Refresh Page', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'chrome',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_browser, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text('Open in Chrome', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'desktop',
                    child: Row(
                      children: [
                        Icon(Icons.desktop_windows, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text('Desktop Mode', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              if (_isPageLoading)
                LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
                ),
              Expanded(
                child: WebViewWidget(controller: _webViewController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadLinks() {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[600],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.download, color: Color(0xFFFF8C00), size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download Links',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.animeTitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: _isLoading
              ? _buildLoading()
              : _error != null
                  ? _buildError()
                  : _buildLinksList(),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF8C00)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading ZIP downloads...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Failed to load ZIP downloads',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadZipDownloads,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8C00),
                foregroundColor: Colors.white,
              ),
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksList() {
    if (_zipDownloads == null || _zipDownloads!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive_outlined,
              color: Colors.white.withOpacity(0.5),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No ZIP downloads available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final displayCount = _showAllDownloads ? _zipDownloads!.length : 3;
    final showButton = _zipDownloads!.length > 3;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: displayCount.clamp(0, _zipDownloads!.length),
            itemBuilder: (context, index) {
              final zipDownload = _zipDownloads![index];
              return _buildZipDownloadItem(zipDownload, index == displayCount - 1 && !showButton);
            },
          ),
        ),
        if (showButton && !_showAllDownloads)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF121212).withOpacity(0.0),
                  Color(0xFF121212).withOpacity(0.8),
                  Color(0xFF121212),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAllDownloads = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8C00),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Show More (${_zipDownloads!.length - 3})'),
                    SizedBox(width: 8),
                    Icon(Icons.expand_more, size: 20),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildZipDownloadItem(ZipDownload zipDownload, bool isLast) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openWebView(zipDownload.url),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF8C00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.archive,
                    color: Color(0xFFFF8C00),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zipDownload.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF8C00).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              zipDownload.quality,
                              style: TextStyle(
                                color: Color(0xFFFF8C00),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            zipDownload.platform,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.download,
                  color: Color(0xFFFF8C00),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
