import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      print('Notification permission error: $e');
      return false;
    }
  }

  // Request storage permissions
  static Future<bool> requestStoragePermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.manageExternalStorage,
      ].request();

      return statuses[Permission.storage] == PermissionStatus.granted ||
             statuses[Permission.manageExternalStorage] == PermissionStatus.granted;
    } catch (e) {
      print('Storage permission error: $e');
      return false;
    }
  }

  // Request media permissions (Android 13+)
  static Future<bool> requestMediaPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();

      return statuses.values.any((status) => status == PermissionStatus.granted);
    } catch (e) {
      print('Media permission error: $e');
      return false;
    }
  }

  // Request all app permissions
  static Future<void> requestAllPermissions(BuildContext context) async {
    try {
      // Request notification permission
      bool notificationGranted = await requestNotificationPermission();
      
      // Request storage permissions
      bool storageGranted = await requestStoragePermissions();
      
      // Request media permissions (Android 13+)
      bool mediaGranted = await requestMediaPermissions();

      // Show result to user
      String message = 'Permissions: ';
      if (notificationGranted) message += 'Notifications ✓ ';
      if (storageGranted || mediaGranted) message += 'Storage ✓';
      
      if (!notificationGranted && !storageGranted && !mediaGranted) {
        message = 'Some permissions were denied. You can enable them in Settings.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: (notificationGranted && (storageGranted || mediaGranted)) 
              ? Colors.green 
              : Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Permission request error: $e');
    }
  }

  // Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    try {
      final status = await Permission.notification.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    try {
      final status = await Permission.storage.status;
      final manageStatus = await Permission.manageExternalStorage.status;
      return status == PermissionStatus.granted || 
             manageStatus == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('Error opening app settings: $e');
    }
  }
}
