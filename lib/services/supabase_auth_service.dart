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
      print('Attempting sign in with email: $email');
      
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      print('Sign in response: ${response.user?.id}');
      print('User confirmed: ${response.user?.emailConfirmedAt}');
      
      if (response.user == null) {
        throw Exception('Login failed - no user returned');
      }
      
      // Check if email is confirmed
      if (response.user!.emailConfirmedAt == null) {
        throw Exception('Please check your email and confirm your account first');
      }
      
      print('Sign in successful for user: ${response.user!.email}');
    } catch (e) {
      print('Email Sign-In Error: $e');
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('Invalid email or password');
      } else if (e.toString().contains('Email not confirmed')) {
        throw Exception('Please confirm your email first');
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Email Sign Up
  static Future<void> signUpWithEmail(String email, String password) async {
    try {
      print('Attempting sign up with email: $email');
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      print('Sign up response: ${response.user?.id}');
      
      if (response.user != null) {
        print('Creating user profile in database...');
        
        // Check if user already exists in public.users
        final existingUser = await _supabase
            .from('users')
            .select()
            .eq('email', email)
            .maybeSingle();
        
        if (existingUser == null) {
          // Create user profile in public.users table (without password field)
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'username': email.split('@')[0],
            'created_at': DateTime.now().toIso8601String(),
          });
          print('User profile created successfully');
        } else {
          print('User profile already exists, skipping creation');
        }
      } else {
        throw Exception('Sign up failed - no user returned');
      }
    } catch (e) {
      print('Email Sign-Up Error: $e');
      if (e.toString().contains('already registered')) {
        throw Exception('Email already registered. Try signing in instead.');
      }
      throw Exception('Sign up failed. Please try again.');
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
