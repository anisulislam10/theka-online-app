import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/services/vt_otp_service.dart';
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

  // Toggle between phone and email login
  Future<void> loginAsGuest() async {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 24.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            
            Text(
              'continue_as_guest'.tr,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'choose_registration_method'.tr,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.h),

            // Customer Option Card
            _buildGuestOption(
              title: 'customer'.tr,
              icon: Icons.person_outline_rounded,
              color: AppColors.primary,
              onTap: () async {
                Get.back();
                try {
                  isLoading.value = true;
                  await AuthService.saveRole('guest');
                  Get.offAll(() => HomePage());
                } finally {
                  isLoading.value = false;
                }
              },
            ),
            
            SizedBox(height: 16.h),

            // Provider Option Card
            _buildGuestOption(
              title: 'service_provider'.tr,
              icon: Icons.handyman_outlined,
              color: AppColors.secondary,
              onTap: () async {
                Get.back();
                try {
                  isLoading.value = true;
                  await AuthService.saveRole('guest_provider');
                  Get.offAll(() => BottomNavbar());
                } finally {
                  isLoading.value = false;
                }
              },
            ),
            
            SizedBox(height: 24.h),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildGuestOption({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: color, size: 28.sp),
            ),
            SizedBox(width: 18.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey[300], size: 18.sp),
          ],
        ),
      ),
    );
  }

  void toggleLoginMethod() {
    isPhoneLogin.value = !isPhoneLogin.value;
    showOtpSection.value = false;
    emailController.clear();
    phoneController.clear();
    passwordController.clear();
    otpController.clear();
    formKey.currentState?.reset();
    debugPrint("🔄 Switched to ${isPhoneLogin.value ? 'Phone' : 'Email'} login");
  }

  // ==================== PHONE LOGIN WITH VT OTP ====================
  Future<void> loginWithPhone(BuildContext context) async {
    debugPrint("==================== PHONE LOGIN STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      String formattedPhone = "+92${phoneController.text.trim()}";
      debugPrint("📱 Checking registration for: $formattedPhone");

      // Check if user is registered in either collection
      bool isRegistered = await _checkIfPhoneRegistered(formattedPhone);
      if (!isRegistered) {
        isLoading.value = false;
        _showSnackbar("Error", "No account is registered with this phone number.", isError: true);
        return;
      }

      debugPrint("✅ User registered. Proceeding to direct login...");
      await _signInWithDummyCredentials(context);
      
    } catch (e) {
      debugPrint("❌ Error in loginWithPhone: ${e.toString()}");
      _showSnackbar("Error", "Login failed. Please try again.", isError: true);
    } finally {
      isLoading.value = false;
    }

    debugPrint("==================== PHONE LOGIN ENDED ====================\n");
  }


  /// Signs in using the dummy email/password pattern (keeps existing Firebase auth session).
  Future<void> _signInWithDummyCredentials(BuildContext context) async {
    String rawPhone = phoneController.text.trim();
    String dummyEmail = "user_$rawPhone@thekaonline.pk";
    String dummyPassword = "pw_${rawPhone}_stable";

    try {
      UserCredential? userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: dummyEmail,
          password: dummyPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
          // Dummy password might have been changed, or account doesn't exist yet
          try {
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: dummyEmail,
              password: dummyPassword,
            );
          } on FirebaseAuthException catch (createError) {
            if (createError.code == 'email-already-in-use') {
              // Account exists but dummy password was changed (old registration bug).
              // Try to recover: ask the user for their password.
              debugPrint("⚠️ Dummy password mismatch. Prompting user for real password...");
              if (context.mounted) {
                await _recoverWithRealPassword(context, dummyEmail, dummyPassword, rawPhone);
              }
              return;
            } else {
              rethrow;
            }
          }
        } else {
          rethrow;
        }
      }

      final user = userCredential.user;
      if (user == null) throw Exception("Authentication failed");

      debugPrint("✅ Firebase sign-in successful. UID: ${user.uid}");
      await _ensureUserDocumentExists(user.uid, "+92$rawPhone");
      await _checkUserTypeAndNavigate(user.uid);

    } on FirebaseAuthException catch (e) {
      debugPrint("❌ FirebaseAuthException: ${e.code}");
      _showSnackbar("Error", "Authentication failed: ${e.message}", isError: true);
    }
  }

  /// Recovery flow when the dummy password was overwritten by old registration code.
  /// Prompts the user for their real password, verifies it, signs in, and resets to dummy.
  Future<void> _recoverWithRealPassword(
    BuildContext context, String dummyEmail, String dummyPassword, String rawPhone,
  ) async {
    final passwordInput = TextEditingController();
    final formattedPhone = "+92$rawPhone";

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Password Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "For security, please enter the password you set during registration to continue.",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordInput,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Enter your password",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Continue", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || passwordInput.text.trim().isEmpty) {
      isLoading.value = false;
      return;
    }

    final enteredPassword = passwordInput.text.trim();

    // Verify password hash against Firestore
    final bytes = utf8.encode(enteredPassword);
    final digest = sha256.convert(bytes);
    final enteredHash = digest.toString();

    // Look up the user document
    String? storedHash;
    String? uid;
    final spQuery = await FirebaseFirestore.instance
        .collection('ServiceProviders')
        .where('phone', isEqualTo: formattedPhone)
        .limit(1)
        .get();
    if (spQuery.docs.isNotEmpty) {
      final data = spQuery.docs.first.data();
      storedHash = data['passwordHash'] as String?;
    }
    if (storedHash == null) {
      final cQuery = await FirebaseFirestore.instance
          .collection('Customers')
          .where('phone', isEqualTo: formattedPhone)
          .limit(1)
          .get();
      if (cQuery.docs.isNotEmpty) {
        final data = cQuery.docs.first.data();
        storedHash = data['passwordHash'] as String?;
      }
    }

    if (storedHash == null || storedHash != enteredHash) {
      _showSnackbar("Incorrect Password", "The password you entered does not match our records.", isError: true);
      isLoading.value = false;
      return;
    }

    // Password verified! Sign in with the real password, then reset to dummy.
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: dummyEmail,
        password: enteredPassword,
      );
      final user = userCredential.user;
      if (user == null) throw Exception("Authentication failed");

      // Reset the Firebase Auth password back to dummy so future phone logins work
      await user.updatePassword(dummyPassword);
      debugPrint("✅ Password recovered and reset to dummy for consistency");

      await _ensureUserDocumentExists(user.uid, formattedPhone);
      await _checkUserTypeAndNavigate(user.uid);
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Recovery sign-in failed: ${e.code}");
      _showSnackbar("Login Failed", "Could not sign in. Please try email login instead.", isError: true);
    }
  }

  // ==================== EMAIL LOGIN WITH PASSWORD ====================
  Future<void> loginWithEmail(BuildContext context) async {
    debugPrint("==================== EMAIL LOGIN STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      String enteredEmail = emailController.text.trim();
      String enteredPassword = passwordController.text.trim();
      debugPrint("⏳ Attempting custom email login for: $enteredEmail");

      // 1. Hash the entered password 
      final bytes = utf8.encode(enteredPassword);
      final digest = sha256.convert(bytes);
      final enteredPasswordHash = digest.toString();

      // 2. Query Firestore for the user 
      QuerySnapshot customerQuery = await FirebaseFirestore.instance
          .collection('Customers')
          .where('email', isEqualTo: enteredEmail)
          .limit(1)
          .get();

      DocumentSnapshot? userDoc;
      if (customerQuery.docs.isNotEmpty) {
        userDoc = customerQuery.docs.first;
      } else {
        // Try Service Providers
        QuerySnapshot providerQuery = await FirebaseFirestore.instance
            .collection('ServiceProviders')
            .where('email', isEqualTo: enteredEmail)
            .limit(1)
            .get();
        if (providerQuery.docs.isNotEmpty) {
          userDoc = providerQuery.docs.first;
        }
      }

      // 3. Check if user exists
      if (userDoc == null || !userDoc.exists) {
        _showSnackbar("Login Failed", "Wrong email or password.", isError: true);
        return;
      }

      // 4. Verify password hash
      final data = userDoc.data() as Map<String, dynamic>;
      final storedHash = data['passwordHash'] as String?;
      
      if (storedHash == null || storedHash != enteredPasswordHash) {
        _showSnackbar("Login Failed", "Wrong email or password.", isError: true);
        return;
      }

      // 5. User authenticated! Sign into Firebase using their dummy phone credentials
      String rawPhone = (data['phone'] as String).replaceAll('+92', '');
      String dummyEmail = "user_$rawPhone@thekaonline.pk";
      String dummyPassword = "pw_${rawPhone}_stable";

      debugPrint("✅ Password verified! Signing into dummy Firebase account: $dummyEmail");
      
      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: dummyEmail,
          password: dummyPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'wrong-password') {
           // Dummy password may have been changed by old registration code.
           // Try the user's actual entered password as fallback.
           try {
             userCredential = await _auth.signInWithEmailAndPassword(
               email: dummyEmail,
               password: enteredPassword,
             );
             // Success! Reset password back to dummy for future phone logins
             await userCredential.user?.updatePassword(dummyPassword);
             debugPrint("✅ Password recovered and reset to dummy for consistency");
           } on FirebaseAuthException catch (_) {
             // If that also fails, try creating the account
             try {
               userCredential = await _auth.createUserWithEmailAndPassword(
                 email: dummyEmail,
                 password: dummyPassword,
               );
             } on FirebaseAuthException catch (createError) {
               if (createError.code == 'email-already-in-use') {
                 _showSnackbar("Login Failed", "Could not authenticate. Please contact support.", isError: true);
                 return;
               } else {
                 rethrow;
               }
             }
           }
        } else {
           rethrow;
        }
      }

      final user = userCredential.user;
      if (user == null) throw Exception("Dummy Firebase Login failed");

      // 6. Complete login process
      debugPrint("✅ Firebase sign-in successful. UID: ${user.uid}");
      await _ensureUserDocumentExists(user.uid, data['phone']);
      await _checkUserTypeAndNavigate(user.uid);

    } catch (e) {
      debugPrint("❌ Error in loginWithEmail: ${e.toString()}");
      _showSnackbar("Error", e.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }

    debugPrint("==================== EMAIL LOGIN ENDED ====================\n");
  }


  // ==================== FACEBOOK LOGIN ====================
  Future<void> signInWithFacebook(BuildContext context) async {
    debugPrint("==================== FACEBOOK SIGN-IN STARTED ====================");

    if (isLoading.value) return;

    try {
      isLoading.value = true;

      // 1. Trigger Facebook Login
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
      );

      if (result.status == LoginStatus.success) {
        debugPrint("✅ Facebook Login success. Token: ${result.accessToken?.tokenString.substring(0, 10)}...");

        // 2. Create a credential from the access token
        final OAuthCredential credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);

        // 3. Sign in to Firebase with the credential
        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        if (user == null) throw Exception("Firebase Facebook Sign-In failed");

        debugPrint("✅ Firebase Facebook Sign-In successful. UID: ${user.uid}");

        // 4. Check if user exists in Firestore
        final customerDoc = await FirebaseFirestore.instance.collection('Customers').doc(user.uid).get();
        final providerDoc = await FirebaseFirestore.instance.collection('ServiceProviders').doc(user.uid).get();

        if (customerDoc.exists) {
          debugPrint("✅ User is existing Customer");
          await AuthService.saveRole('customer');
          Get.offAll(() => HomePage());
        } else if (providerDoc.exists) {
          debugPrint("✅ User is existing Service Provider");
          await AuthService.saveRole('ServiceProvider');
          Get.offAll(() => BottomNavbar());
        } else {
          // 5. New user: Ask for role
          debugPrint("❓ New user detected. Showing role selection...");
          _showRoleSelectionDialog(context, user);
        }
      } else if (result.status == LoginStatus.cancelled) {
        debugPrint("⚪ Facebook Login cancelled by user");
      } else {
        debugPrint("❌ Facebook Login failed: ${result.message}");
        _showSnackbar("Error", result.message ?? "Facebook Login failed", isError: true);
      }
    } catch (e) {
      debugPrint("❌ Error in signInWithFacebook: ${e.toString()}");
      _showSnackbar("Error", "Facebook Login failed. Please try again.", isError: true);
    } finally {
      isLoading.value = false;
    }

    debugPrint("==================== FACEBOOK SIGN-IN ENDED ====================\n");
  }

  void _showRoleSelectionDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Complete Registration"),
        content: const Text("How would you like to use Theka Online?"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _registerFacebookUserAsCustomer(user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("As Customer", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // For provider, we need to collect docs. Navigate to documents page.
              _navigateFacebookProviderToDocs(user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            child: const Text("As Provider", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _registerFacebookUserAsCustomer(User user) async {
    try {
      isLoading.value = true;
      debugPrint("🚀 Registering new Facebook user as Customer...");

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
      _showSnackbar("Welcome!", "Your account has been created.");
    } catch (e) {
      debugPrint("❌ Error registering customer: $e");
      _showSnackbar("Error", "Failed to complete registration.", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateFacebookProviderToDocs(User user) {
    debugPrint("🚀 Navigating Facebook Provider to DocumentsUploadPage...");
    
    // We navigate to the Service Provider Registration's Documents page
    // We need to pass the basic info we already have from Facebook
    Get.toNamed('/ServiceProviderDocs', arguments: {
      'name': user.displayName ?? "",
      'email': user.email ?? "",
      'photoUrl': user.photoURL ?? "",
      'isSocialLogin': true,
    });
  }

  // ==================== HELPERS ====================
  void _showSnackbar(String title, String message, {bool isError = false}) {
    final context = Get.context;
    if (context != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "$title: $message",
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: isError ? AppColors.red : AppColors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<bool> _checkIfPhoneRegistered(String phone) async {
    try {
      final customerQuery = await FirebaseFirestore.instance
          .collection('Customers')
          .where('phone', isEqualTo: phone)
          .get();
      if (customerQuery.docs.isNotEmpty) return true;

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
        title: const Text("Error",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK",
                style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _ensureUserDocumentExists(String uid, String phoneNumber) async {
    debugPrint("🔍 Ensuring Firestore document exists for UID: $uid (Phone: $phoneNumber)");

    try {
      DocumentSnapshot customerDoc =
          await FirebaseFirestore.instance.collection('Customers').doc(uid).get();
      DocumentSnapshot providerDoc =
          await FirebaseFirestore.instance.collection('ServiceProviders').doc(uid).get();

      bool exists = customerDoc.exists || providerDoc.exists;
      Map<String, dynamic>? currentData =
          (customerDoc.exists ? customerDoc.data() : providerDoc.data()) as Map<String, dynamic>?;

      List<String> migratedFromList = [];
      if (currentData != null && currentData['migratedFromList'] != null) {
        migratedFromList = List<String>.from(currentData['migratedFromList']);
      } else if (currentData != null && currentData['migratedFrom'] != null) {
        migratedFromList.add(currentData['migratedFrom']);
      }

      String raw = phoneNumber.replaceAll(RegExp(r'\D'), '');
      List<String> phoneVariations = [phoneNumber];
      if (raw.startsWith('92') && raw.length == 12) {
        phoneVariations.add('0${raw.substring(2)}');
      } else if (raw.startsWith('0') && raw.length == 11) {
        phoneVariations.add('+92${raw.substring(1)}');
      }

      Set<String> oldUids = {};
      for (String variant in phoneVariations) {
        final cQuery = await FirebaseFirestore.instance
            .collection('Customers')
            .where('phone', isEqualTo: variant)
            .get();
        for (var doc in cQuery.docs) if (doc.id != uid) oldUids.add(doc.id);

        final pQuery = await FirebaseFirestore.instance
            .collection('ServiceProviders')
            .where('phone', isEqualTo: variant)
            .get();
        for (var doc in pQuery.docs) if (doc.id != uid) oldUids.add(doc.id);
      }

      List<String> toMigrate = oldUids.where((id) => !migratedFromList.contains(id)).toList();

      if (toMigrate.isEmpty) {
        if (exists && currentData?['lastMigrationCheck'] == null) {
          await _markAsMigrated(uid, migratedFromList);
        }
        return;
      }

      for (String oldUid in toMigrate) {
        await _cloneMainDocumentsIfNeeded(oldUid, uid);
        await _migrateRequestsRecursive(oldUid, uid);
        await _updateHistoricalRecords(oldUid, uid);
        migratedFromList.add(oldUid);
      }

      await _markAsMigrated(uid, migratedFromList);
    } catch (e) {
      debugPrint("❌ Error during deep migration: ${e.toString()}");
    }
  }

  Future<void> _cloneMainDocumentsIfNeeded(String oldUid, String newUid) async {
    final collections = ['Customers', 'ServiceProviders'];
    for (String col in collections) {
      final oldDoc =
          await FirebaseFirestore.instance.collection(col).doc(oldUid).get();
      if (oldDoc.exists) {
        final newDoc =
            await FirebaseFirestore.instance.collection(col).doc(newUid).get();
        if (!newDoc.exists) {
          Map<String, dynamic> data = Map.from(oldDoc.data()!);
          data['uid'] = newUid;
          data['migratedFrom'] = oldUid;
          data['migrationComplete'] = true;
          await FirebaseFirestore.instance.collection(col).doc(newUid).set(data);
        }
      }
    }
  }

  Future<void> _migrateRequestsRecursive(String oldUid, String newUid) async {
    final subs = ['Now', 'AnyTime', 'now', 'anytime'];
    for (String sub in subs) {
      final snapshot = await FirebaseFirestore.instance
          .collection('Requests')
          .doc(oldUid)
          .collection(sub)
          .get();
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data();
          data['userId'] = newUid;
          await FirebaseFirestore.instance
              .collection('Requests')
              .doc(newUid)
              .collection(sub)
              .doc(doc.id)
              .set(data);
        }
      }
    }
  }

  Future<void> _updateHistoricalRecords(String oldUid, String newUid) async {
    final fields = ['userId', 'providerId'];
    for (String field in fields) {
      final snapshot = await FirebaseFirestore.instance
          .collection('completedRequests')
          .where(field, isEqualTo: oldUid)
          .get();
      if (snapshot.docs.isNotEmpty) {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.update(doc.reference, {field: newUid});
        }
        await batch.commit();
      }
    }
  }

  Future<void> _markAsMigrated(String uid, List<String> migratedFromList) async {
    try {
      final updateData = {
        'migrationComplete': true,
        'migratedFromList': migratedFromList,
        'lastMigrationCheck': FieldValue.serverTimestamp(),
      };

      final customerRef =
          FirebaseFirestore.instance.collection('Customers').doc(uid);
      final providerRef =
          FirebaseFirestore.instance.collection('ServiceProviders').doc(uid);

      final cDoc = await customerRef.get();
      if (cDoc.exists) await customerRef.update(updateData);

      final pDoc = await providerRef.get();
      if (pDoc.exists) await providerRef.update(updateData);
    } catch (e) {
      debugPrint("⚠️ Failed to mark as migrated: $e");
    }
  }

  // ==================== CHECK USER TYPE AND NAVIGATE ====================
  Future<void> _checkUserTypeAndNavigate(String uid) async {
    debugPrint("🔍 Checking user type for UID: $uid");

    try {
      final customerDoc = await FirebaseFirestore.instance
          .collection('Customers')
          .doc(uid)
          .get();

      if (customerDoc.exists) {
        debugPrint("✅ User is a Customer");
        await AuthService.saveRole('customer');
        Get.offAll(() => HomePage());
        _showSnackbar("Welcome Back", "You have successfully logged in as a customer.");
        return;
      }

      final providerDoc = await FirebaseFirestore.instance
          .collection('ServiceProviders')
          .doc(uid)
          .get();

      if (providerDoc.exists) {
        debugPrint("✅ User is a Service Provider");
        await AuthService.saveRole('ServiceProvider');
        Get.offAll(() => BottomNavbar());
        _showSnackbar("Welcome Back", "You have successfully logged in as a provider.");
        return;
      }

      debugPrint("❌ User not found in any collection");
      await _auth.signOut();
      _showSnackbar("Account Error", "User data not found in our records.", isError: true);
    } catch (e) {
      debugPrint("❌ Error checking user type: ${e.toString()}");
      await _auth.signOut();
      _showSnackbar("Authentication Failed", "We couldn't verify your account type.", isError: true);
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