import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PersistentCache {
  static const String _cacheFileName = 'anime_cache.json';
  static File? _cacheFile;

  static Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _cacheFile = File('${directory.path}/$_cacheFileName');
    } catch (e) {
    }
  }

  static Future<void> saveCache(Map<String, dynamic> cacheData) async {
    try {
      if (_cacheFile == null) await init();
      await _cacheFile!.writeAsString(jsonEncode(cacheData));
    } catch (e) {
    }
  }

  static Future<Map<String, dynamic>?> loadCache() async {
    try {
      if (_cacheFile == null) await init();
      if (!await _cacheFile!.exists()) return null;
      
      final content = await _cacheFile!.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    try {
      if (_cacheFile == null) await init();
      if (await _cacheFile!.exists()) {
        await _cacheFile!.delete();
      }
    } catch (e) {
    }
  }
}
