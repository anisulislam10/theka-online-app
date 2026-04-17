// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:quickserve/core/constants/appColors.dart';
// import 'package:quickserve/views/CustomerHome/widgets/home_page.dart';

// class LoginController extends GetxController {
//   /// Text controllers
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();

//   /// Loading state
//   final isLoading = false.obs;

//   /// Detect if input is email
//   bool _isEmail(String input) {
//     return input.contains('@');
//   }

//   /// 🔹 Normalize Pakistani phone number to +92XXXXXXXXXX
//   String normalizePhone(String input) {
//     // Remove spaces, dashes, brackets
//     input = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');

//     // Already correct format: +92XXXXXXXXXX
//     if (input.startsWith('+92') && input.length == 13) {
//       return input;
//     }

//     // 92XXXXXXXXXX → add +
//     if (input.startsWith('92') && input.length == 12) {
//       return '+$input';
//     }

//     // 0XXXXXXXXXX → convert to +92XXXXXXXXXX
//     if (input.startsWith('0') && input.length == 11) {
//       return '+92${input.substring(1)}';
//     }

//     // XXXXXXXXXX → convert to +92XXXXXXXXXX
//     if (input.length == 10) {
//       return '+92$input';
//     }

//     // If nothing matches → return cleaned input
//     return input;
//   }

//   /// 🔹 Login method (Customers only)
//   Future<void> login(BuildContext context) async {
//     debugPrint("🔹 Starting Customer login process...");

//     if (emailController.text.isEmpty || passwordController.text.isEmpty) {
//       Get.snackbar(
//         "Missing Information",
//         "Please enter both email/phone number and password",
//         backgroundColor: AppColors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     try {
//       isLoading.value = true;
//       String input = emailController.text.trim();
//       String? emailToUse;

//       // Email Login
//       if (_isEmail(input)) {
//         emailToUse = input;
//         debugPrint("⏳ Attempting email login for: $emailToUse");
//       } else {
//         // Phone Login
//         debugPrint("⏳ Attempting phone number login for: $input");

//         String phoneNumber = normalizePhone(input);
//         debugPrint("📞 Normalized phone: $phoneNumber");

//         // Query Firestore for phone
//         final querySnapshot = await FirebaseFirestore.instance
//             .collection('Customers')
//             .where('phone', isEqualTo: phoneNumber)
//             .limit(1)
//             .get();

//         if (querySnapshot.docs.isEmpty) {
//           Get.snackbar(
//             "Account Not Found",
//             "No account found with this phone number.",
//             backgroundColor: AppColors.red,
//             colorText: Colors.white,
//             snackPosition: SnackPosition.BOTTOM,
//           );
//           return;
//         }

//         emailToUse = querySnapshot.docs.first.data()['email'] as String?;

//         if (emailToUse == null || emailToUse.isEmpty) {
//           Get.snackbar(
//             "Error",
//             "Email not found for this phone number.",
//             backgroundColor: AppColors.red,
//             colorText: Colors.white,
//             snackPosition: SnackPosition.BOTTOM,
//           );
//           return;
//         }

//         debugPrint("✅ Found email: $emailToUse");
//       }

//       // Firebase Login
//       final userCredential = await FirebaseAuth.instance
//           .signInWithEmailAndPassword(
//             email: emailToUse,
//             password: passwordController.text.trim(),
//           );

//       final user = userCredential.user;

//       if (user == null) {
//         throw Exception("Login failed. Please try again.");
//       }

//       final userDoc = await FirebaseFirestore.instance
//           .collection('Customers')
//           .doc(user.uid)
//           .get();

//       if (!userDoc.exists) {
//         await FirebaseAuth.instance.signOut();
//         Get.snackbar(
//           "Access Denied",
//           "This account is not registered as a customer.",
//           backgroundColor: AppColors.red,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.BOTTOM,
//         );
//         return;
//       }

//       // SUCCESS
//       Get.offAll(() => HomePage());
//       debugPrint("🎉 Customer logged in successfully!");
//     } on FirebaseAuthException catch (e) {
//       String errorMessage;

