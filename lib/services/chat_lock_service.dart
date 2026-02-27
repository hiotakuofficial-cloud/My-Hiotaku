import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ChatLockService {
  static Future<bool> isLockEnabled() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/chat_lock.txt');
      
      if (await file.exists()) {
        final content = await file.readAsString();
        final lines = content.split('\n');
        if (lines.isNotEmpty) {
          return lines[0] == 'true';
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
