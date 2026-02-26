import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quickserve/core/constants/appConstants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  static final AuthService instance = AuthService._();
  AuthService._();

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences once
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('🟢 SharedPreferences initialized');
  }

  /// Save Role
  static Future<void> saveRole(String role) async {
    await _prefs?.setString('role', role);
    debugPrint('💾 Role saved: $role');
  }

  /// Get Saved Role
  static String? getSavedRole() {
    return _prefs?.getString('role');
  }

  /// Sign Up
  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String role,
  ) async {
    debugPrint('🔐 Signing up with email: $email');

    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;
    if (user != null) {
      final token = await user.getIdToken();
      AppConstant.setUserUID(user.uid);
      AppConstant.setUserToken(token!);

      debugPrint('✅ Sign-up successful');
      debugPrint('📌 UID: ${user.uid}');
      debugPrint('📌 Token: $token');

      // ✅ Use pre-initialized SharedPreferences
      await _prefs?.setString('role', role);
      await _prefs?.setBool('isLoggedIn', true);
      debugPrint('💾 Saved role: $role and isLoggedIn: true');
    }

    return result;
  }

  /// Sign In
  Future<UserCredential> signInWithEmail(
    String email,
    String password,
    String role,
  ) async {
    debugPrint('🔐 Signing in with email: $email');

    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = result.user;
    if (user != null) {
      final token = await user.getIdToken();
      AppConstant.setUserUID(user.uid);
      AppConstant.setUserToken(token!);

      debugPrint('✅ Sign-in successful');
      debugPrint('📌 UID: ${user.uid}');
      debugPrint('📌 Token: $token');

      await _prefs?.setString('role', role);
      await _prefs?.setBool('isLoggedIn', true);
      debugPrint('💾 Updated role: $role and isLoggedIn: true');
    }

    return result;
  }

  /// Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    debugPrint('📩 Sending password reset email to: $email');
    await _auth.sendPasswordResetEmail(email: email);
    debugPrint('✅ Password reset email sent.');
  }

  /// Sign Out
  Future<void> signOut() async {
    debugPrint('🚪 Signing out...');
    await _auth.signOut();
    AppConstant.clearSession();

    await _prefs?.remove('role');
    await _prefs?.remove('isLoggedIn');
    debugPrint('✅ Sign-out successful and preferences cleared.');
  }
}
