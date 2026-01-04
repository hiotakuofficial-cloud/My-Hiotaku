import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _showAllDownloads = false;
  bool _showAllEpisodes = false;
  String? _error;
  List<ZipDownload>? _zipDownloads;
  List<DownloadLink>? _episodeLinks;

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
      // Load ZIP downloads
      final zipResponse = await DownloadHandler.getZipDownloads(widget.animeId);
      
      // Load episode downloads  
      final episodeResponse = await DownloadHandler.getDownloadLinks(widget.animeId);
      
      if (zipResponse.success && zipResponse.data != null) {
        setState(() {
          _zipDownloads = zipResponse.data;
          if (episodeResponse.success && episodeResponse.data != null) {
            _episodeLinks = episodeResponse.data!.downloads;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = zipResponse.error ?? 'Failed to load downloads';
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

  Future<void> _openInChrome(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyToClipboard(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard!'),
        backgroundColor: Color(0xFFFF8C00),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDownloadOptions(ZipDownload zipDownload) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
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
            SizedBox(height: 20),
            Text(
              zipDownload.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.open_in_browser, color: Color(0xFFFF8C00)),
              title: Text('Open in Chrome', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _openInChrome(zipDownload.url);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: Color(0xFFFF8C00)),
              title: Text('Copy Link', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(zipDownload.url);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height: MediaQuery.of(context).size.height * 0.7,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _buildDownloadLinks(),
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
    // Check if both ZIP and episodes are empty
    bool hasZipDownloads = _zipDownloads != null && _zipDownloads!.isNotEmpty;
    bool hasEpisodeDownloads = _episodeLinks != null && _episodeLinks!.isNotEmpty;
    
    if (!hasZipDownloads && !hasEpisodeDownloads) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_outlined,
              color: Colors.white.withOpacity(0.5),
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'No downloads available',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ZIP Downloads Section (only if available)
            if (hasZipDownloads) ...[
              ...List.generate((_showAllDownloads ? _zipDownloads!.length : 3).clamp(0, _zipDownloads!.length), (index) {
                final zipDownload = _zipDownloads![index];
                return _buildZipDownloadItem(zipDownload, false);
              }),
              
              // Show More ZIP button
              if (_zipDownloads!.length > 3 && !_showAllDownloads) ...[
                SizedBox(height: 12),
                ElevatedButton(
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
                      Text('Show More ZIP (${_zipDownloads!.length - 3})'),
                      SizedBox(width: 8),
                      Icon(Icons.expand_more, size: 20),
                    ],
                  ),
                ),
              ],
            ],
            
            // Episode Downloads Section (only if available)
            if (hasEpisodeDownloads) ...[
              if (hasZipDownloads) SizedBox(height: 20), // Add spacing if ZIP section exists
              Row(
                children: [
                  Icon(Icons.play_circle_outline, color: Color(0xFFFF8C00), size: 20),
                  SizedBox(width: 8),
                  Text(
                    hasZipDownloads ? 'Episode Downloads' : 'Downloads', // Change title if no ZIP
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              
              // Episode items
              ...List.generate((_showAllEpisodes ? _episodeLinks!.length : 3).clamp(0, _episodeLinks!.length), (index) {
                final link = _episodeLinks![index];
                return _buildEpisodeItem(link);
              }),
              
              // Show More Episodes button
              if (_episodeLinks!.length > 3 && !_showAllEpisodes) ...[
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showAllEpisodes = true;
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
                      Text('Show More Episodes (${_episodeLinks!.length - 3})'),
                      SizedBox(width: 8),
                      Icon(Icons.expand_more, size: 20),
                    ],
                  ),
                ),
              ],
            ],
            
            SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
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
          onTap: () => _showDownloadOptions(zipDownload),
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

  Widget _buildEpisodeItem(DownloadLink link) {
    // Extract quality from episode text if available
    String displayQuality = link.quality ?? 'HD';
    String displayTitle = link.episode ?? 'Episode';
    
    // Try to extract quality from episode text (e.g., "Episode 1 - 1080p")
    if (link.episode != null && link.episode!.contains('1080p')) {
      displayQuality = '1080p';
      displayTitle = link.episode!.replaceAll(' - 1080p', '').replaceAll(' 1080p', '');
    } else if (link.episode != null && link.episode!.contains('720p')) {
      displayQuality = '720p';
      displayTitle = link.episode!.replaceAll(' - 720p', '').replaceAll(' 720p', '');
    } else if (link.episode != null && link.episode!.contains('480p')) {
      displayQuality = '480p';
      displayTitle = link.episode!.replaceAll(' - 480p', '').replaceAll(' 480p', '');
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showDownloadOptions(ZipDownload(
            text: displayTitle,
            url: link.url,
            quality: displayQuality,
            type: link.type ?? 'episode',
            platform: link.platform ?? 'web',
          )),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF8C00),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    displayQuality,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (link.size != null) ...[
                        SizedBox(height: 4),
                        Text(
                          link.size!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.download, color: Colors.white.withOpacity(0.7), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
