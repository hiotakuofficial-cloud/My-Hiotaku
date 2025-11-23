import 'dart:convert';
import '../models/api_models.dart';

class ApiCache {
  static final Map<String, CacheItem> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  static void set(String key, dynamic data) {
    _cache[key] = CacheItem(
      data: data,
      timestamp: DateTime.now(),
    );
  }

  static T? get<T>(String key) {
    final item = _cache[key];
    if (item == null) return null;
    
    if (DateTime.now().difference(item.timestamp) > _cacheExpiry) {
      _cache.remove(key);
      return null;
    }
    
    return item.data as T?;
  }

  static void clear() {
    _cache.clear();
  }

  static void remove(String key) {
    _cache.remove(key);
  }
}

class CacheItem {
  final dynamic data;
  final DateTime timestamp;

  CacheItem({
    required this.data,
    required this.timestamp,
  });
}
