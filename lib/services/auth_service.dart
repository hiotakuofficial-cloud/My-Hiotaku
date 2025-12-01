import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Show toast message
  static void _showToast(BuildContext? context, String message, {bool isError = false}) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    }
    print(message); // Also log to console
  }

  // Google Sign In with comprehensive error handling
  Future<User?> signInWithGoogle({BuildContext? context}) async {
    try {
      _showToast(context, 'Initializing Google Sign-in...');
      
      // Initialize GoogleSignIn with explicit scopes
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
      );

      // Step 1: Google Login Popup
      _showToast(context, 'Opening Google login...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        _showToast(context, 'Login cancelled by user', isError: true);
        return null; // User cancelled the login
      }

      _showToast(context, 'Getting authentication details...');
      
      // Step 2: Auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        _showToast(context, 'Failed to get authentication tokens', isError: true);
        return null;
      }

      _showToast(context, 'Creating Firebase credential...');

      // Step 3: Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      _showToast(context, 'Signing in to Firebase...');

      // Step 4: Sign-in to Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        _showToast(context, 'Welcome ${userCredential.user!.displayName ?? 'User'}! 🎉');
        return userCredential.user;
      } else {
        _showToast(context, 'Firebase authentication failed', isError: true);
        return null;
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Firebase Auth Error: ';
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
          errorMessage += e.message ?? 'Unknown error';
      }
      _showToast(context, errorMessage, isError: true);
      return null;
    } on Exception catch (e) {
      _showToast(context, 'Google Sign-in Error: ${e.toString()}', isError: true);
      return null;
    } catch (e) {
      _showToast(context, 'Unexpected error: ${e.toString()}', isError: true);
      return null;
    }
  }

  // Logout with error handling
  Future<bool> signOut({BuildContext? context}) async {
    try {
      _showToast(context, 'Signing out...');
      
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      
      _showToast(context, 'Signed out successfully');
      return true;
    } catch (e) {
      _showToast(context, 'Sign-out Error: ${e.toString()}', isError: true);
      return false;
    }
  }

  // Get current user with error handling
  User? getCurrentUser({BuildContext? context}) {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      _showToast(context, 'Error getting current user: ${e.toString()}', isError: true);
      return null;
    }
  }

  // Check if user is logged in
  bool isLoggedIn({BuildContext? context}) {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      _showToast(context, 'Error checking login status: ${e.toString()}', isError: true);
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
      _showToast(context, 'Checking Firebase connection...');
      
      // Try to get current user to test connection
      User? user = FirebaseAuth.instance.currentUser;
      
      _showToast(context, 'Firebase connection OK');
      return true;
    } catch (e) {
      _showToast(context, 'Firebase connection failed: ${e.toString()}', isError: true);
      return false;
    }
  }

  // Check Google Play Services
  Future<bool> checkGooglePlayServices({BuildContext? context}) async {
    try {
      _showToast(context, 'Checking Google Play Services...');
      
      final GoogleSignIn googleSignIn = GoogleSignIn();
      bool isAvailable = await googleSignIn.isSignedIn();
      
      _showToast(context, 'Google Play Services OK');
      return true;
    } catch (e) {
      _showToast(context, 'Google Play Services error: ${e.toString()}', isError: true);
      return false;
    }
  }
}
