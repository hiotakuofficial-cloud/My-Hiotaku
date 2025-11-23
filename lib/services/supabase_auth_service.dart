import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _supabase.auth.currentUser != null;

  // Email Sign In
  static Future<void> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception('Login failed');
      }
      
      if (response.user!.emailConfirmedAt == null) {
        throw Exception('Please confirm your email first');
      }
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('Invalid email or password');
      } else if (e.toString().contains('Email not confirmed')) {
        throw Exception('Please confirm your email first');
      }
      throw Exception('Login failed');
    }
  }

  // Email Sign Up
  static Future<void> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'https://hiotaku.kesug.com/confirm.php', // Your web domain
      );
      
      if (response.user != null) {
        // Check if user already exists in public.users
        final existingUser = await _supabase
            .from('users')
            .select()
            .eq('email', email)
            .maybeSingle();
        
        if (existingUser == null) {
          // Create user profile in public.users table
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'username': email.split('@')[0],
            'created_at': DateTime.now().toIso8601String(),
          });
        }
        
        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt == null) {
          throw Exception('CONFIRMATION_REQUIRED');
        }
      } else {
        throw Exception('Sign up failed');
      }
    } catch (e) {
      if (e.toString().contains('already registered')) {
        throw Exception('Email already registered');
      } else if (e.toString().contains('CONFIRMATION_REQUIRED')) {
        throw Exception('CONFIRMATION_REQUIRED');
      }
      throw Exception('Sign up failed');
    }
  }

  // Demo Google login (fallback)
  static Future<void> signInWithGoogle() async {
    try {
      // For now, just simulate login
      await Future.delayed(Duration(seconds: 1));
      // In real app, this would be OAuth
    } catch (e) {
      throw Exception('Google login not available');
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
