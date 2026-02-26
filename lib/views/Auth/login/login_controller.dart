import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/views/BottomNavbar/bottom_navbar.dart';
import 'package:quickserve/views/CustomerHome/widgets/home_page.dart';
import 'package:quickserve/views/Auth/AuthService/auth_service.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  // State management
  final isLoading = false.obs;
  final isPhoneLogin = true.obs; // true = phone login, false = email login
  final showOtpSection = false.obs;
  final verificationId = ''.obs;
  final resendToken = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _configureFirebaseAuth();
  }

  void _configureFirebaseAuth() {
    try {
      _auth.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: false,
      );
      debugPrint("✅ Firebase Auth settings configured");
    } catch (e) {
      debugPrint("⚠️ Could not configure auth settings: ${e.toString()}");
    }
  }

  // Toggle between phone and email login
  void toggleLoginMethod() {
    isPhoneLogin.value = !isPhoneLogin.value;
    showOtpSection.value = false;
    // Clear all fields when switching
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    otpController.clear();
    formKey.currentState?.reset();
    debugPrint("🔄 Switched to ${isPhoneLogin.value ? 'Phone' : 'Email'} login");
  }

  // ==================== PHONE LOGIN WITH OTP ====================
  Future<void> sendLoginOtp(BuildContext context) async {
    debugPrint("==================== SEND LOGIN OTP STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;
      String formattedPhone = "+92${phoneController.text.trim()}";
      debugPrint("📱 Checking registration for: $formattedPhone");

      // Check if user is registered in either collection
      bool isRegistered = await _checkIfPhoneRegistered(formattedPhone);

      if (!isRegistered) {
        isLoading.value = false;
        if (context.mounted) {
          _showNotRegisteredDialog(context, "not_registered_error".tr);
        }
        return;
      }

      debugPrint("📱 Sending OTP to: $formattedPhone");
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint("✅ Auto verification completed");
          if (credential.smsCode != null) {
            otpController.text = credential.smsCode!;
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("❌ Verification Failed: ${e.code}");
          isLoading.value = false;

          String errorMessage = "Phone verification failed";
          if (e.code == 'invalid-phone-number') {
            errorMessage = "Invalid phone number format";
          } else if (e.code == 'too-many-requests') {
            errorMessage = "Too many attempts. Please try again later";
          }

          Get.snackbar(
            "Error",
            errorMessage,
            backgroundColor: AppColors.red,
            colorText: Colors.white,
          );
        },
        codeSent: (String verificationIdReceived, int? resendTokenReceived) {
          debugPrint("✅ OTP sent successfully");
          verificationId.value = verificationIdReceived;
          if (resendTokenReceived != null) {
            resendToken.value = resendTokenReceived;
          }

          showOtpSection.value = true;
          isLoading.value = false;

          Get.snackbar(
            "Success",
            "OTP sent to $formattedPhone",
            backgroundColor: AppColors.green,
            colorText: Colors.white,
          );
        },
        codeAutoRetrievalTimeout: (String verificationIdReceived) {
          verificationId.value = verificationIdReceived;
        },
        forceResendingToken: resendToken.value != 0 ? resendToken.value : null,
      );
    } catch (e) {
      debugPrint("❌ Error in sendLoginOtp: ${e.toString()}");
      isLoading.value = false;
      Get.snackbar(
        "Error",
        "Failed to send OTP",
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
    }

    debugPrint("==================== SEND LOGIN OTP ENDED ====================\n");
  }

  Future<void> verifyOtpAndLogin(BuildContext context) async {
    debugPrint("==================== VERIFY OTP AND LOGIN STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;

      // Create credential and sign in
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otpController.text.trim(),
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw Exception("Login failed");
      }

      debugPrint("✅ Phone authentication successful. UID: ${user.uid}");

      // Check user type and navigate
      await _checkUserTypeAndNavigate(user.uid);

    } on FirebaseAuthException catch (e) {
      debugPrint("❌ FirebaseAuthException: ${e.code}");

      String errorMessage = "Verification failed";
      if (e.code == 'invalid-verification-code') {
        errorMessage = "Invalid OTP. Please check and try again";
      } else if (e.code == 'session-expired') {
        errorMessage = "OTP expired. Please request a new one";
        showOtpSection.value = false;
        otpController.clear();
      }

      Get.snackbar(
        "Error",
        errorMessage,
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      debugPrint("❌ Error: ${e.toString()}");
      Get.snackbar(
        "Error",
        "Login failed",
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }

    debugPrint("==================== VERIFY OTP AND LOGIN ENDED ====================\n");
  }

  Future<void> resendLoginOtp(BuildContext context) async {
    debugPrint("🔄 Resending login OTP...");
    otpController.clear();
    await sendLoginOtp(context);
  }

  // ==================== EMAIL LOGIN WITH PASSWORD ====================
  Future<void> loginWithEmail(BuildContext context) async {
    debugPrint("==================== EMAIL LOGIN STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }

    try {
      isLoading.value = true;
      debugPrint("⏳ Attempting email login for: ${emailController.text.trim()}");

      // Firebase Auth login
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception("Login failed");
      }

      debugPrint("✅ Email login successful. UID: ${user.uid}");

      // Check user type and navigate
      await _checkUserTypeAndNavigate(user.uid);

    } on FirebaseAuthException catch (e) {
      debugPrint("❌ FirebaseAuthException: ${e.code}");

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "user_not_found_error".tr;
          break;
        case 'wrong-password':
          errorMessage = "wrong_password_error".tr;
          break;
        case 'invalid-email':
          errorMessage = "invalid_email_error".tr;
          break;
        case 'user-disabled':
          errorMessage = "user_disabled_error".tr;
          break;
        case 'too-many-requests':
          errorMessage = "too_many_requests_error".tr;
          break;
        case 'invalid-credential':
          errorMessage = "invalid_credential_error".tr;
          break;
        default:
          errorMessage = "${'login_failed_error'.tr}: ${e.message}";
      }
      
      // Use Dialog instead of Snackbar for better visibility
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("error_title".tr, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: Text(errorMessage),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.white,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("❌ Error: ${e.toString()}");
      Get.snackbar(
        "error_title".tr,
        e.toString(),
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }

    debugPrint("==================== EMAIL LOGIN ENDED ====================\n");
  }

  // ==================== HELPERS ====================
  Future<bool> _checkIfPhoneRegistered(String phone) async {
    try {
      // Check in Customers collection
      final customerQuery = await FirebaseFirestore.instance
          .collection('Customers')
          .where('phone', isEqualTo: phone)
          .get();

      if (customerQuery.docs.isNotEmpty) return true;

      // Check in ServiceProviders collection
      final providerQuery = await FirebaseFirestore.instance
          .collection('ServiceProviders')
          .where('phone', isEqualTo: phone)
          .get();

      if (providerQuery.docs.isNotEmpty) return true;

      return false;
    } catch (e) {
      debugPrint("❌ Error in _checkIfPhoneRegistered: $e");
      return false;
    }
  }

  void _showNotRegisteredDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("error_title".tr, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ==================== CHECK USER TYPE AND NAVIGATE ====================
  Future<void> _checkUserTypeAndNavigate(String uid) async {
    debugPrint("🔍 Checking user type for UID: $uid");

    try {
      // Check in Customers collection first
      final customerDoc = await FirebaseFirestore.instance
          .collection('Customers')
          .doc(uid)
          .get();

      if (customerDoc.exists) {
        debugPrint("✅ User is a Customer");
        await AuthService.saveRole('customer');
        Get.offAll(() => HomePage());
        Get.snackbar(
          "welcome_back".tr,
          "login_subtitle".tr,
          backgroundColor: AppColors.green,
          colorText: Colors.white,
        );
        return;
      }

      // Check in ServiceProviders collection
      final providerDoc = await FirebaseFirestore.instance
          .collection('ServiceProviders')
          .doc(uid)
          .get();

      if (providerDoc.exists) {
        debugPrint("✅ User is a Service Provider");
        await AuthService.saveRole('ServiceProvider');
        Get.offAll(() => BottomNavbar());
        Get.snackbar(
          "welcome_back".tr,
          "login_subtitle".tr,
          backgroundColor: AppColors.green,
          colorText: Colors.white,
        );
        return;
      }

      // User not found in either collection
      debugPrint("❌ User not found in any collection");
      await _auth.signOut();
      Get.snackbar(
        "error_title".tr,
        "account_data_missing_error".tr,
        backgroundColor: AppColors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

    } catch (e) {
      debugPrint("❌ Error checking user type: ${e.toString()}");
      await _auth.signOut();
      Get.snackbar(
        "error_title".tr,
        "auth_failed".tr,
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.onClose();
  }
}