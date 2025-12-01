import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHandler {
  // Supabase Configuration
  static const String _supabaseUrl = 'https://brwzqawoncblbxqoqyua.supabase.co';
  static const String _supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyd3pxYXdvbmNibGJ4cW9xeXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzM1MjIsImV4cCI6MjA3NzkwOTUyMn0.-HNrfcz5K2N6f_Q8tQsWtsUJCV_SW13Hcj565qU5eCA';
  
  static SupabaseClient? _client;
  
  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }
  
  // Get client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _client!;
  }
  
  // Generic database operations
  
  /// Insert data into any table
  static Future<Map<String, dynamic>?> insertData({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await client
          .from(table)
          .insert(data)
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('Insert error: $e');
      return null;
    }
  }
  
  /// Get data from any table
  static Future<List<Map<String, dynamic>>?> getData({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = client.from(table);
      
      if (select != null) {
        query = query.select(select);
      } else {
        query = query.select('*');
      }
      
      if (filters != null) {
        filters.forEach((key, value) {
          query = query.eq(key, value);
        });
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Get data error: $e');
      return null;
    }
  }
  
  /// Update data in any table
  static Future<bool> updateData({
    required String table,
    required Map<String, dynamic> data,
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = client.from(table).update(data);
      
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
      
      await query;
      return true;
    } catch (e) {
      print('Update error: $e');
      return false;
    }
  }
  
  /// Delete data from any table
  static Future<bool> deleteData({
    required String table,
    required Map<String, dynamic> filters,
  }) async {
    try {
      var query = client.from(table).delete();
      
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
      
      await query;
      return true;
    } catch (e) {
      print('Delete error: $e');
      return false;
    }
  }
  
  // Utility methods
  
  /// Check if Supabase is initialized
  static bool get isInitialized => _client != null;
  
  /// Get current timestamp
  static String getCurrentTimestamp() {
    return DateTime.now().toIso8601String();
  }
}
