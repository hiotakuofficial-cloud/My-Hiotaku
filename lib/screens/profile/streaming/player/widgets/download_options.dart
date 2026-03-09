import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';

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
  String? _selectedQuality;
  late Map<String, dynamic> _selectedLanguage;
  bool _isDownloading = false;
  bool _showLanguageSelection = false;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.availableLanguages.isNotEmpty
        ? widget.availableLanguages.first
        : {};
  }

  Future<bool> _requestPermissions() async {
    final notificationStatus = await Permission.notification.request();
    
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
    if (_isDownloading || _selectedQuality == null) return;
    
    setState(() => _isDownloading = true);
    
    final hasPermissions = await _requestPermissions();
    
    if (!hasPermissions) {
      if (mounted) setState(() => _isDownloading = false);
      Fluttertoast.showToast(msg: 'Permissions required for download');
      return;
    }

    final subjectId = _selectedLanguage['subjectId'] as String? ?? '';
    final detailPath = _selectedLanguage['detailPath'] as String? ?? '';
    
    widget.onDownload(_selectedQuality!, subjectId, detailPath);
  }

  void _goToLanguageSelection() {
    if (widget.availableLanguages.isEmpty) {
      _handleDownload();
    } else {
      setState(() => _showLanguageSelection = true);
    }
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
            _buildHeader(),
            const Divider(color: Color(0xFF333333), height: 1),
            const SizedBox(height: 20),
            Expanded(
              child: _showLanguageSelection 
                  ? _buildLanguageList() 
                  : _buildQualityList(),
            ),
            const SizedBox(height: 20),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (_showLanguageSelection)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => setState(() => _showLanguageSelection = false),
            ),
          Expanded(
            child: Text(
              _showLanguageSelection ? 'Select Language' : 'Select Quality',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'MazzardH',
              ),
            ),
          ),
          if (_showLanguageSelection) const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildQualityList() {
    if (widget.isLoading) return _buildShimmerLoading();
    
    return ListView.builder(
      itemCount: widget.availableQualities.length,
      itemBuilder: (context, index) {
        final quality = widget.availableQualities[index];
        final isSelected = quality == _selectedQuality;
        
        return GestureDetector(
          onTap: () => setState(() => _selectedQuality = quality),
          child: _buildSelectionTile(quality, isSelected),
        );
      },
    );
  }

  Widget _buildLanguageList() {
    return ListView.builder(
      itemCount: widget.availableLanguages.length,
      itemBuilder: (context, index) {
        final lang = widget.availableLanguages[index];
        final isSelected = lang['subjectId'] == _selectedLanguage['subjectId'];
        final lanName = lang['lanName'] as String? ?? 'Unknown';
        
        return GestureDetector(
          onTap: () => setState(() => _selectedLanguage = lang),
          child: _buildSelectionTile(lanName, isSelected),
        );
      },
    );
  }

  Widget _buildSelectionTile(String label, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 60,
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
              label,
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
    );
  }

  Widget _buildActionButton() {
    if (!_showLanguageSelection && _selectedQuality == null) {
      return const SizedBox.shrink();
    }

    final buttonText = _showLanguageSelection ? 'Download' : 'Next';
    final onPressed = _showLanguageSelection ? _handleDownload : _goToLanguageSelection;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isDownloading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC143C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'MazzardH',
          ),
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
            height: 60,
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
