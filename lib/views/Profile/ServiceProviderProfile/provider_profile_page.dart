import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickserve/views/Profile/ServiceProviderProfile/edit_profile_page.dart';
import 'package:quickserve/views/Profile/ServiceProviderProfile/provider_profile_controller.dart';
import 'package:quickserve/views/Splash/welcome_screen.dart';
import 'package:quickserve/core/widgets/secure_firebase_image.dart';

import '../../Auth/Login/login_page.dart';
import '../../Auth/login_type_page.dart';
import '../../Legal/privacy_policy_page.dart';
import '../../Legal/terms_and_conditions_page.dart';
import '../../Legal/about_page.dart';

class ProviderProfilePage extends StatelessWidget {
  const ProviderProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProviderProfileController());

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          /// 🎨 Custom Gradient Header
          Container(
            padding: EdgeInsets.only(top: 10.h, bottom: 25.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.secondary,
                  AppColors.primary,
                ],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r),
                bottomRight: Radius.circular(30.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                child: Row(
                  children: [
                    // Back Button (or Menu if it's a root tab)
                    // Usually Profile is a root tab in BottomNav, so maybe no back button?
                    // But if pushed, back button. Let's assume it's a tab for now or provide back if canPop.
                    // The original had "automaticallyImplyLeading: true" (default) but likely it's a tab.
                    // If it's a tab, we don't need a back button.
                    // Let's assume no back button for now as it's likely a main tab.
                    Expanded(
                      child: Center(
                        child: SmartText(
                          title: "settings".tr,
                          size: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => Get.to(() => EditProfilePage()),
                        child: Container(
                          padding: EdgeInsets.all(16.r),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipOval(
                                child: SizedBox(
                                  width: 64.r,
                                  height: 64.r,
                                  child: controller.profileImageUrl.value.isNotEmpty
                                      ? SecureFirebaseImage(
                                          pathOrUrl: controller.profileImageUrl.value,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          'https://cdn-icons-png.flaticon.com/512/149/149071.png',
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),

                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SmartText(
                                      title: controller.nameController.text,
                                      size: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.black,
                                    ),
                                    SizedBox(height: 4.h),
                                    SmartText(
                                      title:
                                          controller
                                              .categoryController
                                              .text
                                              .isNotEmpty
                                          ? controller.categoryController.text
                                          : 'no_category_selected'.tr,
                                      size: 14.sp,
                                      color: AppColors.darkGrey,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 25.h),

                      _buildTile(
                        title: 'about'.tr,
                        icon: Icons.info_outline,
                        containerColor: Colors.blue.shade50,
                        iconColor: Colors.blue,
                        textColor: Colors.blue.shade800,
                        onTap: () => Get.to(() => const AboutPage()),
                      ),

                      SizedBox(height: 15.h),

                      _buildTile(
                        title: 'privacy_policy'.tr,
                        icon: Icons.privacy_tip_outlined,
                        containerColor: Colors.blue.shade50,
                        iconColor: Colors.blue,
                        textColor: Colors.blue.shade800,
                        onTap: () => Get.to(() => const PrivacyPolicyPage()),
                      ),

                      SizedBox(height: 15.h),

                      _buildTile(
                        title: 'terms_and_conditions'.tr,
                        icon: Icons.description_outlined,
                        containerColor: Colors.blue.shade50,
                        iconColor: Colors.blue,
                        textColor: Colors.blue.shade800,
                        onTap: () => Get.to(() => const TermsAndConditionsPage()),
                      ),

                      SizedBox(height: 15.h),

                      _buildTile(
                        title: 'share_app'.tr,
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

                      SizedBox(height: 15.h),

                      _buildTile(
                        title: 'rate_on_playstore'.tr,
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

                      SizedBox(height: 15.h),

                      _buildTile(
                        title: 'logout'.tr,
                        icon: Icons.logout_rounded,
                        containerColor: Colors.red.shade50,
                        iconColor: AppColors.primary,
                        textColor: AppColors.primary,
                        onTap: () {
                          Get.dialog(
                            AlertDialog(
                              backgroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              title: Column(
                                children: [
                                  Icon(
                                    Icons.logout_rounded,
                                    color: AppColors.red,
                                    size: 36.r,
                                  ),
                                  SizedBox(height: 10.h),
                                  SmartText(
                                    title: "logout".tr,
                                    size: 18.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ],
                              ),
                              content: SmartText(
                                title: "are_you_sure_you_want_to_logout?".tr,
                                textAlign: TextAlign.center,
                                size: 14.sp,
                                color: AppColors.darkGrey,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text("cancel".tr),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    // 🔹 Google Logout
                                    try {
                                      await GoogleSignIn.instance.signOut();
                                    } catch (_) {}

                                    // 🔹 Firebase Logout
                                    try {
                                      await FirebaseAuth.instance.signOut();
                                    } catch (_) {}

                                    // 🔹 Navigate to welcome screen
                                    Get.offAll(() => LoginPage());
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.red,
                                  ),
                                  child: SmartText(
                                    title: "logout".tr,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
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
          borderRadius: BorderRadius.circular(12.r),
        ),
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SmartText(
                title: title,
                color: textColor,
                size: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: textColor.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
