import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class FirebaseHandler {
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

  // Google Sign In with clean error handling
  Future<User?> signInWithGoogle({BuildContext? context}) async {
    try {
      // Initialize GoogleSignIn with explicit scopes
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
      );

      // Step 1: Google Login Popup
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
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
          errorMessage += e.message ?? 'Unknown error';
      }
      _showError(context, errorMessage);
      return null;
    } on Exception catch (e) {
      _showError(context, 'Google Sign-in Error: ${e.toString()}');
      return null;
    } catch (e) {
      _showError(context, 'Unexpected error: ${e.toString()}');
      return null;
    }
  }

  // Logout with error handling
  Future<bool> signOut({BuildContext? context}) async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      _showError(context, 'Sign-out Error: ${e.toString()}');
      return false;
    }
  }

  // Get current user with error handling
  User? getCurrentUser({BuildContext? context}) {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      _showError(context, 'Error getting current user: ${e.toString()}');
      return null;
    }
  }

  // Check if user is logged in
  bool isLoggedIn({BuildContext? context}) {
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (e) {
      _showError(context, 'Error checking login status: ${e.toString()}');
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
      // Try to get current user to test connection
      User? user = FirebaseAuth.instance.currentUser;
      return true;
    } catch (e) {
      _showError(context, 'Firebase connection failed: ${e.toString()}');
      return false;
    }
  }

  // Check Google Play Services
  Future<bool> checkGooglePlayServices({BuildContext? context}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      bool isAvailable = await googleSignIn.isSignedIn();
      return true;
    } catch (e) {
      _showError(context, 'Google Play Services error: ${e.toString()}');
      return false;
    }
  }
}
