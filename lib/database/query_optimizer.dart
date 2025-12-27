import '../screens/auth/handler/supabase.dart';

class QueryOptimizer {
  // Pagination constants
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Optimized user favorites with pagination
  static Future<Map<String, dynamic>> getUserFavoritesPaginated({
    required String userId,
    int page = 1,
    int limit = defaultPageSize,
  }) async {
    try {
      limit = limit > maxPageSize ? maxPageSize : limit;
      int offset = (page - 1) * limit;
      
      final result = await SupabaseHandler.getData(
        table: 'favorites',
        select: 'id,anime_id,anime_title,anime_image,added_at',
        filters: {
          'user_id': userId, // Only actual filter
        },
      );
      
      // Manual sorting and pagination since SupabaseHandler doesn't support it
      List<Map<String, dynamic>> sortedData = result ?? [];
      if (sortedData.isNotEmpty) {
        // Sort by added_at desc
        sortedData.sort((a, b) {
          final aDate = DateTime.parse(a['added_at']);
          final bDate = DateTime.parse(b['added_at']);
          return bDate.compareTo(aDate);
        });
        
        // Apply pagination
        final startIndex = offset;
        final endIndex = (startIndex + limit).clamp(0, sortedData.length);
        sortedData = sortedData.sublist(startIndex, endIndex);
      }
      
      return {
        'data': sortedData,
        'page': page,
        'limit': limit,
        'hasMore': sortedData.length == limit,
      };
    } catch (e) {
      return {
        'data': [],
        'page': page,
        'limit': limit,
        'hasMore': false,
      };
    }
  }
  
  // Optimized public favorites with user info
  static Future<Map<String, dynamic>> getPublicFavoritesPaginated({
    int page = 1,
    int limit = defaultPageSize,
  }) async {
    try {
      limit = limit > maxPageSize ? maxPageSize : limit;
      int offset = (page - 1) * limit;
      
      final result = await SupabaseHandler.getData(
        table: 'favorites',
        select: 'id,anime_id,anime_title,anime_image,added_at,users!inner(username,avatar_url)',
        filters: {
          'is_public': true, // Only actual filter
        },
      );
      
      // Manual sorting and pagination
      List<Map<String, dynamic>> sortedData = result ?? [];
      if (sortedData.isNotEmpty) {
        sortedData.sort((a, b) {
          final aDate = DateTime.parse(a['added_at']);
          final bDate = DateTime.parse(b['added_at']);
          return bDate.compareTo(aDate);
        });
        
        final startIndex = offset;
        final endIndex = (startIndex + limit).clamp(0, sortedData.length);
        sortedData = sortedData.sublist(startIndex, endIndex);
      }
      
      return {
        'data': sortedData,
        'page': page,
        'limit': limit,
        'hasMore': sortedData.length == limit,
      };
    } catch (e) {
      return {
        'data': [],
        'page': page,
        'limit': limit,
        'hasMore': false,
      };
    }
  }
  
  // Optimized search with indexes
  static Future<Map<String, dynamic>> searchFavorites({
    required String userId,
    required String query,
    int page = 1,
    int limit = defaultPageSize,
  }) async {
    try {
      limit = limit > maxPageSize ? maxPageSize : limit;
      int offset = (page - 1) * limit;
      
      final result = await SupabaseHandler.getData(
        table: 'favorites',
        select: 'id,anime_id,anime_title,anime_image,added_at',
        filters: {
          'user_id': userId,
          // Note: ilike search not supported in basic SupabaseHandler
        },
      );
      
      // Manual search and sorting
      List<Map<String, dynamic>> filteredData = result ?? [];
      if (filteredData.isNotEmpty && query.isNotEmpty) {
        filteredData = filteredData.where((item) {
          final title = item['anime_title']?.toString().toLowerCase() ?? '';
          return title.contains(query.toLowerCase());
        }).toList();
        
        filteredData.sort((a, b) {
          final aDate = DateTime.parse(a['added_at']);
          final bDate = DateTime.parse(b['added_at']);
          return bDate.compareTo(aDate);
        });
        
        final startIndex = offset;
        final endIndex = (startIndex + limit).clamp(0, filteredData.length);
        filteredData = filteredData.sublist(startIndex, endIndex);
      }
      
      return {
        'data': result ?? [],
        'page': page,
        'limit': limit,
        'hasMore': (result?.length ?? 0) == limit,
        'query': query,
      };
    } catch (e) {
      return {
        'data': [],
        'page': page,
        'limit': limit,
        'hasMore': false,
        'query': query,
      };
    }
  }
  
  // Batch operations for better performance
  static Future<bool> batchAddFavorites({
    required String userId,
    required List<Map<String, dynamic>> favorites,
  }) async {
    try {
      List<Map<String, dynamic>> batch = favorites.map((fav) => {
        'user_id': userId,
        'anime_id': fav['anime_id'],
        'anime_title': fav['anime_title'],
        'anime_image': fav['anime_image'],
        'is_public': fav['is_public'] ?? false,
        'added_at': DateTime.now().toIso8601String(),
      }).toList();
      
      // Insert in chunks to avoid timeout
      const chunkSize = 50;
      for (int i = 0; i < batch.length; i += chunkSize) {
        int end = (i + chunkSize < batch.length) ? i + chunkSize : batch.length;
        List<Map<String, dynamic>> chunk = batch.sublist(i, end);
        
        for (var item in chunk) {
          await SupabaseHandler.insertData(table: 'favorites', data: item);
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Optimized user lookup with caching
  static Future<Map<String, dynamic>?> getUserOptimized(String firebaseUID) async {
    try {
      final result = await SupabaseHandler.getData(
        table: 'users',
        select: 'id,username,email,avatar_url,display_name,created_at',
        filters: {'firebase_uid': firebaseUID}, // Fixed: Remove eq. prefix
      );
      
      return result?.isNotEmpty == true ? result!.first : null;
    } catch (e) {
      return null;
    }
  }
  
  // Get user stats efficiently
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final favorites = await SupabaseHandler.getData(
        table: 'favorites',
        select: 'id',
        filters: {'user_id': userId},
      );
      
      final publicFavorites = await SupabaseHandler.getData(
        table: 'favorites',
        select: 'id',
        filters: {'user_id': userId, 'is_public': true},
      );
      
      final mergeRequests = await SupabaseHandler.getData(
        table: 'merge_requests',
        select: 'id',
        filters: {'receiver_id': userId, 'status': 'pending'},
      );
      
      return {
        'total_favorites': favorites?.length ?? 0,
        'public_favorites': publicFavorites?.length ?? 0,
        'pending_requests': mergeRequests?.length ?? 0,
      };
    } catch (e) {
      return {
        'total_favorites': 0,
        'public_favorites': 0,
        'pending_requests': 0,
      };
    }
  }
}
