import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Authentication service for Google Sign-In
class AuthService extends ChangeNotifier {
  static AuthService? _instance;
  static AuthService get instance {
    _instance ??= AuthService._();
    return _instance!;
  }

  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isLoading => _isLoading;

  String? get displayName => _user?.displayName;
  String? get email => _user?.email;
  String? get photoUrl => _user?.photoURL;
  String? get uid => _user?.uid;

  /// Initialize auth service
  Future<void> initialize() async {
    // Listen for auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);

    // Check current user
    _user = _auth.currentUser;
    notifyListeners();
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners();
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return null; // User cancelled
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;

      // Save user ID locally for pairing
      if (_user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', _user!.uid);
      }

      _isLoading = false;
      notifyListeners();
      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Check if user is authenticated
  bool checkAuth() {
    return _auth.currentUser != null;
  }
}
