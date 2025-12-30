// Debug script to check offline system
// Run this to see what's happening with user presence

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://brwzqawoncblbxqoqyua.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyd3pxYXdvbmNibGJ4cW9xeXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzM1MjIsImV4cCI6MjA3NzkwOTUyMn0.-HNrfcz5K2N6f_Q8tQsWtsUJCV_SW13Hcj565qU5eCA',
  );

  final client = Supabase.instance.client;

  print('=== Checking User Presence System ===\n');

  try {
    // Check all online users
    final onlineUsers = await client
        .from('user_presence')
        .select('firebase_uid, is_online, last_seen, status, updated_at')
        .eq('is_online', true);

    print('Online Users:');
    for (var user in onlineUsers) {
      final lastSeen = DateTime.parse(user['last_seen']);
      final now = DateTime.now();
      final minutesAgo = now.difference(lastSeen).inMinutes;
      
      print('  Firebase UID: ${user['firebase_uid']}');
      print('  Status: ${user['status']}');
      print('  Last Seen: ${user['last_seen']}');
      print('  Minutes Ago: $minutesAgo');
      print('  Should be offline: ${minutesAgo > 5}');
      print('');
    }

    // Check if cron extension is available
    print('=== Testing Manual Offline Function ===');
    try {
      await client.rpc('mark_stale_users_offline');
      print('✅ Manual offline function executed successfully');
    } catch (e) {
      print('❌ Manual offline function failed: $e');
    }

    // Check again after manual execution
    print('\n=== After Manual Execution ===');
    final afterUsers = await client
        .from('user_presence')
        .select('firebase_uid, is_online, last_seen, status')
        .eq('is_online', true);

    print('Still Online Users: ${afterUsers.length}');
    for (var user in afterUsers) {
      final lastSeen = DateTime.parse(user['last_seen']);
      final now = DateTime.now();
      final minutesAgo = now.difference(lastSeen).inMinutes;
      
      print('  Firebase UID: ${user['firebase_uid']} - ${minutesAgo} minutes ago');
    }

  } catch (e) {
    print('Error: $e');
  }
}
