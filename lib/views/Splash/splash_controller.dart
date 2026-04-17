import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:quickserve/views/Auth/AccountScreens/account_verification_screen.dart';
import 'package:quickserve/views/Auth/login_type_page.dart';
import 'package:quickserve/views/BottomNavbar/bottom_navbar.dart';
import 'package:quickserve/views/CustomerHome/widgets/home_page.dart';
import 'package:quickserve/views/Auth/AuthService/auth_service.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'force_update_page.dart';

import '../Auth/Login/login_page.dart';

class SplashController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void onInit() {
    super.onInit();
    _handleSplashNavigation();
  }

  /// Handles navigation after splash delay
  Future<void> _handleSplashNavigation() async {
    await Future.delayed(const Duration(seconds: 2));

    // 1. Check for force update first
    bool needsUpdate = await _checkVersion();
    if (needsUpdate) {
      Get.offAll(() => const ForceUpdatePage());
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      debugPrint("🚫 No Firebase session found");
      Get.offAll(() => LoginPage());
      return;
    }

    debugPrint("✅ Firebase session active for UID: ${user.uid}");
    debugPrint("📧 Firebase Email: ${user.email}");
    await _checkUserRole(user.uid);
  }

  /// Determines if the user is a ServiceProvider or Customer
  Future<void> _checkUserRole(String uid) async {
    try {
      final savedRole = AuthService.getSavedRole();
      debugPrint("💾 Saved role found in SharedPreferences: $savedRole");

      final providerDoc = await _firestore
          .collection('ServiceProviders')
          .doc(uid)
          .get();
      final customerDoc = await _firestore
          .collection('Customers')
          .doc(uid)
          .get();

      // PRIORITIZE SAVED ROLE
      if (savedRole == 'ServiceProvider' && providerDoc.exists) {
        debugPrint("👷 Routing to ServiceProvider based on saved role");
        await _handleServiceProvider(providerDoc);
        return;
      } else if (savedRole == 'customer' && customerDoc.exists) {
        debugPrint("🧍 Routing to Customer based on saved role");
        Get.offAll(() => HomePage());
        return;
      }

      // FALLBACK TO ORIGINAL LOGIC
      if (providerDoc.exists) {
        debugPrint("👷 Found user in ServiceProviders collection");
        final data = providerDoc.data();
        debugPrint("🪪 Name: ${data?['name'] ?? 'N/A'}");
        debugPrint("📧 Email: ${data?['email'] ?? 'N/A'}");
        debugPrint("📧 Phone: ${data?['phone'] ?? 'N/A'}");
        await _handleServiceProvider(providerDoc);
      } else if (customerDoc.exists) {
        debugPrint("🧍 Found user in Customers collection");
        final data = customerDoc.data();
        debugPrint("🪪 Name: ${data?['name'] ?? 'N/A'}");
        debugPrint("📧 Email: ${data?['email'] ?? 'N/A'}");
        debugPrint("📧 Phone: ${data?['phone'] ?? 'N/A'}");
        Get.offAll(() => HomePage());
      } else {
        debugPrint("⚠️ User not found in either collection");
        Get.offAll(() => LoginPage());
      }
    } catch (e) {
      debugPrint("❌ Error checking user role: $e");
      Get.offAll(() => LoginPage());
    }
  }

  /// Handles service provider status and routing
  Future<void> _handleServiceProvider(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final status = (doc.data()?['accountStatus'] ?? 'pending')
        .toString()
        .toLowerCase();

    debugPrint("🧾 ServiceProvider status: $status");

    if (status == 'accepted') {
      Get.offAll(() => const BottomNavbar());
    } else {
      Get.offAll(() => const AccountVerificationScreen());
    }
  }

  /// Checks if the app version is below the minimum required version
  Future<bool> _checkVersion() async {
    try {
      debugPrint("🔍 Checking for app updates...");
      
      // Get current app version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version; // e.g. "1.2.1"
      debugPrint("📱 Current App Version: $currentVersion");

      // Get minimum required version from Firestore
      // Path: version_control/settings -> { min_version: "1.2.1" }
      DocumentSnapshot settings = await _firestore
          .collection('version_control')
          .doc('settings')
          .get();

      if (settings.exists) {
        String minVersion = settings.get('min_version') ?? "1.0.0";
        debugPrint("📡 Minimum Required Version: $minVersion");

        // Helper to compare versions (e.g. "1.2.1" vs "1.2.0")
        return _isVersionLower(currentVersion, minVersion);
      }
    } catch (e) {
      debugPrint("⚠️ Version check failed: $e. Skipping update check.");
    }
    return false;
  }

  /// Returns true if [current] is lower than [min]
  bool _isVersionLower(String current, String min) {
    try {
      List<int> currentParts = current.split('.').map(int.parse).toList();
      List<int> minParts = min.split('.').map(int.parse).toList();

      for (int i = 0; i < minParts.length; i++) {
        int currentPart = i < currentParts.length ? currentParts[i] : 0;
        int minPart = minParts[i];

        if (currentPart < minPart) return true;
        if (currentPart > minPart) return false;
      }
    } catch (e) {
      debugPrint("❌ Version parsing error: $e");
    }
    return false;
  }
}
