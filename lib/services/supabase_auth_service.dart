import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _supabase.auth.currentUser != null;

  // Google Sign In (Web-based OAuth)
  static Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.hiotaku.app://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      print('Supabase Google Sign-In Error: $e');
      throw Exception('Google Sign-In failed: $e');
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      print('Sign-Out Error: $e');
      throw Exception('Sign-Out failed: $e');
    }
  }

  // Get user display name
  static String get userName => 
      _supabase.auth.currentUser?.userMetadata?['full_name'] ?? 
      _supabase.auth.currentUser?.email?.split('@')[0] ?? 
      'User';

  // Get user email
  static String get userEmail => _supabase.auth.currentUser?.email ?? '';

  // Get user photo URL
  static String? get userPhotoUrl => 
      _supabase.auth.currentUser?.userMetadata?['avatar_url'];

  // Auth state stream
  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
