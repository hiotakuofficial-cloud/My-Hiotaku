import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://brwzqawoncblbxqoqyua.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyd3pxYXdvbmNibGJ4cW9xeXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzM1MjIsImV4cCI6MjA3NzkwOTUyMn0.-HNrfcz5K2N6f_Q8tQsWtsUJCV_SW13Hcj565qU5eCA',
  );

  final client = Supabase.instance.client;

  try {
    // Check all users with 'pihu' in username
    final response = await client
        .from('users')
        .select('id, username, firebase_uid')
        .ilike('username', '%pihu%');
    
    print('=== Users with "pihu" in username ===');
    for (var user in response) {
      print('User: ${user['username']} (ID: ${user['id']}, Firebase: ${user['firebase_uid']})');
      
      // Check presence status
      try {
        final presenceResponse = await client
            .from('user_presence')
            .select('is_online, last_seen, status')
            .eq('firebase_uid', user['firebase_uid'])
            .single();
        
        final isOnline = presenceResponse['is_online'] ?? false;
        final lastSeen = presenceResponse['last_seen'];
        final status = presenceResponse['status'] ?? 'unknown';
        
        print('  Status: ${isOnline ? "🟢 ONLINE" : "⚫ OFFLINE"}');
        print('  Last Seen: $lastSeen');
        print('  Status Field: $status');
        
        if (lastSeen != null) {
          final lastSeenTime = DateTime.parse(lastSeen);
          final now = DateTime.now();
          final minutesAgo = now.difference(lastSeenTime).inMinutes;
          print('  Minutes Ago: $minutesAgo');
        }
        
      } catch (e) {
        print('  No presence record found');
      }
      print('');
    }
    
  } catch (e) {
    print('Error: $e');
  }
}
