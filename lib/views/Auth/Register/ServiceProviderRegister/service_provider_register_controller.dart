import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickserve/core/widgets/saving_progress_widget.dart';
import 'package:quickserve/views/Auth/AccountScreens/account_verification_screen.dart';
import 'documents_upload_page.dart';
import 'package:quickserve/views/Auth/AuthService/auth_service.dart';
import 'package:quickserve/views/BottomNavbar/bottom_navbar.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/services/vt_otp_service.dart';

class ServiceProviderRegisterController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final currentUserId = ''.obs;
  final currentUserEmail = ''.obs;
  final currentUserName = ''.obs;
  final currentUserPhotoUrl = ''.obs;
  final verificationId = ''.obs;
  final resendToken = 0.obs;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final otpController = TextEditingController();
  final showOtpSection = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    otpController.dispose();
    super.onClose();
  }
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();
  final selectedCity = ''.obs;
  final completePhoneNumber = ''.obs;
  final isLoading = false.obs;
  final selectedImageFile = Rx<XFile?>(null);
  final cnicFront = Rx<XFile?>(null);
  final cnicBack = Rx<XFile?>(null);
  final selectedType = ''.obs;
  final selectedCategory = ''.obs;
  final selectedSubcategories = <String>[].obs;
  final skilledCategories = <String>[].obs;
  final unskilledCategories = <String>[].obs;
  final availableSubcategories = <String>[].obs;

  // Persistent data variables to prevent data loss on navigation/rebuilds
  final savedName = ''.obs;
  final savedEmail = ''.obs;
  final savedPhone = ''.obs;
  final savedPassword = ''.obs;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

// Update the print configuration method
  void _printGoogleSignInConfiguration() {
    debugPrint("🔧 ========================================");
    debugPrint("🔧 SERVICE PROVIDER GOOGLE SIGN-IN CONFIG");
    debugPrint("🔧 Using GoogleSignIn.instance (v7.2.0)");
    debugPrint("🔧 ========================================");
  }
  /// ============================================
  /// GOOGLE SIGN-IN FOR SERVICE PROVIDER
  /// ============================================
// Replace your existing signInWithGoogle method with this:


