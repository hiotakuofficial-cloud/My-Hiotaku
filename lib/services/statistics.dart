import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to track app opens and statistics
class StatisticsService {
  static final _supabase = Supabase.instance.client;

  /// Track app open - call this on splash screen
  static Future<void> trackAppOpen() async {
    try {
      print('📊 Starting app open tracking...');
      
      // Get current user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      if (firebaseUser == null) {
        print('📊 No Firebase user - tracking guest');
        // Guest user - use device ID or generate temp UUID
        await _trackGuestOpen();
        return;
      }

      print('📊 Firebase user found: ${firebaseUser.uid}');

      // Get user UUID from Supabase users table
      final userResponse = await _supabase
          .from('users')
          .select('id, display_name')
          .eq('firebase_uid', firebaseUser.uid)
          .maybeSingle();

      if (userResponse == null) {
        print('📊 User not found in Supabase database');
        // User not in database yet
        return;
      }

      final userUuid = userResponse['id'] as String;
      final userName = userResponse['display_name'] as String? ?? 
                       firebaseUser.displayName ?? 
                       'User';

      print('📊 Calling increment_today_opens for: $userName ($userUuid)');

      // Call database function to increment today's opens
      await _supabase.rpc('increment_today_opens', params: {
        'p_user_uuid': userUuid,
        'p_user_name': userName,
      });

      print('📊 ✅ Tracking successful!');

    } catch (e) {
      // Silent fail - don't block app if tracking fails
      print('📊 ❌ Statistics tracking failed: $e');
    }
  }

  /// Track guest user opens (optional)
  static Future<void> _trackGuestOpen() async {
    try {
      // You can implement guest tracking here if needed
      // For now, we only track logged-in users
    } catch (e) {
      print('Guest tracking failed: $e');
    }
  }

  /// Get today's statistics (admin use)
  static Future<Map<String, dynamic>?> getTodayStats() async {
    try {
      final response = await _supabase
          .from('today_stats')
          .select()
          .maybeSingle();
      
      return response;
    } catch (e) {
      print('Failed to get stats: $e');
      return null;
    }
  }

  /// Get user's today open count
  static Future<int> getUserTodayOpens(String userUuid) async {
    try {
      final response = await _supabase
          .from('today_opens')
          .select('total_opens')
          .eq('user_uuid', userUuid)
          .eq('date', DateTime.now().toIso8601String().split('T')[0])
          .maybeSingle();

      if (response == null) return 0;
      return response['total_opens'] as int? ?? 0;
    } catch (e) {
      print('Failed to get user opens: $e');
      return 0;
    }
  }
}
