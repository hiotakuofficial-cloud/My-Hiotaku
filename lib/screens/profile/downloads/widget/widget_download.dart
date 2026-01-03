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
  String? _error;
  AnimeDetails? _animeDetails;
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
    
    _loadDownloadLinks();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadDownloadLinks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await DownloadHandler.getDownloadLinks(widget.animeId);
      
      if (response.success && response.data != null) {
        setState(() {
          _animeDetails = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load download links';
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

  Map<String, List<DownloadLink>> _categorizeLinks() {
    if (_animeDetails == null) return {};
    
    Map<String, List<DownloadLink>> categories = {};
    
    for (var link in _animeDetails!.downloads) {
      String category = 'Other';
      
      if (link.episode?.contains('1080') == true) {
        category = '1080p HD';
      } else if (link.episode?.contains('720') == true) {
        category = '720p HD';
      } else if (link.episode?.contains('480') == true) {
        category = '480p SD';
      } else if (link.episode?.toLowerCase().contains('complete') == true) {
        category = 'Complete Pack';
      }
      
      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(link);
    }
    
    return categories;
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
            'Loading download links...',
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
              'Failed to load download links',
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
              onPressed: _loadDownloadLinks,
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
    final categories = _categorizeLinks();
    
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.link_off,
              color: Colors.white.withOpacity(0.5),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No download links available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories.keys.elementAt(index);
        final links = categories[category]!;
        
        return _buildCategorySection(category, links);
      },
    );
  }

  Widget _buildCategorySection(String category, List<DownloadLink> links) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF8C00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: Color(0xFFFF8C00),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  '${links.length} link${links.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ...links.asMap().entries.map((entry) {
            final index = entry.key;
            final link = entry.value;
            final isLast = index == links.length - 1;
            
            return _buildLinkItem(link, isLast);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLinkItem(DownloadLink link, bool isLast) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _openWebView(link.url);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Color(0xFFFF8C00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.link,
                color: Color(0xFFFF8C00),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.episode ?? 'Download Link',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (link.platform != null) ...[
                    SizedBox(height: 4),
                    Text(
                      'Platform: ${link.platform}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.4),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
