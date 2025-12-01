import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseHandler {
  // Supabase Configuration
  static const String _supabaseUrl = 'nehu';
  static const String _supabaseAnonKey = 'pihu';
  
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
  
  // Custom table-based authentication methods
  
  /// Login using custom users table
  static Future<Map<String, dynamic>?> loginWithTable({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client
          .from('users')
          .select('*')
          .eq('email', email)
          .eq('password', password)
          .single();
      
      return response;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }
  
  /// Register new user in custom table
  static Future<Map<String, dynamic>?> registerWithTable({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await client
          .from('users')
          .insert({
            'email': email,
            'password': password,
            'full_name': fullName,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      print('Registration error: $e');
      return null;
    }
  }
  
  /// Check if email exists in users table
  static Future<bool> emailExists(String email) async {
    try {
      final response = await client
          .from('users')
          .select('email')
          .eq('email', email);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Email check error: $e');
      return false;
    }
  }
  
  /// Update password in users table
  static Future<bool> updatePassword({
    required String email,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // First verify old password
      final user = await loginWithTable(email: email, password: oldPassword);
      if (user == null) return false;
      
      // Update password
      await client
          .from('users')
          .update({'password': newPassword})
          .eq('email', email);
      
      return true;
    } catch (e) {
      print('Password update error: $e');
      return false;
    }
  }
  
  /// Reset password (for forgot password)
  static Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      await client
          .from('users')
          .update({'password': newPassword})
          .eq('email', email);
      
      return true;
    } catch (e) {
      print('Password reset error: $e');
      return false;
    }
  }
  
  /// Get user profile by email
  static Future<Map<String, dynamic>?> getUserProfile(String email) async {
    try {
      final response = await client
          .from('users')
          .select('id, email, full_name, created_at')
          .eq('email', email)
          .single();
      
      return response;
    } catch (e) {
      print('Get profile error: $e');
      return null;
    }
  }
  
  /// Update user profile
  static Future<bool> updateUserProfile({
    required String email,
    String? fullName,
    String? profilePicture,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (fullName != null) updates['full_name'] = fullName;
      if (profilePicture != null) updates['profile_picture'] = profilePicture;
      
      if (updates.isEmpty) return false;
      
      await client
          .from('users')
          .update(updates)
          .eq('email', email);
      
      return true;
    } catch (e) {
      print('Profile update error: $e');
      return false;
    }
  }
  
  /// Delete user account
  static Future<bool> deleteAccount(String email) async {
    try {
      await client
          .from('users')
          .delete()
          .eq('email', email);
      
      return true;
    } catch (e) {
      print('Account deletion error: $e');
      return false;
    }
  }
  
  // Utility methods
  
  /// Validate email format
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  /// Validate password strength
  static bool isValidPassword(String password) {
    return password.length >= 6;
  }
  
  /// Hash password (basic implementation)
  static String hashPassword(String password) {
    // In production, use proper hashing like bcrypt
    // This is just a placeholder
    return password; // TODO: Implement proper hashing
  }
  
  /// Generate random token for password reset
  static String generateResetToken() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return chars[(random % chars.length)] + 
           chars[((random ~/ 10) % chars.length)] +
           chars[((random ~/ 100) % chars.length)] +
           chars[((random ~/ 1000) % chars.length)] +
           chars[((random ~/ 10000) % chars.length)] +
           chars[((random ~/ 100000) % chars.length)];
  }
}

// User model for type safety
class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String? profilePicture;
  final DateTime createdAt;
  
  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.profilePicture,
    required this.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['full_name'],
      profilePicture: json['profile_picture'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'profile_picture': profilePicture,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
