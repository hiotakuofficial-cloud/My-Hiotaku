import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';

class DownloadQuality {
  final String label;
  final String resolution;

  const DownloadQuality({
    required this.label,
    required this.resolution,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DownloadQuality && label == other.label;

  @override
  int get hashCode => label.hashCode;
}

class DownloadOptionsBottomSheet extends StatefulWidget {
  final String title;
  final List<String> availableQualities;
  final List<Map<String, dynamic>> availableLanguages;
  final Function(String quality, String subjectId, String detailPath) onDownload;
  final bool isLoading;

  const DownloadOptionsBottomSheet({
    Key? key,
    required this.title,
    required this.availableQualities,
    required this.availableLanguages,
    required this.onDownload,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<DownloadOptionsBottomSheet> createState() => _DownloadOptionsBottomSheetState();
}

class _DownloadOptionsBottomSheetState extends State<DownloadOptionsBottomSheet> {
  late String _selectedQuality;
  late Map<String, dynamic> _selectedLanguage;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _selectedQuality = widget.availableQualities.isNotEmpty 
        ? widget.availableQualities.first 
        : '720p';
    _selectedLanguage = widget.availableLanguages.isNotEmpty
        ? widget.availableLanguages.first
        : {};
  }

  Future<bool> _requestPermissions() async {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    
    // Request storage permission
    PermissionStatus storageStatus;
    if (await Permission.storage.isGranted) {
      storageStatus = PermissionStatus.granted;
    } else {
      storageStatus = await Permission.storage.request();
      if (storageStatus.isDenied) {
        storageStatus = await Permission.manageExternalStorage.request();
      }
    }

    return notificationStatus.isGranted && storageStatus.isGranted;
  }

  Future<void> _handleDownload() async {
    if (_isDownloading) return; // Prevent multiple clicks
    
    setState(() => _isDownloading = true);
    
    // Request permissions
    final hasPermissions = await _requestPermissions();
    
    if (!hasPermissions) {
      if (mounted) setState(() => _isDownloading = false);
      Fluttertoast.showToast(msg: 'Permissions required for download');
      return;
    }

    final subjectId = _selectedLanguage['subjectId'] as String? ?? '';
    final detailPath = _selectedLanguage['detailPath'] as String? ?? '';
    
    // Trigger download
    widget.onDownload(_selectedQuality, subjectId, detailPath);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.6,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MazzardH',
                ),
              ),
            ),
            const Divider(color: Color(0xFF333333), height: 1),
            const SizedBox(height: 20),
            // Quality Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Quality',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'MazzardH',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              flex: 2,
              child: widget.isLoading
                  ? _buildShimmerLoading()
                  : ListView.builder(
                      itemCount: widget.availableQualities.length,
                      itemBuilder: (context, index) {
                        final quality = widget.availableQualities[index];
                        final isSelected = quality == _selectedQuality;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedQuality = quality),
                          child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 50,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFDC143C).withOpacity(0.2)
                            : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFDC143C)
                              : const Color(0xFF333333),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              quality,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'MazzardH',
                              ),
                            ),
                            const Spacer(),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? const Color(0xFFDC143C)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFDC143C)
                                      : const Color(0xFFB0B0B0),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.availableLanguages.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select Language',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'MazzardH',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: widget.availableLanguages.length,
                  itemBuilder: (context, index) {
                    final lang = widget.availableLanguages[index];
                    final isSelected = lang['subjectId'] == _selectedLanguage['subjectId'];
                    final lanName = lang['lanName'] as String? ?? 'Unknown';
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedLanguage = lang),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 50,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFDC143C).withOpacity(0.2)
                              : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFDC143C)
                                : const Color(0xFF333333),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text(
                                lanName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'MazzardH',
                                ),
                              ),
                              const Spacer(),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFFDC143C)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFDC143C)
                                        : const Color(0xFFB0B0B0),
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      fixedSize: const Size.fromHeight(50),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'MazzardH',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDownloading ? null : _handleDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC143C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      fixedSize: const Size.fromHeight(50),
                    ),
                    child: const Text(
                      'Download',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'MazzardH',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFF1E1E1E),
          highlightColor: const Color(0xFF2A2A2A),
          child: Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}