//       switch (e.code) {
//         case 'user-not-found':
//           errorMessage = "No account found with this email.";
//           break;
//         case 'wrong-password':
//           errorMessage = "Incorrect password.";
//           break;
//         case 'invalid-email':
//           errorMessage = "Invalid email format.";
//           break;
//         case 'user-disabled':
//           errorMessage = "This account is disabled.";
//           break;
//         case 'too-many-requests':
//           errorMessage = "Too many attempts. Try again later.";
//           break;
//         case 'network-request-failed':
//           errorMessage = "Network error. Check your internet.";
//           break;
//         default:
//           errorMessage = "Login failed: ${e.message}";
//       }

//       Get.snackbar(
//         "Login Error",
//         errorMessage,
//         backgroundColor: AppColors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } catch (e) {
//       Get.snackbar(
//         "Error",
//         e.toString(),
//         backgroundColor: AppColors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } finally {
//       isLoading.value = false;
//       debugPrint("🟢 Login flow ended.");
//     }
//   }

//   @override
//   void onClose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.onClose();
//   }
// // }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:quickserve/core/constants/appColors.dart';
// import 'package:quickserve/views/CustomerHome/widgets/home_page.dart';

// class LoginController extends GetxController {
//   final isLoading = false.obs;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   @override
//   void onInit() {
//     super.onInit();
//     // If already signed in, navigate automatically
//     FirebaseAuth.instance.authStateChanges().listen((user) {
//       if (user != null) {
//         // already signed in -> go to Home
//         try {
//           // Prevent multiple navigations
//           if (!Get.isOverlaysOpen) {
//             Get.offAll(() => HomePage());
//           } else {
//             Get.offAll(() => HomePage());
//           }
//         } catch (_) {
//           Get.offAll(() => HomePage());
//         }
//       }
//     });
//   }

