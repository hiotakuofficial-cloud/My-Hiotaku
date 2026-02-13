import '../database/query_optimizer.dart';
import '../database/data_validator.dart';
import '../screens/auth/handler/supabase.dart';

class PerformanceOptimizer {
  // Connection pooling simulation
  static int _activeConnections = 0;
  static const int _maxConnections = 10;
  
  // Rate limiting
  static final Map<String, DateTime> _lastRequests = {};
  static const Duration _minRequestInterval = Duration(milliseconds: 100);
  
  // Cache for frequently accessed data
  static final Map<String, dynamic> _performanceCache = {};
  static const Duration _performanceCacheExpiry = Duration(minutes: 5);
  
  // Optimized database operations with connection management
  static Future<T?> executeWithConnectionLimit<T>(
    Future<T?> Function() operation,
    String operationKey,
  ) async {
    try {
      // Rate limiting check
      if (!DataValidator.isWithinRateLimit(
        _lastRequests[operationKey],
        _minRequestInterval,
      )) {
        return null;
      }
      
      // Connection limit check
      if (_activeConnections >= _maxConnections) {
        await Future.delayed(Duration(milliseconds: 50));
        if (_activeConnections >= _maxConnections) {
          return null;
        }
      }
      
      _activeConnections++;
      _lastRequests[operationKey] = DateTime.now();
      
      final result = await operation();
      return result;
    } catch (e) {
      return null;
    } finally {
      _activeConnections--;
    }
  }
  
  // Optimized user favorites with caching
  static Future<Map<String, dynamic>> getOptimizedUserFavorites({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    final cacheKey = 'user_favorites_${userId}_${page}_$limit';
    
    // Check performance cache first
    if (_performanceCache.containsKey(cacheKey)) {
      final cached = _performanceCache[cacheKey];
      if (cached['timestamp'] != null) {
        final age = DateTime.now().difference(cached['timestamp']);
        if (age < _performanceCacheExpiry) {
          return cached['data'];
        }
      }
    }
    
    final result = await executeWithConnectionLimit(
      () => QueryOptimizer.getUserFavoritesPaginated(
        userId: userId,
        page: page,
        limit: limit,
      ),
      'user_favorites_$userId',
    );
    
    if (result != null) {
      _performanceCache[cacheKey] = {
        'data': result,
        'timestamp': DateTime.now(),
      };
    }
    
    return result ?? {'data': [], 'hasMore': false};
  }
  
  // Batch operations with optimized performance
  static Future<bool> batchOperationOptimized({
    required List<Map<String, dynamic>> operations,
    required String operationType,
  }) async {
    try {
      // Process in smaller chunks for better performance
      const chunkSize = 25;
      bool allSuccessful = true;
      
      for (int i = 0; i < operations.length; i += chunkSize) {
        final chunk = operations.skip(i).take(chunkSize).toList();
        
        final result = await executeWithConnectionLimit(
          () async {
            for (var operation in chunk) {
              final validated = DataValidator.validateFavoriteData(
                userId: operation['user_id'],
                animeId: operation['anime_id'],
                animeTitle: operation['anime_title'],
                animeImage: operation['anime_image'],
                isPublic: operation['is_public'] ?? false,
              );
              
              if (validated != null) {
                await SupabaseHandler.insertData(
                  table: 'favorites',
                  data: validated,
                );
              }
            }
            return true;
          },
          '${operationType}_batch_$i',
        );
        
        if (result != true) {
          allSuccessful = false;
        }
        
        // Small delay between chunks to prevent overwhelming the database
        if (i + chunkSize < operations.length) {
          await Future.delayed(Duration(milliseconds: 50));
        }
      }
      
      return allSuccessful;
    } catch (e) {
      return false;
    }
  }
  
  // Optimized search with debouncing
  static Future<Map<String, dynamic>> optimizedSearch({
    required String userId,
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final validatedQuery = DataValidator.validateSearchQuery(query);
    if (validatedQuery == null) {
      return {'data': [], 'hasMore': false};
    }
    
    final cacheKey = 'search_${userId}_${validatedQuery}_${page}_$limit';
    
    // Check cache first
    if (_performanceCache.containsKey(cacheKey)) {
      final cached = _performanceCache[cacheKey];
      if (cached['timestamp'] != null) {
        final age = DateTime.now().difference(cached['timestamp']);
        if (age < Duration(minutes: 2)) { // Shorter cache for search
          return cached['data'];
        }
      }
    }
    
    final result = await executeWithConnectionLimit(
      () => QueryOptimizer.searchFavorites(
        userId: userId,
        query: validatedQuery,
        page: page,
        limit: limit,
      ),
      'search_${userId}_$validatedQuery',
    );
    
    if (result != null) {
      _performanceCache[cacheKey] = {
        'data': result,
        'timestamp': DateTime.now(),
      };
    }
    
    return result ?? {'data': [], 'hasMore': false};
  }
  
  // Memory management
  static void clearPerformanceCache() {
    try {
      _performanceCache.clear();
      _lastRequests.clear();
    } catch (e) {
      // Silent fail
    }
  }
  
  // Cleanup expired cache entries
  static void cleanupExpiredCache() {
    try {
      final now = DateTime.now();
      final expiredKeys = <String>[];
      
      _performanceCache.forEach((key, value) {
        if (value['timestamp'] != null) {
          final age = now.difference(value['timestamp']);
          if (age > _performanceCacheExpiry) {
            expiredKeys.add(key);
          }
        }
      });
      
      for (final key in expiredKeys) {
        _performanceCache.remove(key);
      }
    } catch (e) {
      // Silent fail
    }
  }
  
  // Get performance metrics
  static Map<String, dynamic> getPerformanceMetrics() {
    try {
      return {
        'active_connections': _activeConnections,
        'max_connections': _maxConnections,
        'cache_size': _performanceCache.length,
        'rate_limit_entries': _lastRequests.length,
      };
    } catch (e) {
      return {
        'active_connections': 0,
        'max_connections': _maxConnections,
        'cache_size': 0,
        'rate_limit_entries': 0,
      };
    }
  }
}
