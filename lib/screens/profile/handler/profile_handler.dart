import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/handler/supabase.dart';

class ProfileHandler {
  
  // TODO: Get current user data from Supabase
  static Future<Map<String, dynamic>?> getCurrentUserData() async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        return null;
      }
      
      
      final userData = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      if (userData == null) {
      } else {
      }
      
      return userData;
    } catch (e) {
      return null;
    }
  }
  
  // TODO: Update user profile data
  static Future<bool> updateUserProfile({
    required String displayName,
    String? avatarUrl,
    String? username,
  }) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      // Update Firebase display name
      await firebaseUser.updateDisplayName(displayName);
      
      // Update Supabase data
      final success = await SupabaseHandler.updateData(
        table: 'users',
        data: {
          'display_name': displayName,
          'avatar_url': avatarUrl,
          'username': username,
          'updated_at': SupabaseHandler.getCurrentTimestamp(),
        },
        filters: {'firebase_uid': firebaseUser.uid},
      );
      
      return success;
    } catch (e) {
      return false;
    }
  }
  
  // TODO: Update avatar only
  static Future<bool> updateAvatar(String avatarId) async {
    try {
      final User? firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) return false;
      
      // Save only the avatar filename (e.g., "male1.png") to Supabase
      final success = await SupabaseHandler.updateData(
        table: 'users',
        data: {
          'avatar_url': avatarId,
          'updated_at': SupabaseHandler.getCurrentTimestamp(),
        },
        filters: {'firebase_uid': firebaseUser.uid},
      );
      
      return success;
    } catch (e) {
      return false;
    }
  }
  
  // TODO: Get user favorites count
  static Future<int> getUserFavoritesCount() async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return 0;
      
      final favorites = await SupabaseHandler.getUserFavorites(userData['id']);
      return favorites?.length ?? 0;
    } catch (e) {
      return 0;
    }
  }
  
  // TODO: Logout user
  static Future<bool> logoutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      return false;
    }
  }
}