//   /// Sign in with Google and ensure customer document exists/updated
//   Future<void> signInWithGoogle() async {
//     isLoading.value = true;
//     try {
//       // 1) Trigger Google Sign-In
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) {
//         // User cancelled
//         return;
//       }

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       // 2) Create Firebase credential
//       final credential = GoogleAuthProvider.credential(
//         idToken: googleAuth.idToken,
//         accessToken: googleAuth.accessToken,
//       );

//       // 3) Sign in with Firebase
//       final userCredential = await FirebaseAuth.instance.signInWithCredential(
//         credential,
//       );

//       final User? firebaseUser = userCredential.user;
//       if (firebaseUser == null) throw Exception('Unable to sign in.');

//       // 4) Write / merge customer document
//       final userDocRef = FirebaseFirestore.instance
//           .collection('Customers')
//           .doc(firebaseUser.uid);

//       await userDocRef.set({
//         'uid': firebaseUser.uid,
//         'name': firebaseUser.displayName ?? '',
//         'email': firebaseUser.email ?? '',
//         'photo': firebaseUser.photoURL ?? '',
//         'lastLoginAt': FieldValue.serverTimestamp(),
//         'createdAt':
//             FieldValue.serverTimestamp(), // serverTimestamp will not overwrite if exists
//       }, SetOptions(merge: true));

//       // 5) Navigate to Home
//       Get.offAll(() => HomePage());
//     } on FirebaseAuthException catch (e) {
//       debugPrint('FirebaseAuthException: ${e.code} ${e.message}');
//       Get.snackbar(
//         'Login Error',
//         _firebaseAuthMessage(e),
//         backgroundColor: AppColors.red,
//         colorText: AppColors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } catch (e, st) {
//       debugPrint('SignIn error: $e\n$st');
//       Get.snackbar(
//         'Login Error',
//         e.toString(),
//         backgroundColor: AppColors.red,
//         colorText: AppColors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   String _firebaseAuthMessage(FirebaseAuthException e) {
//     switch (e.code) {
//       case 'account-exists-with-different-credential':
//         return 'Account exists with different credential.';
//       case 'invalid-credential':
//         return 'Invalid credential.';
//       case 'operation-not-allowed':
//         return 'Operation not allowed.';
//       case 'user-disabled':
//         return 'User disabled.';
//       default:
//         return e.message ?? 'Authentication failed.';
//     }
//   }

//   /// Sign out helper
//   Future<void> signOut() async {
//     try {
//       await _googleSignIn.signOut();
//     } catch (_) {}
//     try {
//       await FirebaseAuth.instance.signOut();
//     } catch (_) {}
//   }

//   @override
//   void onClose() {
//     // nothing to dispose
//     super.onClose();
//   }
// }

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:quickserve/views/CustomerHome/widgets/home_page.dart';

// class LoginController extends GetxController {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   RxBool isLoading = false.obs;

//   /// Google Sign-In
//   Future<void> signInWithGoogle() async {
//     try {
//       isLoading.value = true;

//       // 1️⃣ Start Google sign-in process
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//       if (googleUser == null) {
//         isLoading.value = false;
//         return; // user cancelled the login
//       }

//       // 2️⃣ Get authentication tokens
//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;

//       // 3️⃣ Create Firebase credential
//       final credential = GoogleAuthProvider.credential(
//         idToken: googleAuth.idToken,
//         accessToken: googleAuth.accessToken,
//       );

//       // 4️⃣ Sign in to Firebase
//       final userCredential = await _auth.signInWithCredential(credential);

//       final user = userCredential.user;

//       if (user != null) {
//         print("🔥 Logged In: ${user.displayName}");
//         print("📧 Email: ${user.email}");
//         print("🆔 UID: ${user.uid}");

//         // TODO: Navigate to your Home page here
//         Get.offAll(() => HomePage());
//       }

//       isLoading.value = false;
//     } catch (e) {
//       isLoading.value = false;
//       print("⚠️ Google Sign-In Error: $e");
//       Get.snackbar("Error", e.toString(), snackPosition: SnackPosition.BOTTOM);
//     }
//   }
// }

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:quickserve/core/constants/appColors.dart';
// import 'package:quickserve/views/CustomerHome/widgets/home_page.dart';

// class LoginController extends GetxController {
//   final isLoading = false.obs;
//   final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

//   @override
//   void onInit() {
//     super.onInit();
//   }

//   /// Sign in with Google and save customer data to Firestore
//   Future<void> signInWithGoogleCustomer() async {
//     if (isLoading.value) return;

//     isLoading.value = true;
//     try {
//       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//       if (googleUser == null) {
//         isLoading.value = false;
//         return; // User cancelled
//       }

//       final GoogleSignInAuthentication googleAuth =
//           await googleUser.authentication;
//       final credential = GoogleAuthProvider.credential(
//         idToken: googleAuth.idToken,
//         accessToken: googleAuth.accessToken,
//       );

//       final userCredential = await FirebaseAuth.instance.signInWithCredential(
//         credential,
//       );
//       final User? firebaseUser = userCredential.user;
//       if (firebaseUser == null) throw Exception('Unable to sign in.');

//       final userDocRef = FirebaseFirestore.instance
//           .collection('Customers')
//           .doc(firebaseUser.uid);
//       final userDoc = await userDocRef.get();
//       final bool isNewUser = !userDoc.exists;

//       // Only set phone/city if new user
//       final data = {
//         'uid': firebaseUser.uid,
//         'name': firebaseUser.displayName ?? '',
//         'email': firebaseUser.email ?? '',
//         'photo': firebaseUser.photoURL ?? '',
//         'lastLoginAt': FieldValue.serverTimestamp(),
//       };

//       if (isNewUser) {
//         data['phone'] = '';
//         data['city'] = '';
//         data['createdAt'] = FieldValue.serverTimestamp();
//       }

//       await userDocRef.set(data, SetOptions(merge: true));

//       debugPrint('✅ Customer data saved to Firestore');
//       debugPrint('👤 Name: ${firebaseUser.displayName}');
//       debugPrint('📧 Email: ${firebaseUser.email}');
//       debugPrint('🆔 UID: ${firebaseUser.uid}');

//       // Navigate only for customers
//       Get.offAll(() => HomePage());

//       Get.snackbar(
//         'Welcome!',
//         'Successfully signed in as ${firebaseUser.displayName}',
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//         duration: const Duration(seconds: 2),
//       );
//     } on FirebaseAuthException catch (e) {
//       debugPrint('FirebaseAuthException: ${e.code} ${e.message}');
//       Get.snackbar(
//         'Login Error',
//         _firebaseAuthMessage(e),
//         backgroundColor: AppColors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } catch (e, st) {
//       debugPrint('SignIn error: $e\n$st');
//       Get.snackbar(
//         'Login Error',
//         'An unexpected error occurred. Please try again.',
//         backgroundColor: AppColors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   String _firebaseAuthMessage(FirebaseAuthException e) {
//     switch (e.code) {
//       case 'account-exists-with-different-credential':
//         return 'Account exists with different credential.';
//       case 'invalid-credential':
//         return 'Invalid credential. Please try again.';
//       case 'operation-not-allowed':
//         return 'Operation not allowed. Contact support.';
//       case 'user-disabled':
//         return 'This account has been disabled.';
//       case 'user-not-found':
//         return 'No account found with this credential.';
//       case 'wrong-password':
//         return 'Incorrect password.';
//       case 'network-request-failed':
//         return 'Network error. Check your connection.';
//       default:
//         return e.message ?? 'Authentication failed. Please try again.';
//     }
//   }
// }
// // class LoginController extends GetxController {
// //   final isLoading = false.obs;
// //   final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

// //   @override
// //   void onInit() {
// //     super.onInit();
// //     // Auto navigate if already signed in
// //     FirebaseAuth.instance.authStateChanges().listen((user) {
// //       if (user != null) {
// //         Future.delayed(const Duration(milliseconds: 100), () {
// //           if (Get.currentRoute != '/HomePage') {
// //             Get.offAll(() => HomePage());
// //           }
// //         });
// //       }
// //     });
// //   }

// //   /// Sign in with Google and save customer data to Firestore
// //   Future<void> signInWithGoogleCustomer() async {
// //     if (isLoading.value) return;

// //     isLoading.value = true;
// //     try {
// //       final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
// //       if (googleUser == null) {
// //         isLoading.value = false;
// //         return; // User cancelled
// //       }

// //       final GoogleSignInAuthentication googleAuth =
// //           await googleUser.authentication;
// //       final credential = GoogleAuthProvider.credential(
// //         idToken: googleAuth.idToken,
// //         accessToken: googleAuth.accessToken,
// //       );

// //       final userCredential = await FirebaseAuth.instance.signInWithCredential(
// //         credential,
// //       );
// //       final User? firebaseUser = userCredential.user;
// //       if (firebaseUser == null) throw Exception('Unable to sign in.');

// //       final userDocRef = FirebaseFirestore.instance
// //           .collection('Customers')
// //           .doc(firebaseUser.uid);
// //       final userDoc = await userDocRef.get();
// //       final bool isNewUser = !userDoc.exists;

// //       // Only set phone/city if new user
// //       final data = {
// //         'uid': firebaseUser.uid,
// //         'name': firebaseUser.displayName ?? '',
// //         'email': firebaseUser.email ?? '',
// //         'photo': firebaseUser.photoURL ?? '',
// //         'lastLoginAt': FieldValue.serverTimestamp(),
// //       };

// //       if (isNewUser) {
// //         data['phone'] = '';
// //         data['city'] = '';
// //         data['createdAt'] = FieldValue.serverTimestamp();
// //       }

// //       await userDocRef.set(data, SetOptions(merge: true));

// //       debugPrint('✅ Customer data saved to Firestore');
// //       debugPrint('👤 Name: ${firebaseUser.displayName}');
// //       debugPrint('📧 Email: ${firebaseUser.email}');
// //       debugPrint('🆔 UID: ${firebaseUser.uid}');

// //       Get.offAll(() => HomePage());

// //       Get.snackbar(
// //         'Welcome!',
// //         'Successfully signed in as ${firebaseUser.displayName}',
// //         backgroundColor: Colors.green,
// //         colorText: Colors.white,
// //         snackPosition: SnackPosition.BOTTOM,
// //         duration: const Duration(seconds: 2),
// //       );
// //     } on FirebaseAuthException catch (e) {
// //       debugPrint('FirebaseAuthException: ${e.code} ${e.message}');
// //       Get.snackbar(
// //         'Login Error',
// //         _firebaseAuthMessage(e),
// //         backgroundColor: AppColors.red,
// //         colorText: Colors.white,
// //         snackPosition: SnackPosition.BOTTOM,
// //       );
// //     } catch (e, st) {
// //       debugPrint('SignIn error: $e\n$st');
// //       Get.snackbar(
// //         'Login Error',
// //         'An unexpected error occurred. Please try again.',
// //         backgroundColor: AppColors.red,
// //         colorText: Colors.white,
// //         snackPosition: SnackPosition.BOTTOM,
// //       );
// //     } finally {
// //       isLoading.value = false;
// //     }
// //   }

// //   String _firebaseAuthMessage(FirebaseAuthException e) {
// //     switch (e.code) {
// //       case 'account-exists-with-different-credential':
// //         return 'Account exists with different credential.';
// //       case 'invalid-credential':
// //         return 'Invalid credential. Please try again.';
// //       case 'operation-not-allowed':
// //         return 'Operation not allowed. Contact support.';
// //       case 'user-disabled':
// //         return 'This account has been disabled.';
// //       case 'user-not-found':
// //         return 'No account found with this credential.';
// //       case 'wrong-password':
// //         return 'Incorrect password.';
// //       case 'network-request-failed':
// //         return 'Network error. Check your connection.';
// //       default:
// //         return e.message ?? 'Authentication failed. Please try again.';
// //     }
// //   }
// // }

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/views/CustomerHome/widgets/home_page.dart';
import 'package:quickserve/views/Auth/AuthService/auth_service.dart';

class LoginController extends GetxController {
  final isLoading = false.obs;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  TextEditingController? get phoneController => null;

  @override
  void onInit() {
    super.onInit();
    _printGoogleSignInConfiguration();
  }

  /// Print Google Sign-In configuration details
  void _printGoogleSignInConfiguration() {
    debugPrint("🔧 ========================================");
    debugPrint("🔧 CUSTOMER GOOGLE SIGN-IN CONFIGURATION");
    debugPrint("🔧 Using GoogleSignIn.instance (v7.2.0)");
    debugPrint("🔧 ========================================");
  }

  /// Sign in with Google and save customer data to Firestore
  Future<void> signInWithGoogleCustomer() async {
    if (isLoading.value) {
      debugPrint("⚠️ Already signing in, ignoring duplicate tap");
      return;
    }

    try {
      isLoading.value = true;
      final timestamp = DateTime.now().toIso8601String();

      debugPrint("");
      debugPrint("🔵 ╔════════════════════════════════════════╗");
      debugPrint("🔵 ║  CUSTOMER GOOGLE SIGN-IN STARTED       ║");
      debugPrint("🔵 ╚════════════════════════════════════════╝");
      debugPrint(
        "🔵 Build Mode: ${const bool.fromEnvironment('dart.vm.product') ? '🔴 RELEASE' : '🟢 DEBUG'}",
      );
      debugPrint("🔵 Timestamp: $timestamp");
      debugPrint("");

      // ═══════════════════════════════════════════════════════════
      // STEP 1: Initialize Google Sign-In
      // ═══════════════════════════════════════════════════════════
      debugPrint("📍 STEP 1/9: Initializing Google Sign-In...");
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
      debugPrint("📍 STEP 2/9: Clearing previous session...");
      try {
        await _googleSignIn.signOut();
        await FirebaseAuth.instance.signOut();
        debugPrint("   ✓ Previous session cleared");
      } catch (e) {
        debugPrint("   ⚪ No previous session: $e");
      }

      // ═══════════════════════════════════════════════════════════
      // STEP 3: Check platform support
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 3/9: Checking platform support...");
      if (!_googleSignIn.supportsAuthenticate()) {
        debugPrint("   ❌ Platform does not support authenticate");
        Get.snackbar(
          'Platform Not Supported',
          'Google Sign-In is not supported on this platform',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }
      debugPrint("   ✓ Platform supports authenticate");

      // ═══════════════════════════════════════════════════════════
      // STEP 4: Set up authentication event listener
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 4/9: Setting up authentication listener...");

      final Completer<GoogleSignInAccount?> completer =
          Completer<GoogleSignInAccount?>();
      late StreamSubscription<GoogleSignInAuthenticationEvent> subscription;

      subscription = _googleSignIn.authenticationEvents.listen(
        (event) {
          debugPrint("   📨 Event: ${event.runtimeType}");

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
        },
        onError: (error) {
          debugPrint("   ❌ Event error: $error");
          if (!completer.isCompleted) {
            subscription.cancel();
            completer.completeError(error);
          }
        },
      );

      debugPrint("   ✓ Listener configured");

      // ═══════════════════════════════════════════════════════════
      // STEP 5: Trigger authentication
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 5/9: Opening Google Sign-In dialog...");

      try {
        await _googleSignIn.authenticate();
        debugPrint("   ✓ Authenticate called");
      } catch (authError) {
        debugPrint("");
        debugPrint("❌ ╔════════════════════════════════════════╗");
        debugPrint("❌ ║  AUTHENTICATION FAILED                 ║");
        debugPrint("❌ ╚════════════════════════════════════════╝");
        debugPrint("❌ Error: $authError");
        debugPrint("");

        subscription.cancel();

        Get.snackbar(
          'Sign-In Failed',
          'Could not start Google Sign-In. Check SHA keys.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      // ═══════════════════════════════════════════════════════════
      // STEP 6: Wait for user selection
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 6/9: Waiting for user selection...");

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await completer.future.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            debugPrint("   ⏱️ Timeout");
            subscription.cancel();
            return null;
          },
        );
      } catch (e) {
        debugPrint("   ❌ Error: $e");
        subscription.cancel();
        return;
      }

      if (googleUser == null) {
        debugPrint("");
        debugPrint("⚠️ ╔════════════════════════════════════════╗");
        debugPrint("⚠️ ║  USER CANCELLED                        ║");
        debugPrint("⚠️ ╚════════════════════════════════════════╝");
        debugPrint("");
        return;
      }

      debugPrint("");
      debugPrint("✅ ╔════════════════════════════════════════╗");
      debugPrint("✅ ║  GOOGLE ACCOUNT SELECTED               ║");
      debugPrint("✅ ╚════════════════════════════════════════╝");
      debugPrint("✅ Email: ${googleUser.email}");
      debugPrint("✅ Name: ${googleUser.displayName ?? '(No name)'}");
      debugPrint("✅ ID: ${googleUser.id}");
      debugPrint("");

      // ═══════════════════════════════════════════════════════════
      // STEP 7: Get tokens and sign in to Firebase
      // ═══════════════════════════════════════════════════════════
      debugPrint("📍 STEP 7/9: Getting tokens and signing into Firebase...");

      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = googleUser.authentication;
        debugPrint("   ✓ Tokens retrieved");

        if (googleAuth.idToken == null) {
          throw Exception("ID Token is NULL");
        }
      } catch (tokenError) {
        debugPrint("   ❌ Token error: $tokenError");
        Get.snackbar(
          'Token Error',
          'Failed to get authentication tokens.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        debugPrint("   ✓ Firebase authentication successful");
      } on FirebaseAuthException catch (e) {
        debugPrint("   ❌ Firebase error: ${e.code} - ${e.message}");
        Get.snackbar(
          'Firebase Error',
          _firebaseAuthMessage(e),
          backgroundColor: AppColors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase user is NULL');
      }

      debugPrint("");
      debugPrint("✅ ╔════════════════════════════════════════╗");
      debugPrint("✅ ║  FIREBASE USER AUTHENTICATED           ║");
      debugPrint("✅ ╚════════════════════════════════════════╝");
      debugPrint("✅ UID: ${firebaseUser.uid}");
      debugPrint("✅ Email: ${firebaseUser.email}");
      debugPrint("");

      // ═══════════════════════════════════════════════════════════
      // STEP 8: Check for conflicts
      // ═══════════════════════════════════════════════════════════
      debugPrint("📍 STEP 8/9: Checking for account conflicts...");

      final providerDoc = await FirebaseFirestore.instance
          .collection('ServiceProviders')
          .doc(firebaseUser.uid)
          .get();

      if (providerDoc.exists) {
        debugPrint("");
        debugPrint("⚠️ ╔════════════════════════════════════════╗");
        debugPrint("⚠️ ║  ACCOUNT CONFLICT                      ║");
        debugPrint("⚠️ ╚════════════════════════════════════════╝");
        debugPrint("");

        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();

        Get.snackbar(
          'Account Conflict',
          'This account is registered as Service Provider. Use a different account.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
        return;
      }

      debugPrint("   ✓ No conflicts detected");

      // ═══════════════════════════════════════════════════════════
      // STEP 9: Save customer data
      // ═══════════════════════════════════════════════════════════
      debugPrint("");
      debugPrint("📍 STEP 9/9: Saving customer data...");

      final userDocRef = FirebaseFirestore.instance
          .collection('Customers')
          .doc(firebaseUser.uid);

      final userDoc = await userDocRef.get();
      final bool isNewUser = !userDoc.exists;

      debugPrint("   └─ User: ${isNewUser ? 'NEW' : 'EXISTING'}");

      final data = {
        'uid': firebaseUser.uid,
        'name': firebaseUser.displayName ?? '',
        'email': firebaseUser.email ?? '',
        'photo': firebaseUser.photoURL ?? '',
        'role': 'Customer',
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      if (isNewUser) {
        data['phone'] = '';
        data['city'] = '';
        data['createdAt'] = FieldValue.serverTimestamp();
      }

      await userDocRef.set(data, SetOptions(merge: true));
      debugPrint("   ✓ Customer data saved");

      await Future.delayed(const Duration(milliseconds: 500));

      await AuthService.saveRole('customer');
      Get.offAll(() => HomePage());

      Get.snackbar(
        'Welcome!',
        'Successfully signed in as ${firebaseUser.displayName}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      debugPrint("");
      debugPrint("🟢 ╔════════════════════════════════════════╗");
      debugPrint("🟢 ║  CUSTOMER SIGN-IN COMPLETE             ║");
      debugPrint("🟢 ╚════════════════════════════════════════╝");
      debugPrint("");
    } on FirebaseAuthException catch (e) {
      debugPrint("");
      debugPrint("❌ FIREBASE AUTH EXCEPTION: ${e.code} - ${e.message}");
      debugPrint("");

      Get.snackbar(
        'Login Error',
        _firebaseAuthMessage(e),
        backgroundColor: AppColors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e, stackTrace) {
      debugPrint("");
      debugPrint("❌ UNEXPECTED ERROR: $e");
      debugPrint("$stackTrace");
      debugPrint("");

      Get.snackbar(
        'Login Error',
        'Sign-in failed: ${e.toString()}',
        backgroundColor: AppColors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
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
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  /// Sign out the customer
  Future<void> signOutCustomer() async {
    try {
      debugPrint("🔵 Signing out customer...");
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      debugPrint("✅ Customer signed out successfully");
    } catch (e) {
      debugPrint("❌ Error signing out customer: $e");
    }
  }

  void loginWithPhoneNoOtp(BuildContext context) {}
}