// Replace the entire signInWithGoogle method with this:
  Future<void> signInWithGoogle(BuildContext context) async {
    if (isLoading.value) {
      debugPrint("⚠️ Already signing in, ignoring duplicate tap");
      return;
    }

    try {
      isLoading.value = true;
      final timestamp = DateTime.now().toIso8601String();

      debugPrint("");
      debugPrint("🔵 ╔════════════════════════════════════════╗");
      debugPrint("🔵 ║  PROVIDER GOOGLE SIGN-IN STARTED       ║");
      debugPrint("🔵 ╚════════════════════════════════════════╝");
      debugPrint("🔵 Build Mode: ${const bool.fromEnvironment('dart.vm.product') ? '🔴 RELEASE' : '🟢 DEBUG'}");
      debugPrint("🔵 Timestamp: $timestamp");
      debugPrint("");

      // ═══════════════════════════════════════════════════════════
      // STEP 1: Initialize Google Sign-In
      // ═══════════════════════════════════════════════════════════
      debugPrint("📍 STEP 1/10: Initializing Google Sign-In...");
      try {
        await _googleSignIn.initialize();
        debugPrint("   ✓ Google Sign-In initialized");
      } catch (e) {
        debugPrint("   ⚠️ Initialization check: $e");
      }

      // ═══════════════════════════════════════════════════════════
      // STEP 2: Sign out from previous session
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 2/10: Clearing previous session...");
      try {
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        debugPrint("   ✓ Previous session cleared");
      } catch (e) {
        debugPrint("   ⚪ No previous session (expected): $e");
      }

      // ═══════════════════════════════════════════════════════════
      // STEP 3: Check if platform supports authenticate
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 3/10: Checking platform support...");
      if (!_googleSignIn.supportsAuthenticate()) {
        debugPrint("   ❌ Platform does not support authenticate method");
        _showErrorDialog(context, 'Google Sign-In is not supported on this platform');
        return;
      }
      debugPrint("   ✓ Platform supports authenticate method");

      // ═══════════════════════════════════════════════════════════
      // STEP 4: Set up authentication event listener
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 4/10: Setting up authentication listener...");

      final Completer<GoogleSignInAccount?> completer = Completer<GoogleSignInAccount?>();
      late StreamSubscription<GoogleSignInAuthenticationEvent> subscription;

      subscription = _googleSignIn.authenticationEvents.listen((event) {
        debugPrint("   📨 Authentication event received: ${event.runtimeType}");

        if (event is GoogleSignInAuthenticationEventSignIn) {
          debugPrint("   ✅ Sign-in event detected");
          subscription.cancel();
          completer.complete(event.user);
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          debugPrint("   ⚠️ Sign-out event detected");
          if (!completer.isCompleted) {
            subscription.cancel();
            completer.complete(null);
          }
        }
      }, onError: (error) {
        debugPrint("   ❌ Authentication event error: $error");
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.completeError(error);
        }
      });

      debugPrint("   ✓ Listener configured");

      // ═══════════════════════════════════════════════════════════
      // STEP 5: Trigger authentication
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 5/10: Triggering authentication...");
      debugPrint("   ⏳ Opening Google Sign-In dialog...");

      try {
        await _googleSignIn.authenticate();
        debugPrint("   ✓ Authenticate method called");
      } catch (authError) {
        debugPrint("");
        debugPrint("❌ ╔════════════════════════════════════════╗");
        debugPrint("❌ ║  AUTHENTICATION TRIGGER FAILED         ║");
        debugPrint("❌ ╚════════════════════════════════════════╝");
        debugPrint("❌ Error Type: ${authError.runtimeType}");
        debugPrint("❌ Error: $authError");
        debugPrint("");

        subscription.cancel();

        _showErrorDialog(context, 'Could not start Google Sign-In. Check SHA keys in Firebase Console.');
        return;
      }

      // ═══════════════════════════════════════════════════════════
      // STEP 6: Wait for authentication result
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 6/10: Waiting for user selection...");

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await completer.future.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            debugPrint("   ⏱️ Authentication timeout");
            subscription.cancel();
            return null;
          },
        );
      } catch (e) {
        debugPrint("   ❌ Error waiting for result: $e");
        subscription.cancel();
        return;
      }

      if (googleUser == null) {
        debugPrint("");
        debugPrint("⚠️ ╔════════════════════════════════════════╗");
        debugPrint("⚠️ ║  USER CANCELLED OR NO ACCOUNT          ║");
        debugPrint("⚠️ ╚════════════════════════════════════════╝");
        debugPrint("");
        return;
      }

      debugPrint("");
      debugPrint("✅ ╔════════════════════════════════════════╗");
      debugPrint("✅ ║  GOOGLE ACCOUNT SELECTED               ║");
      debugPrint("✅ ╚════════════════════════════════════════╝");
      debugPrint("✅ Email: ${googleUser.email}");
      debugPrint("✅ Display Name: ${googleUser.displayName ?? '(No name)'}");
      debugPrint("✅ ID: ${googleUser.id}");
      debugPrint("✅ Photo URL: ${googleUser.photoUrl ?? '(No photo)'}");
      debugPrint("");

      // ═══════════════════════════════════════════════════════════
      // STEP 7: Get authentication tokens
      // ═══════════════════════════════════════════════════════════
      debugPrint("📍 STEP 7/10: Retrieving authentication tokens...");

      GoogleSignInAuthentication googleAuth;
      try {
        // In v7.x, authentication is now synchronous
        googleAuth = googleUser.authentication;
        debugPrint("   ✓ Tokens retrieved");

        if (googleAuth.idToken != null) {
          debugPrint("   ✅ ID Token: EXISTS (${googleAuth.idToken!.length} chars)");
        } else {
          debugPrint("   ❌ ID Token: NULL ⚠️ CRITICAL ERROR");
        }
      } catch (tokenError) {
        debugPrint("");
        debugPrint("❌ ╔════════════════════════════════════════╗");
        debugPrint("❌ ║  TOKEN RETRIEVAL FAILED                ║");
        debugPrint("❌ ╚════════════════════════════════════════╝");
        debugPrint("❌ Error: $tokenError");
        debugPrint("");
        debugPrint("💡 THIS IS THE MOST COMMON PLAY STORE ISSUE!");
        debugPrint("   1️⃣ Get SHA-1 & SHA-256 from Play Console → App Integrity");
        debugPrint("   2️⃣ Add both keys to Firebase Console");
        debugPrint("   3️⃣ Re-download google-services.json");
        debugPrint("");

        _showErrorDialog(context, 'Failed to get tokens. Check Firebase SHA keys.');
        return;
      }

      // ═══════════════════════════════════════════════════════════
      // STEP 8: Validate ID Token
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 8/10: Validating ID token...");

      if (googleAuth.idToken == null) {
        debugPrint("");
        debugPrint("❌ ╔════════════════════════════════════════╗");
        debugPrint("❌ ║  ID TOKEN IS NULL                      ║");
        debugPrint("❌ ╚════════════════════════════════════════╝");
        debugPrint("");
        debugPrint("💡 Play Store signing key missing in Firebase");
        debugPrint("");

        _showErrorDialog(context, 'Play Store signing key not configured in Firebase.');
        return;
      }

      debugPrint("   ✅ ID Token validated");

      // ═══════════════════════════════════════════════════════════
      // STEP 9: Create Firebase credential and sign in
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 9/10: Creating Firebase credential...");

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      debugPrint("   ✓ Credential created");

      debugPrint("   🔐 Signing in to Firebase...");
      UserCredential? userCredential;
      try {
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
        debugPrint("   ✓ Firebase authentication successful");
      } catch (firebaseError) {
        debugPrint("");
        debugPrint("❌ ╔════════════════════════════════════════╗");
        debugPrint("❌ ║  FIREBASE AUTHENTICATION FAILED        ║");
        debugPrint("❌ ╚════════════════════════════════════════╝");
        debugPrint("❌ Error: $firebaseError");
        debugPrint("");

        _showErrorDialog(context, 'Authentication failed: ${firebaseError.toString()}');
        return;
      }

      final User? user = userCredential.user;

      if (user == null) {
        debugPrint("❌ Firebase returned NULL user");
        throw Exception("Firebase user is NULL after sign-in");
      }

      debugPrint("");
      debugPrint("✅ ╔════════════════════════════════════════╗");
      debugPrint("✅ ║  FIREBASE USER AUTHENTICATED           ║");
      debugPrint("✅ ╚════════════════════════════════════════╝");
      debugPrint("✅ UID: ${user.uid}");
      debugPrint("✅ Email: ${user.email ?? '(No email)'}");
      debugPrint("✅ Display Name: ${user.displayName ?? '(No name)'}");
      debugPrint("");

      currentUserId.value = user.uid;
      currentUserEmail.value = user.email ?? '';
      currentUserName.value = user.displayName ?? '';
      currentUserPhotoUrl.value = user.photoURL ?? '';

      // ═══════════════════════════════════════════════════════════
      // STEP 10: Check Firestore and navigate
      // ═══════════════════════════════════════════════════════════
      debugPrint("📍 STEP 10/10: Checking user status in Firestore...");

      final providerDoc = await FirebaseFirestore.instance
          .collection('ServiceProviders')
          .doc(user.uid)
          .get();

      if (providerDoc.exists) {
        debugPrint("");
        debugPrint("🟦 ╔════════════════════════════════════════╗");
        debugPrint("🟦 ║  EXISTING PROVIDER FOUND               ║");
        debugPrint("🟦 ╚════════════════════════════════════════╝");

        final data = providerDoc.data() as Map<String, dynamic>;
        final status = data['accountStatus'] ?? 'pending';

        debugPrint("📋 Status: $status");
        await Future.delayed(const Duration(milliseconds: 500));

        if (status == 'accepted') {
          debugPrint("✅ APPROVED → BottomNavbar");
          Get.offAll(() => BottomNavbar());
        } else if (status == 'rejected') {
          debugPrint("❌ REJECTED → Verification Screen");
          Get.offAll(() => const AccountVerificationScreen());
        } else {
          debugPrint("🟨 PENDING → Verification Screen");
          Get.offAll(() => const AccountVerificationScreen());
        }
        return;
      }

      // Check for account conflict
      debugPrint("   📋 Checking for account conflicts...");
      final customerDoc = await FirebaseFirestore.instance
          .collection('Customers')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        debugPrint("");
        debugPrint("⚠️ ╔════════════════════════════════════════╗");
        debugPrint("⚠️ ║  ACCOUNT CONFLICT                      ║");
        debugPrint("⚠️ ╚════════════════════════════════════════╝");
        debugPrint("");

        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();

        _showErrorDialog(context, 'This account is registered as Customer. Use a different account.');
        return;
      }

      // New provider registration flow
      debugPrint("   🆕 NEW PROVIDER → Fetching categories...");
      await fetchServiceCategories(context);

      debugPrint("   ✓ Categories loaded");
      debugPrint("   🚀 Navigating to Documents Upload...");
      
      // Save role as ServiceProvider
      await AuthService.saveRole('ServiceProvider');

      await Future.delayed(const Duration(milliseconds: 500));
      Get.off(() => const DocumentsUploadPage());

      debugPrint("");
      debugPrint("🟢 ╔════════════════════════════════════════╗");
      debugPrint("🟢 ║  SIGN-IN COMPLETE                      ║");
      debugPrint("🟢 ╚════════════════════════════════════════╝");
      debugPrint("");

    } on FirebaseAuthException catch (e) {
      debugPrint("");
      debugPrint("❌ FIREBASE AUTH EXCEPTION: ${e.code} - ${e.message}");
      debugPrint("");

      _showErrorDialog(context, _firebaseAuthMessage(e));

    } catch (e, stackTrace) {
      debugPrint("");
      debugPrint("❌ UNEXPECTED ERROR: $e");
      debugPrint("$stackTrace");
      debugPrint("");

      _showErrorDialog(context, 'Sign-in failed: ${e.toString()}');

    } finally {
      isLoading.value = false;
      debugPrint("🔵 Loading state cleared");
      debugPrint("");
    }
  }

  String _firebaseAuthMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Account exists with different credential.';
      case 'invalid-credential':
        return 'Invalid credential. Please try again.';
      case 'operation-not-allowed':
        return 'Operation not allowed. Contact support.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this credential.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      currentUserId.value = '';
      currentUserEmail.value = '';
      currentUserName.value = '';
      currentUserPhotoUrl.value = '';
      selectedCity.value = '';
      completePhoneNumber.value = '';
      phoneController.clear();
      selectedImageFile.value = null;
      cnicFront.value = null;
      cnicBack.value = null;
      selectedType.value = '';
      selectedCategory.value = '';
      selectedSubcategories.clear();

      debugPrint("✅ User signed out successfully");
    } catch (e) {
      debugPrint("❌ Error signing out: $e");
    }
  }

  Future<void> fetchServiceCategories(BuildContext context) async {
    try {
      isLoading.value = true;
      final firestore = FirebaseFirestore.instance;

      debugPrint('🔍 Fetching service categories...');

      skilledCategories.clear();
      unskilledCategories.clear();

      final skilledCategoryNames = [
        'Electrician',
        'Plumber',
        'Painter',
        'Carpenter',
        'Welder',
        'Solar Panel Technicians',
        'Fabricator',
        'AC Services',
        'CCTV Services',
        'Tiles Work',
      ];

      final unskilledCategoryNames = [
        'Helper',
        'Sweeper',
        'Gardener',
        'Guard',
        'Aya (Baby Caretaker)',
      ];

      for (var categoryName in skilledCategoryNames) {
        try {
          final doc = await firestore
              .collection('ServiceCategories')
              .doc('Skilled')
              .collection(categoryName)
              .doc(categoryName)
              .get();

          if (doc.exists) {
            skilledCategories.add(categoryName);
            debugPrint('✅ Found Skilled: $categoryName');
          }
        } catch (e) {
          debugPrint('⚠️ Skilled category not found: $categoryName');
        }
      }

      for (var categoryName in unskilledCategoryNames) {
        try {
          final doc = await firestore
              .collection('ServiceCategories')
              .doc('Unskilled')
              .collection(categoryName)
              .doc(categoryName)
              .get();

          if (doc.exists) {
            unskilledCategories.add(categoryName);
            debugPrint('✅ Found Unskilled: $categoryName');
          }
        } catch (e) {
          debugPrint('⚠️ Unskilled category not found: $categoryName');
        }
      }

      debugPrint('✅ Total Skilled: ${skilledCategories.length}');
      debugPrint('✅ Total Unskilled: ${unskilledCategories.length}');

      if (skilledCategories.isEmpty && unskilledCategories.isEmpty) {
        _showErrorDialog(context, 'No service categories available');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching categories: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      _showErrorDialog(context, 'Failed to load categories');
    } finally {
      isLoading.value = false;
    }
  }

  List<String> getCurrentCategoryList() {
    return selectedType.value == 'Skilled'
        ? skilledCategories
        : unskilledCategories;
  }

  void selectCategory(String category) {
    selectedCategory.value = category;
    selectedSubcategories.clear();
    fetchSubcategoriesForCategory(category);
  }

  void toggleSubcategory(String subcategory) {
    if (selectedSubcategories.contains(subcategory)) {
      selectedSubcategories.remove(subcategory);
    } else {
      selectedSubcategories.add(subcategory);
    }
  }

  Future<void> fetchSubcategoriesForCategory(String category) async {
    if (category.isEmpty || selectedType.value.isEmpty) return;

    try {
      isLoading.value = true;
      final firestore = FirebaseFirestore.instance;

      debugPrint('🔍 Fetching subcategories for: $category');
      debugPrint('🔍 Service Type: ${selectedType.value}');

      final doc = await firestore
          .collection('ServiceCategories')
          .doc(selectedType.value)
          .collection(category)
          .doc(category)
          .get();

      if (doc.exists) {
        final data = doc.data();

        if (data != null && data.containsKey('subcategories')) {
          final subcats = data['subcategories'];

          if (subcats is List && subcats.isNotEmpty) {
            availableSubcategories.value = List<String>.from(subcats);
            debugPrint(
              '✅ Loaded ${availableSubcategories.length} subcategories',
            );
          } else {
            availableSubcategories.clear();
            debugPrint('⚠️ Subcategories field is empty or not a list');
          }
        } else {
          availableSubcategories.clear();
          debugPrint('⚠️ No subcategories field found');
        }
      } else {
        availableSubcategories.clear();
        debugPrint('❌ Document does not exist');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching subcategories: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      availableSubcategories.clear();
    } finally {
      isLoading.value = false;
    }
  }

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
      // ✅ Camera permission is required only when using camera on mobile
      if (source == ImageSource.camera && !kIsWeb) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          _showErrorDialog(Get.context!, 'Camera permission is required to take a photo');
          return;
        }
      }

      // ✅ System picker (NO media permission needed)
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


  Future<void> pickDocumentWithOptions(BuildContext context, Rx<XFile?> targetFile) async {
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
                  final file = await _pickImageToFile(ImageSource.camera);
                  if (file != null) targetFile.value = file;
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  // Small delay to ensure bottom sheet closes before picker opens
                  await Future.delayed(const Duration(milliseconds: 300));
                  final file = await _pickImageToFile(ImageSource.gallery);
                  if (file != null) targetFile.value = file;
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

  Future<XFile?> _pickImageToFile(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) return pickedFile;
    } catch (e) {
      _showErrorDialog(Get.context!, 'Failed to pick image: $e');
    }
    return null;
  }

  bool validateDocuments(BuildContext context) {
    if (selectedCity.value.isEmpty) {
      _showErrorDialog(context, 'Please select a city');
      return false;
    }

    // Phone validation removed as per user request (captured in previous steps)


    if (selectedType.value.isEmpty) {
      _showErrorDialog(context, 'Please select service type');
      return false;
    }

    if (selectedCategory.value.isEmpty) {
      _showErrorDialog(context, 'Please select a category');
      return false;
    }

    if (selectedSubcategories.length < 3) {
      _showErrorDialog(context, 'Please select at least 3 skills');
      return false;
    }

    if (cnicFront.value == null) {
      _showErrorDialog(context, 'Please upload ID front image');
      return false;
    }

    if (cnicBack.value == null) {
      _showErrorDialog(context, 'Please upload ID back image');
      return false;
    }

    if (selectedImageFile.value == null && currentUserPhotoUrl.value.isEmpty) {
      _showErrorDialog(context, 'Please select a profile picture');
      return false;
    }

    return true;
  }

  Future<String> _uploadFileWithProgress(
      XFile file,
      String path,
      Function(double) onProgress,
      ) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final task = ref.putData(await file.readAsBytes());

    task.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress(progress);
    });

    final snapshot = await task;
    final url = await snapshot.ref.getDownloadURL();
    return url;
  }

  Future<void> submitRegistration(BuildContext context) async {
    if (!validateDocuments(context)) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorDialog(context, 'Authentication failed');
      return;
    }

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SavingProgressWidget(
          task: (updateProgress) async {
            // LINK EMAIL & PASSWORD CREDENTIAL START
            try {
              String emailToLink = currentUserEmail.value.isNotEmpty ? currentUserEmail.value 
                  : (savedEmail.value.isNotEmpty ? savedEmail.value : emailController.text.trim());
              String passwordToLink = savedPassword.value.isNotEmpty ? savedPassword.value : passwordController.text.trim();
              
              if (emailToLink.isNotEmpty && passwordToLink.isNotEmpty) {
                bool hasPasswordProvider = currentUser.providerData.any((info) => info.providerId == 'password');
                
                if (!hasPasswordProvider) {
                  debugPrint("🔗 Attempting to link new Email/Password credential...");
                  AuthCredential credential = EmailAuthProvider.credential(
                    email: emailToLink,
                    password: passwordToLink
                  );
                  await currentUser.linkWithCredential(credential);
                  debugPrint("✅ Email/Password linked successfully");
                } else {
                  // User already has a password provider (maybe from a previous customer account)
                  // We should update the email and password to the new one provided during SP registration
                  debugPrint("🔄 User already has password provider. Updating email and password...");
                  
                  // Update email if it's different
                  if (currentUser.email != emailToLink) {
                    debugPrint("📧 Updating email from ${currentUser.email} to $emailToLink");
                    await currentUser.verifyBeforeUpdateEmail(emailToLink);
                  }
                  
                  // Update password to the new one
                  debugPrint("🔑 Updating password...");
                  await currentUser.updatePassword(passwordToLink);
                  debugPrint("✅ Email and password updated successfully");
                }
              }
            } catch (e) {
               debugPrint("⚠️ Failed to link/update email/password: $e");
               // Proceed anyway, as phone auth is already active. 
               // This might happen if re-authentication is required for updateEmail/updatePassword.
            }
            // LINK EMAIL & PASSWORD CREDENTIAL END

            double overallProgress = 0.0;
            final userId = currentUser.uid;

            String profileUrl;

            if (selectedImageFile.value != null) {
              updateProgress(0.0);
              profileUrl = await _uploadFileWithProgress(
                selectedImageFile.value!,
                'profile_images/$userId',
                    (progress) {
                  updateProgress(progress * 0.25);
                },
              );
              overallProgress = 0.25;
            } else {
              profileUrl = currentUserPhotoUrl.value;
              overallProgress = 0.25;
            }
            updateProgress(overallProgress);

            final cnicFrontUrl = await _uploadFileWithProgress(
              cnicFront.value!,
              'documents/cnic_front/$userId',
                  (progress) {
                updateProgress(0.25 + (progress * 0.35));
              },
            );
            overallProgress = 0.6;
            updateProgress(overallProgress);

            final cnicBackUrl = await _uploadFileWithProgress(
              cnicBack.value!,
              'documents/cnic_back/$userId',
                  (progress) {
                updateProgress(0.6 + (progress * 0.35));
              },
            );
            overallProgress = 0.95;
            updateProgress(overallProgress);

            await FirebaseFirestore.instance
                .collection('ServiceProviders')
                .doc(userId)
                .set({
              'uid': userId,
              'name': currentUserName.value.isNotEmpty ? currentUserName.value 
                  : (savedName.value.isNotEmpty ? savedName.value : nameController.text.trim()),
              'email': currentUserEmail.value.isNotEmpty ? currentUserEmail.value 
                  : (savedEmail.value.isNotEmpty ? savedEmail.value : emailController.text.trim()),
              'phone': savedPhone.value.isNotEmpty 
                  ? savedPhone.value 
                  : (completePhoneNumber.value.isNotEmpty ? completePhoneNumber.value : '+92${phoneController.text.trim()}'),
              'role': 'ServiceProvider',
              'city': selectedCity.value,
              'serviceType': selectedType.value,
              'serviceCategory': selectedCategory.value,
              'subcategories': selectedSubcategories.toList(),
              'totalSubcategories': selectedSubcategories.length,
              'profileImage': profileUrl,
              'cnicFront': cnicFrontUrl,
              'cnicBack': cnicBackUrl,
              'accountStatus': 'pending',
              'reason': '',
              'createdAt': FieldValue.serverTimestamp(),
            });

            debugPrint(
              '✅ ServiceProvider data saved with role: ServiceProvider',
            );

            updateProgress(1.0);
            await Future.delayed(const Duration(milliseconds: 300));
          },
        ),
      );

      _showSnackbar(
        'Success',
        'Your application has been submitted for review',
      );

      await Future.delayed(const Duration(milliseconds: 300));
      Get.off(() => const AccountVerificationScreen());
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      _showErrorDialog(Get.context!, 'Registration failed: ${e.toString()}');

      debugPrint('Registration error: $e');
    }
  }

  // Continue to documents upload without OTP (using dummy email)
  Future<void> continueToDocumentsWithoutOtp(BuildContext context) async {
    print("==================== CONTINUE WITHOUT OTP STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      _showErrorDialog(context, "Please fill all required fields correctly");
      return;
    }

    if (selectedImageFile.value == null) {
      _showErrorDialog(context, "Please select a profile picture");
      return;
    }

    String rawPhone = phoneController.text.trim();
    String formattedPhone = "+92$rawPhone";
    String dummyEmail = "user_$rawPhone@thekaonline.pk";
    String dummyPassword = "pw_${rawPhone}_stable";

    try {
      isLoading.value = true;
      print("🔍 Checking if phone number already registered...");
      final phoneQuery = await FirebaseFirestore.instance
          .collection("ServiceProviders")
          .where("phone", isEqualTo: formattedPhone)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        isLoading.value = false;
        _showErrorDialog(context, "Phone number already registered. Please login.");
        return;
      }

      print("🔐 Creating Firebase account with dummy email: $dummyEmail");
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: dummyEmail,
        password: dummyPassword,
      );

      final user = userCredential.user;
      if (user == null) throw Exception("Registration failed");

      print("✅ Firebase account created. UID: ${user.uid}");

      // Save data for next screen
      savedName.value = nameController.text.trim();
      savedEmail.value = dummyEmail; // Use dummy email as primary
      savedPhone.value = formattedPhone;
      savedPassword.value = dummyPassword;

      print("🚀 Navigating to DocumentsUploadPage...");
      Get.to(() => const DocumentsUploadPage(), arguments: {
        'name': savedName.value,
        'email': savedEmail.value,
        'phone': savedPhone.value,
        'password': savedPassword.value,
        'city': selectedCity.value,
      });

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print("ℹ️ Email already in use. Signing in with dummy credentials...");
        try {
          UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: dummyEmail,
            password: dummyPassword,
          );
          final user = userCredential.user;
          if (user == null) throw Exception("Login failed");
          
          print("✅ Firebase account signed in. UID: ${user.uid}");
          
          // Save data for next screen
          savedName.value = nameController.text.trim();
          savedEmail.value = dummyEmail; 
          savedPhone.value = formattedPhone;
          savedPassword.value = dummyPassword;

          print("🚀 Navigating to DocumentsUploadPage...");
          Get.to(() => const DocumentsUploadPage(), arguments: {
            'name': savedName.value,
            'email': savedEmail.value,
            'phone': savedPhone.value,
            'password': savedPassword.value,
            'city': selectedCity.value,
          });
        } catch (signInError) {
          _showErrorDialog(context, "Auth Error: ${signInError.toString()}");
        }
      } else {
        _showErrorDialog(context, "Auth Error: ${e.message}");
      }
    } catch (e) {
      _showErrorDialog(context, "Error: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
    print("==================== CONTINUE WITHOUT OTP ENDED ====================\n");
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;
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

  // ==================== SERVICE PROVIDER REGISTRATION WITH OTP ====================
  Future<void> sendOtp(BuildContext context) async {
    debugPrint("==================== SEND OTP FOR SERVICE PROVIDER STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      _showErrorDialog(context, "Please fill all required fields correctly");
      return;
    }

    if (selectedImageFile.value == null) {
      _showErrorDialog(context, "Please select a profile picture first");
      return;
    }

    try {
      isLoading.value = true;

      String rawPhone = phoneController.text.trim();
      String formattedPhone = "+92$rawPhone";
      debugPrint("📱 Formatted phone number: $formattedPhone");

      // Verify if number already exists
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ServiceProviders')
          .where('phone', isEqualTo: formattedPhone)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        isLoading.value = false;
        _showErrorDialog(context, "This phone number is already registered as a Service Provider. Please login.");
        return;
      }

      // Check Customers collection too
      final customerQuery = await FirebaseFirestore.instance
          .collection('Customers')
          .where('phone', isEqualTo: formattedPhone)
          .get();

      if (customerQuery.docs.isNotEmpty) {
        isLoading.value = false;
        _showErrorDialog(context, "This phone number is already registered as a Customer.");
        return;
      }

      // SAVE FORM DATA LOCALLY BEFORE ASYNC GAP
      savedName.value = nameController.text.trim();
      savedEmail.value = emailController.text.trim();
      savedPhone.value = formattedPhone;
      savedPassword.value = passwordController.text.trim();
      debugPrint("💾 Temporary provider data saved locally");

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
      debugPrint("❌ Error in SP sendOtp: ${e.toString()}");
      _showErrorDialog(context, "Failed to send OTP. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resendOtp(BuildContext context) async {
    await sendOtp(context);
  }

  Future<void> verifyOtpAndContinue(BuildContext context) async {
    if (otpController.text.trim().isEmpty) {
      _showErrorDialog(context, "Please enter the OTP");
      return;
    }

    try {
      isLoading.value = true;
      final otp = otpController.text.trim();

      debugPrint("📲 SP OTP Verification started for ${savedPhone.value}");
      final verifyResult = VtOtpService.instance.verifyOtp(savedPhone.value, otp);

      switch (verifyResult) {
        case VtOtpVerifyResult.valid:
          debugPrint("✅ OTP verified. Proceeding with account creation...");
          await _createDummyAccountAndContinue(context);
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
      debugPrint("❌ SP OTP Verification failed: $e");
      _showErrorDialog(context, "An error occurred: ${e.toString()}");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createDummyAccountAndContinue(BuildContext context) async {
    String rawPhone = phoneController.text.trim();
    String formattedPhone = "+92$rawPhone";
    String dummyEmail = "user_$rawPhone@thekaonline.pk";
    String dummyPassword = "pw_${rawPhone}_stable";

    try {
      print("🔐 Creating Firebase account with dummy email: $dummyEmail");
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: dummyEmail,
        password: dummyPassword,
      );

      final user = userCredential.user;
      if (user == null) throw Exception("Registration failed");

      print("✅ Firebase account created. UID: ${user.uid}");

      savedEmail.value = dummyEmail; 
      savedPassword.value = dummyPassword;

      print("🚀 Navigating to DocumentsUploadPage...");
      Get.to(() => const DocumentsUploadPage(), arguments: {
        'name': savedName.value,
        'email': savedEmail.value,
        'phone': savedPhone.value,
        'password': savedPassword.value,
        'city': selectedCity.value,
      });

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print("ℹ️ Email already in use. Signing in with dummy credentials...");
        try {
          UserCredential userCredential = await _auth.signInWithEmailAndPassword(
            email: dummyEmail,
            password: dummyPassword,
          );
          final user = userCredential.user;
          if (user == null) throw Exception("Login failed");
          
          print("✅ Firebase account signed in. UID: ${user.uid}");
          
          savedEmail.value = dummyEmail; 
          savedPassword.value = dummyPassword;

          print("🚀 Navigating to DocumentsUploadPage...");
          Get.to(() => const DocumentsUploadPage(), arguments: {
            'name': savedName.value,
            'email': savedEmail.value,
            'phone': savedPhone.value,
            'password': savedPassword.value,
            'city': selectedCity.value,
          });
        } catch (signInError) {
          _showErrorDialog(context, "Auth Error: ${signInError.toString()}");
        }
      } else {
        _showErrorDialog(context, "Auth Error: ${e.message}");
      }
    } catch (e) {
      _showErrorDialog(context, "Error: ${e.toString()}");
    }
  }
  // Safe snackbar helper to prevent Overlay errors
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
}
