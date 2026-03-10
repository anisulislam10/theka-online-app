import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  Future<void> sendLoginOtp(BuildContext context) async {
    debugPrint("==================== SEND LOGIN OTP STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      String formattedPhone = "+92${phoneController.text.trim()}";
      debugPrint("📱 Checking registration for: $formattedPhone");

      // Check if user is registered in either collection
      bool isRegistered = await _checkIfPhoneRegistered(formattedPhone);
      if (!isRegistered) {
        isLoading.value = false;
        if (context.mounted) _showNotRegisteredDialog(context, "not_registered_error".tr);
        return;
      }

      debugPrint("📤 Sending OTP via VeevoTech to: $formattedPhone");
      final result = await VtOtpService.instance.sendOtp(formattedPhone);

      if (result.isSuccess) {
        showOtpSection.value = true;
        _showSnackbar("Success", "OTP sent to $formattedPhone");
      } else {
        _showSnackbar("Error", result.errorMessage ?? "Failed to send OTP", isError: true);
      }
    } catch (e) {
      debugPrint("❌ Error in sendLoginOtp: ${e.toString()}");
      _showSnackbar("Error", "Failed to send OTP", isError: true);
    } finally {
      isLoading.value = false;
    }

    debugPrint("==================== SEND LOGIN OTP ENDED ====================\n");
  }

  Future<void> verifyOtpAndLogin(BuildContext context) async {
    debugPrint("==================== VERIFY OTP AND LOGIN STARTED ====================");

    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      _showSnackbar("Error", "Please enter the OTP", isError: true);
      return;
    }

    try {
      isLoading.value = true;
      String formattedPhone = "+92${phoneController.text.trim()}";

      final verifyResult = VtOtpService.instance.verifyOtp(formattedPhone, otp);

      switch (verifyResult) {
        case VtOtpVerifyResult.valid:
          debugPrint("✅ OTP verified. Signing in...");
          await _signInWithDummyCredentials(context);
          break;
        case VtOtpVerifyResult.invalid:
          _showSnackbar("Error", "Invalid OTP. Please check and try again.", isError: true);
          break;
        case VtOtpVerifyResult.expired:
          showOtpSection.value = false;
          otpController.clear();
          _showSnackbar("Error", "OTP expired. Please request a new one.", isError: true);
          break;
        case VtOtpVerifyResult.notFound:
          _showSnackbar("Error", "No OTP found. Please send OTP first.", isError: true);
          break;
      }
    } catch (e) {
      debugPrint("❌ Error in verifyOtpAndLogin: ${e.toString()}");
      _showSnackbar("Error", "Login failed. Please try again.", isError: true);
    } finally {
      isLoading.value = false;
    }

    debugPrint("==================== VERIFY OTP AND LOGIN ENDED ====================\n");
  }

  Future<void> resendLoginOtp(BuildContext context) async {
    debugPrint("🔄 Resending login OTP...");
    otpController.clear();
    showOtpSection.value = false;
    await sendLoginOtp(context);
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
          userCredential = await _auth.createUserWithEmailAndPassword(
            email: dummyEmail,
            password: dummyPassword,
          );
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

  // ==================== EMAIL LOGIN WITH PASSWORD ====================
  Future<void> loginWithEmail(BuildContext context) async {
    debugPrint("==================== EMAIL LOGIN STARTED ====================");

    if (formKey.currentState == null || !formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;
      debugPrint("⏳ Attempting email login for: ${emailController.text.trim()}");

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) throw Exception("Login failed");

      debugPrint("✅ Email login successful. UID: ${user.uid}");
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

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("error_title".tr,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            content: Text(errorMessage),
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
    } catch (e) {
      debugPrint("❌ Error: ${e.toString()}");
      _showSnackbar("error_title".tr, e.toString(), isError: true);
    } finally {
      isLoading.value = false;
    }

    debugPrint("==================== EMAIL LOGIN ENDED ====================\n");
  }

  // ==================== HELPERS ====================
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
        title: Text("error_title".tr,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
        _showSnackbar("welcome_back".tr, "login_subtitle".tr);
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
        _showSnackbar("welcome_back".tr, "login_subtitle".tr);
        return;
      }

      debugPrint("❌ User not found in any collection");
      await _auth.signOut();
      _showSnackbar("error_title".tr, "account_data_missing_error".tr, isError: true);
    } catch (e) {
      debugPrint("❌ Error checking user type: ${e.toString()}");
      await _auth.signOut();
      _showSnackbar("error_title".tr, "auth_failed".tr, isError: true);
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