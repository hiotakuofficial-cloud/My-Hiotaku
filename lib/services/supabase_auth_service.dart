import 'package:supabase_flutter/supabase_flutter.dart';
import '../supa.dart';

class SupabaseAuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  static User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _supabase.auth.currentUser != null;

  // Email Sign In
  static Future<void> signInWithEmail(String email, String password) async {
    try {
      // Validate input
      if (!SupaConfig.isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      if (!SupaConfig.isValidPassword(password)) {
        throw Exception(SupaConfig.getErrorMessage('weak_password'));
      }

      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user == null) {
        throw Exception(SupaConfig.getErrorMessage('invalid_credentials'));
      }
      
      if (SupaConfig.requireEmailConfirmation && response.user!.emailConfirmedAt == null) {
        throw Exception(SupaConfig.getErrorMessage('email_not_confirmed'));
      }
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception(SupaConfig.getErrorMessage('invalid_credentials'));
      } else if (e.toString().contains('Email not confirmed')) {
        throw Exception(SupaConfig.getErrorMessage('email_not_confirmed'));
      }
      throw Exception(SupaConfig.getErrorMessage('unknown_error'));
    }
  }

  // Email Sign Up
  static Future<void> signUpWithEmail(String email, String password) async {
    try {
      // Validate input
      if (!SupaConfig.isValidEmail(email)) {
        throw Exception('Invalid email format');
      }
      if (!SupaConfig.isValidPassword(password)) {
        throw Exception(SupaConfig.getErrorMessage('weak_password'));
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: SupaConfig.emailConfirmRedirect,
      );
      
      if (response.user != null) {
        // Check if user already exists in users table
        final existingUser = await _supabase
            .from(SupaConfig.usersTable)
            .select()
            .eq('email', email)
            .maybeSingle();
        
        if (existingUser == null) {
          // Create user profile
          await _supabase.from(SupaConfig.usersTable).insert({
            'id': response.user!.id,
            'email': email,
            'username': SupaConfig.generateUsername(email),
            'created_at': DateTime.now().toIso8601String(),
          });
        }
        
        // Check if email confirmation is required
        if (SupaConfig.requireEmailConfirmation && response.user!.emailConfirmedAt == null) {
          throw Exception('CONFIRMATION_REQUIRED');
        }
      } else {
        throw Exception(SupaConfig.getErrorMessage('unknown_error'));
      }
    } catch (e) {
      if (e.toString().contains('already registered')) {
        throw Exception(SupaConfig.getErrorMessage('email_already_exists'));
      } else if (e.toString().contains('CONFIRMATION_REQUIRED')) {
        throw Exception('CONFIRMATION_REQUIRED');
      }
      throw Exception(SupaConfig.getErrorMessage('unknown_error'));
    }
  }

  // Reset Password
  static Future<void> resetPassword(String email) async {
    try {
      if (!SupaConfig.isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: SupaConfig.passwordResetRedirect,
      );
    } catch (e) {
      throw Exception(SupaConfig.getErrorMessage('unknown_error'));
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
