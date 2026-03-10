import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/views/MyRequest/my_request.dart';
import 'package:quickserve/views/Profile/CustomerProfile/customer_profile_settings.dart';
import 'package:quickserve/views/Profile/CustomerProfile/customer_profile_settings_controller.dart';
import 'package:quickserve/views/Legal/privacy_policy_page.dart';
import 'package:quickserve/views/Legal/terms_and_conditions_page.dart';
import 'package:quickserve/views/Legal/about_page.dart';
import 'package:quickserve/views/Auth/login_type_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../views/Auth/Login/login_page.dart';

class CustomDrawer extends StatelessWidget {
  final VoidCallback onSwitchMode;

  const CustomDrawer({super.key, required this.onSwitchMode});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomerProfileSettingsController());

    return SafeArea(
      child: Drawer(
        backgroundColor: AppColors.white,
        child: Column(
          children: [
            // Profile Header
            Obx(() {
              String rawName = controller.name.value.isNotEmpty
                  ? controller.name.value
                  : "User";

              // Helper for title case
              String name = rawName.split(' ').map((word) {
                if (word.isEmpty) return '';
                return word[0].toUpperCase() + word.substring(1).toLowerCase();
              }).join(' ');

              return InkWell(
                onTap: () => Get.to(() => const ProfileSettingsPage()),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30.r,
                        backgroundColor: AppColors.white,
                        child: ClipOval(
                          child: SizedBox(
                            width: 60.r,
                            height: 60.r,
                            child: CachedNetworkImage(
                              imageUrl:
                              controller.profileImageUrl.value.isNotEmpty
                                  ? controller.profileImageUrl.value
                                  : 'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 300),
                              fadeOutDuration: const Duration(milliseconds: 100),
                              placeholder: (context, url) => Center(
                                child: SizedBox(
                                  height: 30.r,
                                  width: 30.r,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                color: Colors.grey,
                                size: 60.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: SmartText(
                          title: name,
                          size: 16.sp,
                          fontWeight: FontWeight.w600,
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16.sp,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const Divider(),

            // Drawer Items
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Column(
                  children: [
                    _buildDrawerTile(
                      title: "requests".tr,
                      icon: Icons.history,
                      containerColor: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      textColor: Colors.blue.shade800,
                      onTap: () => Get.to(() => MyRequest()),
                    ),
                    SizedBox(height: 12.h),
                    
                    _buildDrawerTile(
                      title: "about".tr,
                      icon: Icons.info_outline,
                      containerColor: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      textColor: Colors.blue.shade800,
                      onTap: () => Get.to(() => const AboutPage()),
                    ),
                    SizedBox(height: 12.h),

                    _buildDrawerTile(
                      title: "terms_and_conditions".tr,
                      icon: Icons.description_outlined,
                      containerColor: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      textColor: Colors.blue.shade800,
                      onTap: () => Get.to(() => const TermsAndConditionsPage()),
                    ),
                    SizedBox(height: 12.h),

                    _buildDrawerTile(
                      title: "share_app".tr,
                      icon: Icons.share_outlined,
                      containerColor: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      textColor: Colors.blue.shade800,
                      onTap: () {
                        Share.share(
                          'Check out Theeka Online on Play Store: https://play.google.com/store/apps/details?id=com.shaplogicians.theka_online&hl=en',
                        );
                      },
                    ),
                    SizedBox(height: 12.h),

                    _buildDrawerTile(
                      title: "rate_on_playstore".tr,
                      icon: Icons.star_rate_outlined,
                      containerColor: Colors.blue.shade50,
                      iconColor: Colors.blue,
                      textColor: Colors.blue.shade800,
                      onTap: () async {
                        final Uri url = Uri.parse(
                          'https://play.google.com/store/apps/details?id=com.shaplogicians.theka_online&hl=en',
                        );
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          Get.snackbar("Error", "Could not launch Play Store");
                        }
                      },
                    ),
                    SizedBox(height: 12.h),

                    _buildDrawerTile(
                      title: "logout".tr,
                      icon: Icons.logout_rounded,
                      containerColor: Colors.red.shade50,
                      iconColor: AppColors.red, // Using red explicitly for logout to match previous logic
                      textColor: AppColors.red,
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required String title,
    required IconData icon,
    required Color containerColor,
    required Color iconColor,
    required Color textColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 10.r), // Reduced padding
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r), // Reduced icon padding
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18.sp), // Reduced icon size
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: SmartText(
                title: title,
                color: textColor,
                size: 14.sp, // Reduced font size
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor.withOpacity(0.6),
              size: 14.sp,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// ✅ FIXED LOGOUT DIALOG
// ============================================
void _showLogoutDialog(BuildContext context) {
  Get.dialog(
    AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.logout, color: AppColors.primary),
          const SizedBox(width: 10),
          SmartText(
            title: "confirm_logout".tr,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
            size: 18,
          ),
        ],
      ),
      content: SmartText(
        title: "are_you_sure_you_want_to_logout?".tr,
        color: AppColors.darkGrey,
        size: 15,
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppColors.lightGrey,
                  foregroundColor: AppColors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: SmartText(title: "no".tr, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  await performLogout();
                },
                child: SmartText(
                  title: "yes".tr,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    barrierDismissible: true,
  );
}

// ============================================
// ✅ COMPLETE LOGOUT FUNCTION (Session Cleared)
// Email/Password Authentication Only
// ============================================
Future<void> performLogout() async {
  try {
    // Show loading
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    debugPrint("🔹 Starting logout process...");

    // 1️⃣ Sign out from Firebase Auth (MOST IMPORTANT!)
    await FirebaseAuth.instance.signOut();
    debugPrint("✅ Firebase Auth signed out");

    // 2️⃣ Clear ALL GetX controllers and cached data
    Get.deleteAll(force: true);
    debugPrint("✅ All GetX controllers cleared");

    // Close loading dialog
    Get.back();

    // 3️⃣ Navigate to login and clear all previous routes
    Get.offAll(() => LoginPage());

    debugPrint("🎉 Logout completed successfully - Session cleared!");

    // Show success message
    Get.snackbar(
      "Logged Out",
      "You have been logged out successfully",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  } catch (e) {
    // Close loading if error occurs
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    debugPrint("❌ Error during logout: $e");

    Get.snackbar(
      "Logout Failed",
      "Something went wrong: ${e.toString()}",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }
}