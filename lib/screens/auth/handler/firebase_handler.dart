import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'supabase.dart';

class FirebaseHandler {
  // Singleton GoogleSignIn instance for better performance
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'openid'],
  );

  // Pre-initialize Google Sign In for faster response
  static Future<void> preInitializeGoogleSignIn() async {
    try {
      // Trigger initialization by checking sign-in status
      await _googleSignIn.isSignedIn();
    } catch (e) {
    }
  }

  // Show error message only
  static void _showError(BuildContext? context, String message) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Show professional iOS-style success message
  static void _showSuccess(BuildContext? context, String message) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 14,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  // Google Sign In with clean error handling and account selection
  Future<User?> signInWithGoogle({BuildContext? context}) async {
    try {
      // Step 1: Force account selection by signing out first
      await _googleSignIn.signOut();
      
      // Step 2: Google Login Popup with account selection
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User cancelled the login
      }
      
      // Step 2: Auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _showError(context, 'Failed to get authentication tokens');
        return null;
      }

      // Step 3: Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Step 4: Sign-in to Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        // TODO: Sync user data with Supabase
        await _syncUserWithSupabase(userCredential.user!);
        _showSuccess(context, 'Welcome back, ${userCredential.user!.displayName?.split(' ')[0] ?? 'User'}');
        return userCredential.user;
      } else {
        _showError(context, 'Firebase authentication failed');
        return null;
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed: ';
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage += 'Account exists with different credential';
          break;
        case 'invalid-credential':
          errorMessage += 'Invalid credential provided';
          break;
        case 'operation-not-allowed':
          errorMessage += 'Google sign-in not enabled';
          break;
        case 'user-disabled':
          errorMessage += 'User account disabled';
          break;
        case 'user-not-found':
          errorMessage += 'User not found';
          break;
        case 'wrong-password':
          errorMessage += 'Wrong password';
          break;
        case 'network-request-failed':
          errorMessage += 'Network error - check internet connection';
          break;
        default:
          errorMessage += 'Authentication failed. Please try again.';
      }
      _showError(context, errorMessage);
      return null;
    } on PlatformException catch (e) {
      String errorMessage = 'Google Sign-in failed: ';
      switch (e.code) {
        case 'network_error':
          errorMessage = 'Network error. Please check your internet connection and try again.';
          break;
        case 'sign_in_canceled':
          return null; // User cancelled, don't show error
        case 'sign_in_failed':
          errorMessage = 'Google Sign-in failed. Please try again.';
          break;
        default:
          errorMessage = 'Google Sign-in error. Please try again later.';
      }
      _showError(context, errorMessage);
      return null;
    } on Exception catch (e) {
      _showError(context, 'Unexpected error occurred. Please try again.');
      return null;
    } catch (e) {
      _showError(context, 'Unexpected error occurred. Please try again.');
      return null;
    }
  }

  // Logout with error handling and proper disconnect
  Future<bool> signOut({BuildContext? context}) async {
    try {
      // Sign out from Google (not disconnect to allow account selection next time)
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      _showError(context, 'Sign-out failed. Please try again.');
      return false;
    }
  }

  // Get current user with error handling
  User? getCurrentUser({BuildContext? context}) {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      _showError(context, 'Unable to get user information.');
      return null;
    }
  }

  // Check if user is logged in
  bool isLoggedIn({BuildContext? context}) {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      _showError(context, 'Unable to check login status.');
      return false;
    }
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges {
    return FirebaseAuth.instance.authStateChanges();
  }

  // Check Firebase connection
  Future<bool> checkFirebaseConnection({BuildContext? context}) async {
    try {
      // Check Firebase connection
      User? user = FirebaseAuth.instance.currentUser;
      return true;
    } catch (e) {
      _showError(context, 'Connection failed. Please check your internet.');
      return false;
    }
  }

  // Check Google Play Services
  Future<bool> checkGooglePlayServices({BuildContext? context}) async {
    try {
      await _googleSignIn.isSignedIn();
      return true;
    } catch (e) {
      _showError(context, 'Google Play Services unavailable.');
      return false;
    }
  }

  // Email/Password Sign Up
  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    BuildContext? context,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(name);
      
      if (userCredential.user != null) {
        // TODO: Create user in Supabase
        await _syncUserWithSupabase(userCredential.user!);
        _showSuccess(context, 'Account created successfully!');
        return userCredential.user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign up failed: ';
      switch (e.code) {
        case 'weak-password':
          errorMessage += 'Password is too weak';
          break;
        case 'email-already-in-use':
          errorMessage += 'Email already registered';
          break;
        case 'invalid-email':
          errorMessage += 'Invalid email address';
          break;
        default:
          errorMessage += 'Authentication failed. Please try again.';
      }
      _showError(context, errorMessage);
      return null;
    } catch (e) {
      _showError(context, 'Sign up failed. Please try again.');
      return null;
    }
  }

  // Email/Password Sign In
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
    BuildContext? context,
  }) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // TODO: Sync user data with Supabase
        await _syncUserWithSupabase(userCredential.user!);
        _showSuccess(context, 'Welcome back!');
        return userCredential.user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed: ';
      switch (e.code) {
        case 'user-not-found':
          errorMessage += 'No account found with this email';
          break;
        case 'wrong-password':
          errorMessage += 'Incorrect password';
          break;
        case 'invalid-email':
          errorMessage += 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage += 'Account has been disabled';
          break;
        default:
          errorMessage += 'Authentication failed. Please try again.';
      }
      _showError(context, errorMessage);
      return null;
    } catch (e) {
      _showError(context, 'Login failed. Please try again.');
      return null;
    }
  }

  // TODO: Sync Firebase user with Supabase database
  static Future<void> _syncUserWithSupabase(User firebaseUser) async {
    try {
      // Check if user exists in Supabase
      final existingUser = await SupabaseHandler.getUserByFirebaseUID(firebaseUser.uid);
      
      if (existingUser != null) {
        // User exists, update basic info but keep custom avatar
        String avatarToUpdate = existingUser['avatar_url'] ?? 'default.png';
        
        await SupabaseHandler.upsertUser(
          firebaseUID: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          avatarUrl: avatarToUpdate,
          username: existingUser['username'], // Keep existing username
        );
      } else {
        // New user, create with default avatar ID
        await SupabaseHandler.upsertUser(
          firebaseUID: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          avatarUrl: 'default.png', // Always default for new users
          username: _generateUsername(firebaseUser),
        );
      }
    } catch (e) {
    }
  }

  // Generate unique username from display name or email
  static String? _generateUsername(User firebaseUser) {
    String baseUsername;
    
    if (firebaseUser.displayName != null) {
      baseUsername = firebaseUser.displayName!
          .toLowerCase()
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    } else if (firebaseUser.email != null) {
      baseUsername = firebaseUser.email!.split('@')[0].toLowerCase();
    } else {
      baseUsername = 'user';
    }
    
    // Add timestamp to ensure uniqueness
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '${baseUsername}_$timestamp';
  }
}
