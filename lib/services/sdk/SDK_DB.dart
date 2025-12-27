import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSDK {
  static SupabaseClient get client => Supabase.instance.client;
  
  // Simple data operations without complex chaining
  static Future<List<Map<String, dynamic>>?> getData({
    required String table,
    String? select,
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
    String? orderBy,
  }) async {
    try {
      // Start with basic query
      dynamic query = client.from(table).select(select ?? '*');
      
      // Apply filters
      if (filters != null) {
        for (final entry in filters.entries) {
          query = query.eq(entry.key, entry.value);
        }
      }
      
      // Apply ordering
      if (orderBy != null) {
        final parts = orderBy.split('.');
        final column = parts[0];
        final ascending = parts.length > 1 ? parts[1] != 'desc' : true;
        query = query.order(column, ascending: ascending);
      }
      
      // Apply pagination
      if (limit != null) {
        query = query.limit(limit);
      }
      
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }
      
      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return null;
    }
  }
  
  // Insert data
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
      return null;
    }
  }
  
  // Update data
  static Future<bool> updateData({
    required String table,
    required Map<String, dynamic> data,
    required String column,
    required dynamic value,
  }) async {
    try {
      await client
          .from(table)
          .update(data)
          .eq(column, value);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Delete data
  static Future<bool> deleteData({
    required String table,
    required String column,
    required dynamic value,
  }) async {
    try {
      await client
          .from(table)
          .delete()
          .eq(column, value);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Subscribe to real-time changes
  static RealtimeChannel subscribeToTable({
    required String table,
    Function(PostgresChangePayload)? onInsert,
    Function(PostgresChangePayload)? onUpdate,
    Function(PostgresChangePayload)? onDelete,
  }) {
    final channel = client.channel('public:$table');
    
    if (onInsert != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: table,
        callback: onInsert,
      );
    }
    
    if (onUpdate != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        callback: onUpdate,
      );
    }
    
    if (onDelete != null) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        callback: onDelete,
      );
    }
    
    channel.subscribe();
    return channel;
  }
}
