import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionService {
  // Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final status = await Permission.notification.request();
      return status == PermissionStatus.granted;
    } catch (e) {
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
      return false;
    }
  }

  // Request essential app permissions
  static Future<void> requestEssentialPermissions(BuildContext context) async {
    try {
      // Request notification permission
      bool notificationGranted = await requestNotificationPermission();
      
      // Request storage permissions
      bool storageGranted = await requestStoragePermissions();

      // Show result to user
      String message = 'Permissions: ';
      if (notificationGranted) message += 'Notifications ✓ ';
      if (storageGranted) message += 'Storage ✓';
      
      if (!notificationGranted && !storageGranted) {
        message = 'Some permissions were denied. You can enable them in Settings.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: (notificationGranted && storageGranted) 
              ? Colors.green 
              : Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
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
    }
  }
}
