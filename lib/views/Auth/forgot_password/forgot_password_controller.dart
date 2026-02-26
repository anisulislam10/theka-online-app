import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';

import '../../../core/services/internet_connectivity.dart';

class ForgotPasswordController extends GetxController {
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your email";
    }
    if (!value.contains("@")) {
      return "Enter a valid email address";
    }
    return null;
  }

  Future<void> sendResetLink() async {
    if (!formKey.currentState!.validate()) {
      _showSnack("Error", "Please enter a valid email", AppColors.red);
      return;
    }

    if (!await NetworkHelper.hasConnection()) {
      _showSnack(
        "No Internet",
        "Please check your connection",
        AppColors.primary,
      );
      return;
    }

    try {
      isLoading.value = true;

      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      isLoading.value = false;
      Get.back();
      _showSnack(
        "Password Reset",
        "A reset link has been sent to ${emailController.text}",
        Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      _handleFirebaseError(e);
    } catch (e) {
      isLoading.value = false;
      _showSnack(
        "Error",
        "Something went wrong. Please try again.",
        Colors.red,
      );
    }
  }

  void _handleFirebaseError(FirebaseAuthException e) {
    String msg;
    switch (e.code) {
      case 'user-not-found':
        msg = "No user found with this email.";
        break;
      case 'invalid-email':
        msg = "Invalid email format.";
        break;
      default:
        msg = e.message ?? "Failed to send reset link.";
    }
    _showSnack("Error", msg, Colors.red);
  }

  void _showSnack(String title, String msg, Color bg) {
    Get.snackbar(
      title,
      msg,
      backgroundColor: bg,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }
}
