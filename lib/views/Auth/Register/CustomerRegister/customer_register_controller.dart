import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/views/CustomerHome/widgets/home_page.dart';
import 'dart:io';
import 'package:quickserve/views/Auth/AuthService/auth_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CustomerRegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();

  final isLoading = false.obs;
  final selectedCity = ''.obs;
  final showOtpSection = false.obs;
  final verificationId = ''.obs;
  final resendToken = 0.obs;
  final selectedImageFile = Rx<XFile?>(null);

  // Persistent data variables
  final savedName = ''.obs;
  final savedEmail = ''.obs;
  final savedPhone = ''.obs;
  final savedCity = ''.obs;

  @override
  void onInit() {
    super.onInit();
    print("🔧 Initializing Firebase Auth settings...");
    _configureFirebaseAuth();
  }

  void _configureFirebaseAuth() {
    try {
      _auth.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: false,
      );
      print("✅ Firebase Auth settings configured");
    } catch (e) {
      print("⚠️ Could not configure auth settings: ${e.toString()}");
    }
  }

  // Send OTP to phone number
  Future<void> sendOtp(BuildContext context) async {
    print("==================== SEND OTP STARTED ====================");

    // Validate all fields using formKey
    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      print("❌ Validation Failed via formKey");
      _showErrorDialog(context, "Please fill all required fields correctly");
      return;
    }

    if (selectedImageFile.value == null) {
      _showErrorDialog(context, "Please select a profile picture");
      return;
    }

    print("✅ All validations passed");

    try {
      isLoading.value = true;
      print("🔄 Loading started");

      // Format phone number
      String formattedPhone = "+92${phoneController.text.trim()}";
      print("📱 Formatted phone number: $formattedPhone");

      // SAVE DATA BEFORE ASYNC
      savedName.value = nameController.text.trim();
      savedEmail.value = emailController.text.trim();
      savedPhone.value = formattedPhone;
      savedCity.value = selectedCity.value;
      print("💾 Saved Customer Data: ${savedName.value}, ${savedPhone.value}");

      // Check if phone already exists
      print("🔍 Checking if phone number already exists in Firestore...");
      final phoneQuery = await FirebaseFirestore.instance
          .collection("Customers")
          .where("phone", isEqualTo: formattedPhone)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        print("❌ Phone number already registered");
        _showErrorDialog(context, "Phone number already registered");
        isLoading.value = false;
        return;
      }
      print("✅ Phone number is available");

      // Check if email already exists (only if email is provided)
      if (emailController.text.trim().isNotEmpty) {
        print("🔍 Checking if email already exists in Firestore...");
        final emailQuery = await FirebaseFirestore.instance
            .collection("Customers")
            .where("email", isEqualTo: emailController.text.trim())
            .get();

        if (emailQuery.docs.isNotEmpty) {
          print("❌ Email already registered");
          _showErrorDialog(context, "Email already registered");
          isLoading.value = false;
          return;
        }
        print("✅ Email is available");
      }

      // Send OTP
      print("📤 Sending OTP to: $formattedPhone");
      print("🔑 Using resend token: ${resendToken.value}");

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 120),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print("✅ Auto verification completed");
          print("📋 Credential: ${credential.smsCode}");
          if (credential.smsCode != null) {
            otpController.text = credential.smsCode!;
            print("🔢 Auto-filled OTP: ${credential.smsCode}");
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print("❌ Verification Failed");
          print("Error code: ${e.code}");
          print("Error message: ${e.message}");

          isLoading.value = false;
          String errorMessage = "Phone verification failed";

          if (e.code == 'invalid-phone-number') {
            errorMessage = "Invalid phone number format";
          } else if (e.code == 'too-many-requests') {
            errorMessage = "Too many attempts. Please try again after some time";
            print("⚠️ Too many requests - Firebase has temporarily blocked this number");
          } else if (e.code == 'quota-exceeded') {
            errorMessage = "SMS quota exceeded. Please try again later";
            print("⚠️ SMS quota exceeded");
          } else if (e.code == 'network-request-failed') {
            errorMessage = "Network error. Please check your connection";
          }

          // Show dialog for consistency as requested
          _showErrorDialog(context, errorMessage);
        },
        codeSent: (String verificationIdReceived, int? resendTokenReceived) {
          print("✅ OTP sent successfully");
          print("📋 Verification ID: $verificationIdReceived");
          print("🔢 Resend Token: $resendTokenReceived");

          verificationId.value = verificationIdReceived;
          if (resendTokenReceived != null) {
            resendToken.value = resendTokenReceived;
            print("💾 Saved resend token for future use");
          }

          showOtpSection.value = true;
          isLoading.value = false;

          Get.snackbar(
            "Success",
            "OTP sent to $formattedPhone",
            backgroundColor: AppColors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );

          print("📱 OTP section now visible");
        },
        codeAutoRetrievalTimeout: (String verificationIdReceived) {
          print("⏱️ Auto retrieval timeout");
          print("📋 Verification ID: $verificationIdReceived");
          verificationId.value = verificationIdReceived;
        },
        forceResendingToken: resendToken.value != 0 ? resendToken.value : null,
      );

    } catch (e) {
      print("❌ Error in sendOtp: ${e.toString()}");
      print("📍 Error type: ${e.runtimeType}");

      isLoading.value = false;

      String errorMessage = "An error occurred while sending OTP";

      if (e.toString().contains('reCAPTCHA')) {
        errorMessage = "Verification failed. Please try again";
        print("⚠️ reCAPTCHA error detected");
      } else if (e.toString().contains('network')) {
        errorMessage = "Network error. Please check your connection";
      }

      _showErrorDialog(context, errorMessage);
    }

    print("==================== SEND OTP ENDED ====================\n");
  }

  // Verify OTP and Register User - UPDATED TO GO TO HOMEPAGE
  Future<void> verifyOtpAndRegister(BuildContext context) async {
    print("==================== VERIFY OTP STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      print("❌ OTP Validation Failed via formKey");
      return;
    }

    print("✅ OTP validation passed");
    print("🔢 Entered OTP: ${otpController.text.trim()}");

    try {
      isLoading.value = true;
      print("🔄 Loading started");

      // Create PhoneAuthCredential
      print("🔐 Creating PhoneAuthCredential...");
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otpController.text.trim(),
      );
      print("✅ PhoneAuthCredential created");

      // Sign in with phone credential
      print("📲 Signing in with phone credential...");
      UserCredential phoneAuthResult = await _auth.signInWithCredential(credential);
      print("✅ Phone authentication successful");
      print("👤 User UID: ${phoneAuthResult.user!.uid}");

      String formattedPhone = "+92${phoneController.text.trim()}";
      String finalEmail = emailController.text.trim();

      // If email is provided, link it to the account
      // If email is provided, TRY to link it, but don't block registration if it fails
      if (finalEmail.isNotEmpty) {
        print("📧 Email provided, attempting to link...");
        try {
          AuthCredential emailCredential = EmailAuthProvider.credential(
            email: finalEmail,
            password: passwordController.text.trim(),
          );

          await phoneAuthResult.user!.linkWithCredential(emailCredential);
          print("✅ Email linked successfully");
        } catch (e) {
          // KEY FIX: If linking fails (e.g. invalid email, used email), just log it
          // and CONTINUE registration. Do not sign out or show error.
          print("⚠️ Email linking failed but proceeding: $e");
          // We can optionally show a small toast, but user asked for "no error"
        }
      } else {
        print("ℹ️ No email provided, skipping email linking");
      }

      print("💾 Saving user data to Firestore...");
      
      String profileUrl = "";
      if (selectedImageFile.value != null) {
        print("📤 Uploading profile image...");
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images/${phoneAuthResult.user!.uid}');
        final uploadTask = await ref.putFile(File(selectedImageFile.value!.path));
        profileUrl = await uploadTask.ref.getDownloadURL();
        print("✅ Image uploaded: $profileUrl");
      }

      Map<String, dynamic> userData = {
        "uid": phoneAuthResult.user!.uid,
        "name": savedName.value.isNotEmpty ? savedName.value : nameController.text.trim(),
        "phone": savedPhone.value.isNotEmpty ? savedPhone.value : formattedPhone,
        "city": savedCity.value.isNotEmpty ? savedCity.value : selectedCity.value,
        "role": "customer",
        "profileImage": profileUrl,
        "createdAt": FieldValue.serverTimestamp(),
      };

      // Add email only if provided
      if (finalEmail.isNotEmpty) {
        userData["email"] = finalEmail;
        print("📧 Email added to user data: $finalEmail");
      } else {
        print("ℹ️ No email in user data");
      }

      print("📋 User data to save: $userData");

      await FirebaseFirestore.instance
          .collection("Customers")
          .doc(phoneAuthResult.user!.uid)
          .set(userData);

      print("✅ User data saved to Firestore");

      // Clear the resend token after successful registration
      resendToken.value = 0;
      print("🧹 Cleared resend token");

      Get.snackbar(
        "Success",
        "Account created successfully!",
        backgroundColor: AppColors.green,
        colorText: Colors.white,
      );

      print("🚀 Navigating to Customer HomePage...");
      // Save role as customer
      await AuthService.saveRole('customer');
      
      // Navigate directly to Customer HomePage
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAll(() => HomePage());

    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException occurred");
      print("Error code: ${e.code}");
      print("Error message: ${e.message}");

      String errorMessage = "Verification failed";

      if (e.code == 'invalid-verification-code') {
        errorMessage = "Invalid OTP code. Please check and try again";
      } else if (e.code == 'session-expired') {
        errorMessage = "OTP expired. Please request a new one";
        showOtpSection.value = false;
        otpController.clear();
      } else if (e.code == 'invalid-verification-id') {
        errorMessage = "Verification session expired. Please try again";
        showOtpSection.value = false;
        otpController.clear();
      }

      _showErrorDialog(context, errorMessage);
    } catch (e) {
      print("❌ Error in verifyOtpAndRegister: ${e.toString()}");
      _showErrorDialog(context, "An error occurred: ${e.toString()}");
    } finally {
      isLoading.value = false;
      print("🔄 Loading ended");
    }

    print("==================== VERIFY OTP ENDED ====================\n");
  }

  // Helper to show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // Resend OTP with proper token handling
  Future<void> resendOtp(BuildContext context) async {
    print("==================== RESEND OTP STARTED ====================");
    print("🔄 Resending OTP...");
    print("🔑 Current resend token: ${resendToken.value}");

    otpController.clear();
    print("🧹 Cleared OTP input");

    await sendOtp(context);

    print("==================== RESEND OTP ENDED ====================\n");
  }

  Future<void> pickImage() async {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Get.back();
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Get.back();
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
      isDismissible: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (source == ImageSource.camera && !kIsWeb) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          _showErrorDialog(Get.context!, 'Camera permission is required to take a photo');
          return;
        }
      }

      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        selectedImageFile.value = pickedFile;
      }
    } catch (e) {
      _showErrorDialog(Get.context!, 'Failed to pick image');
      print('Image picker error: $e');
    }
  }

  @override
  void onClose() {
    print("🧹 Disposing controllers...");
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.onClose();
  }
}