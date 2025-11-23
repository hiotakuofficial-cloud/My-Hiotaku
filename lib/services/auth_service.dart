import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => _auth.currentUser != null;

  // Google Sign In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In...');
      
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('User canceled the sign-in');
        return null;
      }

      print('Google user: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('Access token: ${googleAuth.accessToken != null}');
      print('ID token: ${googleAuth.idToken != null}');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in to Firebase...');
      
      // Sign in to Firebase with the Google credential
      final result = await _auth.signInWithCredential(credential);
      
      print('Firebase sign-in successful: ${result.user?.email}');
      
      return result;
    } catch (e) {
      print('Google Sign-In Error Details: $e');
      if (e.toString().contains('network_error')) {
        throw Exception('Network error. Check internet connection.');
      } else if (e.toString().contains('sign_in_canceled')) {
        throw Exception('Sign-in was canceled.');
      } else if (e.toString().contains('sign_in_failed')) {
        throw Exception('Google Sign-In failed. Please try again.');
      } else {
        throw Exception('Authentication failed: ${e.toString()}');
      }
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Sign-Out Error: $e');
      throw Exception('Sign-Out failed: $e');
    }
  }

  // Get user display name
  static String get userName => _auth.currentUser?.displayName ?? 'User';

  // Get user email
  static String get userEmail => _auth.currentUser?.email ?? '';

  // Get user photo URL
  static String? get userPhotoUrl => _auth.currentUser?.photoURL;

  // Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}
