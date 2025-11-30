class SupaConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://brwzqawoncblbxqoqyua.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJyd3pxYXdvbmNibGJ4cW9xeXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzM1MjIsImV4cCI6MjA3NzkwOTUyMn0.-HNrfcz5K2N6f_Q8tQsWtsUJCV_SW13Hcj565qU5eCA';
  
  // Redirect URLs
  static const String emailConfirmRedirect = 'https://hiotaku.kesug.com/confirm.php';
  static const String passwordResetRedirect = 'https://hiotaku.kesug.com/reset.php';
  
  // Database Tables
  static const String usersTable = 'users';
  static const String profilesTable = 'profiles';
  static const String settingsTable = 'user_settings';
  
  // Auth Configuration
  static const Duration sessionTimeout = Duration(hours: 24);
  static const bool requireEmailConfirmation = true;
  static const int minPasswordLength = 6;
  
  // Storage Buckets
  static const String avatarsBucket = 'avatars';
  static const String publicBucket = 'public';
  
  // RLS Policies
  static const bool enableRLS = true;
  
  // Error Messages
  static const Map<String, String> errorMessages = {
    'invalid_credentials': 'Invalid email or password',
    'email_not_confirmed': 'Please confirm your email first',
    'user_not_found': 'User not found',
    'email_already_exists': 'Email already registered',
    'weak_password': 'Password must be at least 6 characters',
    'network_error': 'Network connection failed',
    'server_error': 'Server error occurred',
    'unknown_error': 'An unexpected error occurred',
  };
  
  // Get error message
  static String getErrorMessage(String errorCode) {
    return errorMessages[errorCode] ?? errorMessages['unknown_error']!;
  }
  
  // Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }
  
  // Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= minPasswordLength;
  }
  
  // Generate username from email
  static String generateUsername(String email) {
    return email.split('@')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
