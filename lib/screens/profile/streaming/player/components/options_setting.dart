import 'package:flutter/material.dart';
import 'dart:ui';

enum SettingType { speed, quality, language }

class SettingItem {
  final IconData icon;
  final String label;
  final SettingType type;

  SettingItem({
    required this.icon,
    required this.label,
    required this.type,
  });
}

class SettingsData extends ChangeNotifier {
  String _currentSpeed;
  String _currentQuality;
  String _currentLanguage;

  final List<String> availableSpeeds;
  final List<String> availableQualities;
  final List<String> availableLanguages;

  SettingsData({
    String initialSpeed = "1.0x",
    String initialQuality = "720p",
    String initialLanguage = "English",
    List<String>? availableQualities,
  })  : _currentSpeed = initialSpeed,
        _currentQuality = initialQuality,
        _currentLanguage = initialLanguage,
        availableSpeeds = ["0.5x", "0.75x", "1.0x", "1.25x", "1.5x", "2.0x"],
        availableQualities = availableQualities ?? ["360p", "480p", "720p", "1080p"],
        availableLanguages = ["English", "Hindi", "Spanish", "French"];

  String get currentSpeed => _currentSpeed;
  String get currentQuality => _currentQuality;
  String get currentLanguage => _currentLanguage;

  void setSpeed(String newSpeed) {
    if (_currentSpeed != newSpeed) {
      _currentSpeed = newSpeed;
      notifyListeners();
    }
  }

  void setQuality(String newQuality) {
    if (_currentQuality != newQuality) {
      _currentQuality = newQuality;
      notifyListeners();
    }
  }

  void setLanguage(String newLanguage) {
    if (_currentLanguage != newLanguage) {
      _currentLanguage = newLanguage;
      notifyListeners();
    }
  }
}

class VideoSettingsDialog extends StatelessWidget {
  final SettingsData settingsData;
  final List<SettingItem> settings = [
    SettingItem(icon: Icons.speed, label: "Speed", type: SettingType.speed),
    SettingItem(icon: Icons.hd, label: "Quality", type: SettingType.quality),
    SettingItem(icon: Icons.language, label: "Language", type: SettingType.language),
  ];

  VideoSettingsDialog({Key? key, required this.settingsData}) : super(key: key);

  static void show(BuildContext context, SettingsData settingsData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => VideoSettingsDialog(settingsData: settingsData),
    );
  }

  void _showOptionSheet(BuildContext context, SettingType type) {
    String title;
    List<String> options;
    String selectedValue;
    void Function(String) onSelect;

    switch (type) {
      case SettingType.speed:
        title = "Playback Speed";
        options = settingsData.availableSpeeds;
        selectedValue = settingsData.currentSpeed;
        onSelect = settingsData.setSpeed;
        break;
      case SettingType.quality:
        title = "Video Quality";
        options = settingsData.availableQualities;
        selectedValue = settingsData.currentQuality;
        onSelect = settingsData.setQuality;
        break;
      case SettingType.language:
        title = "Language";
        options = settingsData.availableLanguages;
        selectedValue = settingsData.currentLanguage;
        onSelect = settingsData.setLanguage;
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: const Color(0xFF1E1E1E).withOpacity(0.95),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB0B0B0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'MazzardH',
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (_, index) {
                      final option = options[index];
                      final isSelected = option == selectedValue;
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            onSelect(option);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: isSelected ? const Color(0xFFE5003C) : Colors.white,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      fontFamily: 'MazzardH',
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check, color: Color(0xFFE5003C), size: 24),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsData,
      builder: (context, _) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E).withOpacity(0.95),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 30,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB0B0B0),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      margin: const EdgeInsets.only(bottom: 24),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        "Playback Settings",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'MazzardH',
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    ...settings.map((item) {
                      String currentValue;
                      switch (item.type) {
                        case SettingType.speed:
                          currentValue = settingsData.currentSpeed;
                          break;
                        case SettingType.quality:
                          currentValue = settingsData.currentQuality;
                          break;
                        case SettingType.language:
                          currentValue = settingsData.currentLanguage;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showOptionSheet(context, item.type),
                            highlightColor: Colors.white.withOpacity(0.1),
                            splashColor: Colors.white.withOpacity(0.05),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(item.icon, color: const Color(0xFFE0E0E0), size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                        fontFamily: 'MazzardH',
                                      ),
                                    ),
                                  ),
                                  Text(
                                    currentValue,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE5003C),
                                      fontFamily: 'MazzardH',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, color: Color(0xFFE0E0E0), size: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
