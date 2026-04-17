import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/services/vt_otp_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
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
  final addressController = TextEditingController(); // New

  final latitude = 0.0.obs; // New
  final longitude = 0.0.obs; // New
  final isFetchingLocation = false.obs; // New

  final isLoading = false.obs;
  final selectedCity = ''.obs;
  final showOtpSection = false.obs;
  final selectedImageFile = Rx<XFile?>(null);

  // Persistent data saved before async operations
  final savedName = ''.obs;
  final savedEmail = ''.obs;
  final savedPhone = ''.obs;
  final savedCity = ''.obs;

  // ==================== STEP 1: Send OTP ====================
  Future<void> sendOtp(BuildContext context) async {
    debugPrint("==================== SEND OTP STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      _showErrorDialog(context, "Please fill all required fields correctly");
      return;
    }

    if (selectedImageFile.value == null) {
      _showErrorDialog(context, "Please select a profile picture");
      return;
    }

    try {
      isLoading.value = true;

      String rawPhone = phoneController.text.trim();
      String formattedPhone = "+92$rawPhone";

      // Save form data before any async gap
      savedName.value = nameController.text.trim();
      savedEmail.value = emailController.text.trim();
      savedPhone.value = formattedPhone;
      savedCity.value = selectedCity.value;

      // Check if phone already registered
      debugPrint("🔍 Checking if phone already registered: $formattedPhone");
      final phoneQuery = await FirebaseFirestore.instance
          .collection("Customers")
          .where("phone", isEqualTo: formattedPhone)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        isLoading.value = false;
        _showErrorDialog(context, "Phone number already registered. Please login.");
        return;
      }

      // Also check ServiceProviders
      final providerQuery = await FirebaseFirestore.instance
          .collection("ServiceProviders")
          .where("phone", isEqualTo: formattedPhone)
          .get();

      if (providerQuery.docs.isNotEmpty) {
        isLoading.value = false;
        _showErrorDialog(context, "This phone number is already registered as a Service Provider.");
        return;
      }

      debugPrint("📤 Sending OTP to $formattedPhone via VeevoTech...");
      final result = await VtOtpService.instance.sendOtp(formattedPhone);

      if (result.isSuccess) {
        showOtpSection.value = true;
        _showSnackbar("Success", "OTP sent to $formattedPhone");
        debugPrint("✅ OTP sent successfully");
      } else {
        _showErrorDialog(context, result.errorMessage ?? "Failed to send OTP");
      }
    } catch (e) {
      debugPrint("❌ Error in sendOtp: ${e.toString()}");
      _showErrorDialog(context, "An error occurred while sending OTP");
    } finally {
      isLoading.value = false;
    }

    debugPrint("==================== SEND OTP ENDED ====================\n");
  }

  // ==================== STEP 2: Verify OTP & Register ====================
  Future<void> verifyOtpAndRegister(BuildContext context) async {
    debugPrint("==================== VERIFY OTP STARTED ====================");

    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      _showErrorDialog(context, "Please enter the OTP");
      return;
    }

    try {
      isLoading.value = true;

      final verifyResult =
          VtOtpService.instance.verifyOtp(savedPhone.value, otp);

      switch (verifyResult) {
        case VtOtpVerifyResult.valid:
          debugPrint("✅ OTP verified. Proceeding with registration...");
          await _createAccount(context);
          break;
        case VtOtpVerifyResult.invalid:
          _showErrorDialog(context, "Invalid OTP code. Please check and try again.");
          break;
        case VtOtpVerifyResult.expired:
          showOtpSection.value = false;
          otpController.clear();
          _showErrorDialog(context, "OTP has expired. Please request a new one.");
          break;
        case VtOtpVerifyResult.notFound:
          _showErrorDialog(context, "No OTP found. Please tap 'Send OTP' first.");
          break;
      }
    } catch (e) {
      debugPrint("❌ Error in verifyOtpAndRegister: ${e.toString()}");
      _showErrorDialog(context, "An error occurred: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }

    debugPrint("==================== VERIFY OTP ENDED ====================\n");
  }

  Future<void> _createAccount(BuildContext context) async {
    String rawPhone = savedPhone.value.replaceAll(RegExp(r'\D'), '');
    if (rawPhone.startsWith('92')) {
      rawPhone = rawPhone.substring(2);
    }
    String dummyEmail = "user_$rawPhone@thekaonline.pk";
    String dummyPassword = "pw_${rawPhone}_stable";

    debugPrint("🔐 Authenticating Firebase account: $dummyEmail");
    UserCredential userCredential;
    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: dummyEmail,
        password: dummyPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        debugPrint("ℹ️ Email already in use. Attempting sign-in with dummy credentials...");
        try {
          userCredential = await _auth.signInWithEmailAndPassword(
            email: dummyEmail,
            password: dummyPassword,
          );
        } on FirebaseAuthException catch (signInError) {
          if (signInError.code == 'invalid-credential' || signInError.code == 'wrong-password') {
            try {
              debugPrint("⚠️ Dummy password mismatch. Trying real entered password...");
              userCredential = await _auth.signInWithEmailAndPassword(
                email: dummyEmail,
                password: passwordController.text.trim(),
              );
              await userCredential.user?.updatePassword(dummyPassword);
              debugPrint("✅ Password recovered and reset to dummy for consistency");
            } catch (_) {
              throw FirebaseAuthException(
                code: 'invalid-credential',
                message: 'This phone number has a previous partial registration with a different password. Please try registering again with the password you previously entered, or login instead.',
              );
            }
          } else {
            rethrow;
          }
        }
      } else {
        rethrow;
      }
    }

    final user = userCredential.user;
    if (user == null) throw Exception("Registration failed");

    debugPrint("✅ Firebase authenticated. UID: ${user.uid}");

    // Upload profile image
    String profileUrl = "";
    if (selectedImageFile.value != null) {
      debugPrint("📤 Uploading profile image...");
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images/${user.uid}');
      await ref.putFile(File(selectedImageFile.value!.path));
      profileUrl = ref.fullPath;
    }

    // Generate password hash using SHA-256
    final bytes = utf8.encode(passwordController.text.trim());
    final digest = sha256.convert(bytes);
    final passwordHash = digest.toString();

    // Get coordinates from precise location OR typed address OR city
    double? lat = latitude.value != 0.0 ? latitude.value : null;
    double? lng = longitude.value != 0.0 ? longitude.value : null;

    try {
      // 1. Try geocoding the typed address if precise coordinates are 0.0
      if (lat == null && addressController.text.trim().isNotEmpty) {
        debugPrint("📍 Geocoding typed address: ${addressController.text}");
        List<Location> locations = await locationFromAddress("${addressController.text}, ${savedCity.value}, Pakistan");
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
          debugPrint("📍 Geocoded typed address to: $lat, $lng");
        }
      }

      // 2. Fallback to geocoding the city if still null
      if (lat == null && savedCity.value.isNotEmpty) {
        debugPrint("📍 Precision location not set, geocoding city: ${savedCity.value}");
        List<Location> locations = await locationFromAddress("${savedCity.value}, Pakistan");
        if (locations.isNotEmpty) {
          lat = locations.first.latitude;
          lng = locations.first.longitude;
          debugPrint("📍 Geocoded ${savedCity.value} to: $lat, $lng");
        }
      }
    } catch (e) {
      debugPrint("❌ Geocoding error: $e");
    }

    // Save to Firestore
    Map<String, dynamic> userData = {
      "uid": user.uid,
      "name": savedName.value,
      "phone": savedPhone.value,
      "city": savedCity.value,
      "role": "customer",
      "profileImage": profileUrl,
      "passwordHash": passwordHash, // Save the hashed password
      "createdAt": FieldValue.serverTimestamp(),
    };

    if (lat != null && lng != null) {
      userData["latitude"] = lat;
      userData["longitude"] = lng;
      userData["address"] = addressController.text; // Save address
    }

    if (savedEmail.value.isNotEmpty) {
      userData["email"] = savedEmail.value;
    }

    await FirebaseFirestore.instance
        .collection("Customers")
        .doc(user.uid)
        .set(userData);

    debugPrint("✅ User data saved to Firestore");

    await AuthService.saveRole('customer');
    _showSnackbar("Success", "Account created successfully!");
    Get.offAll(() => HomePage());
  }

  /// 📍 Get Current Location & Convert to Address
  Future<void> getCurrentLocation() async {
    isFetchingLocation.value = true;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        latitude.value = position.latitude;
        longitude.value = position.longitude;

        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = "${place.name}, ${place.locality}, ${place.administrativeArea}";
          addressController.text = address;
        }
      } else {
        Get.snackbar(
          "Permission Denied",
          "Location permission is required to fetch your position.",
          backgroundColor: AppColors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      debugPrint("❌ Error fetching location: $e");
      Get.snackbar(
        "Location Error",
        "Could not fetch your location. Please enter your address manually.",
        backgroundColor: AppColors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isFetchingLocation.value = false;
    }
  }

  // ==================== RESEND OTP ====================
  Future<void> resendOtp(BuildContext context) async {
    otpController.clear();
    showOtpSection.value = false;
    await sendOtp(context);
  }

  // ==================== IMAGE PICKER ====================
  Future<void> pickImage(BuildContext context) async {
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
                  Navigator.pop(context);
                  // Small delay to ensure bottom sheet closes before picker opens
                  await Future.delayed(const Duration(milliseconds: 300));
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  // Small delay to ensure bottom sheet closes before picker opens
                  await Future.delayed(const Duration(milliseconds: 300));
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
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
      debugPrint('Image picker error: $e');
    }
  }

  // ==================== HELPERS ====================

  // ==================== FACEBOOK SIGN-IN FOR CUSTOMER ====================
  Future<void> signInWithFacebook(BuildContext context) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      debugPrint("🔵 Facebook Sign-In Started for Customer");

      // 1. Trigger Facebook Login
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        debugPrint("✅ Facebook Login success");

        // 2. Create a credential
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);

        // 3. Sign in to Firebase
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user == null) throw Exception("Firebase Facebook Sign-In failed");

        debugPrint("✅ Firebase Facebook Sign-In successful. UID: ${user.uid}");

        // 4. Check if user already exists in Firestore as a Customer
        final customerDoc = await FirebaseFirestore.instance.collection('Customers').doc(user.uid).get();

        if (customerDoc.exists) {
          debugPrint("✅ User is existing Customer. Logging in...");
          await AuthService.saveRole('customer');
          Get.offAll(() => HomePage());
        } else {
          // 5. New user: Create account and navigate to Home
          debugPrint("🚀 New user from Facebook. Creating Customer record...");
          
          await FirebaseFirestore.instance.collection('Customers').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? "User",
            'email': user.email ?? "",
            'phone': user.phoneNumber ?? "",
            'profileImage': user.photoURL ?? "",
            'role': 'customer',
            'createdAt': FieldValue.serverTimestamp(),
          });

          await AuthService.saveRole('customer');
          Get.offAll(() => HomePage());
        }
      } else if (result.status == LoginStatus.cancelled) {
        debugPrint("⚪ Facebook Login cancelled");
      } else {
        debugPrint("❌ Facebook Login failed: ${result.message}");
        _showErrorDialog(context, result.message ?? "Facebook login failed");
      }
    } catch (e) {
      debugPrint("❌ Error in Customer Facebook sign-in: ${e.toString()}");
      _showErrorDialog(context, "Facebook Sign-In failed. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    Future.microtask(() {
      Get.snackbar(
        title,
        message,
        backgroundColor: isError ? AppColors.red : AppColors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    });
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    otpController.dispose();
    addressController.dispose(); // New
    super.onClose();
  }
}