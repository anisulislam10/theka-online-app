import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/views/BottomNavbar/bottom_navbar.dart';
import 'package:quickserve/views/Auth/AuthService/auth_service.dart';

class ProviderLoginController extends GetxController {
  /// Text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  /// Loading state
  final isLoading = false.obs;

  /// Login method (ServiceProviders only)
  Future<void> login(BuildContext context) async {
    debugPrint("🔹 Starting ServiceProvider login process...");

    // ✅ Input validation
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      debugPrint("⚠️ Validation failed: Missing email or password");
      Get.snackbar(
        "Missing Information",
        "Please enter both email and password",
        backgroundColor: AppColors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      debugPrint("⏳ Attempting login for: ${emailController.text.trim()}");

      // ✅ Firebase Auth login
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

      final user = userCredential.user;
      if (user == null) {
        debugPrint("❌ Firebase returned null user");
        throw Exception("Login failed. Please try again.");
      }

      debugPrint("✅ Login successful. UID: ${user.uid}");

      // ✅ Verify from 'ServiceProviders' collection only
      final userDoc = await FirebaseFirestore.instance
          .collection('ServiceProviders')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Not a registered service provider
        await FirebaseAuth.instance.signOut();
        Get.snackbar(
          "Access Denied",
          "This email is not registered as a service provider.",
          backgroundColor: AppColors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // ✅ Success — Determine redirection based on status
      final data = userDoc.data();
      final status = data?['accountStatus'] ?? 'pending';
      
      await AuthService.saveRole('ServiceProvider');

      if (status == 'accepted') {
        Get.offAll(() => BottomNavbar());
        debugPrint("🎉 Service provider login successful - To Dashboard");
      } else {
        Get.offAll(() => const AccountVerificationScreen());
        debugPrint("⏳ Service provider login successful - To Verification Screen");
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ FirebaseAuthException: ${e.code}");
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No account found with this email.";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password. Please try again.";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email format.";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled.";
          break;
        case 'too-many-requests':
          errorMessage = "Too many failed attempts. Try again later.";
          break;
        case 'network-request-failed':
          errorMessage = "Network error. Check your internet connection.";
          break;
        default:
          errorMessage = "Login failed: ${e.message}";
      }

      Get.snackbar(
        "Login Error",
        errorMessage,
        backgroundColor: AppColors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint("❌ General Error during login: $e");
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: AppColors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      debugPrint("🟢 Loading state reset. Login flow ended.");
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
