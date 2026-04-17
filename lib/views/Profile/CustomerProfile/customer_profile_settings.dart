import 'dart:io';


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:quickserve/core/widgets/secure_firebase_image.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/core/widgets/custom_button.dart';
import 'package:quickserve/core/widgets/custom_text_field.dart';
import 'package:quickserve/core/widgets/city_drop_down.dart';
import 'package:quickserve/views/CustomerHome/widgets/home_page.dart';
import 'package:quickserve/views/Profile/CustomerProfile/customer_profile_settings_controller.dart';
import 'package:quickserve/views/Profile/reviews_page.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  void _openPhoto(BuildContext context, String imageUrl) {
    if (imageUrl.isEmpty) return;

    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.0,
                child: SecureFirebaseImage(
                  pathOrUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10.h,
              left: 10.w,
              child: SafeArea(
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      transition: Transition.fadeIn,
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CustomerProfileSettingsController());

    return WillPopScope(
      onWillPop: () async {
        Get.off(HomePage());
        return false;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              /// 🎨 Custom Gradient Header
              Container(
                padding: EdgeInsets.only(bottom: 20.h),
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
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                          onPressed: () => Get.off(HomePage()),
                        ),
                         Expanded(
                          child: Center(
                            child: SmartText(
                              title: "profile_settings".tr,
                              size: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Placeholder to balance the back button
                        SizedBox(width: 40.w),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.nameController.text.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

            return SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: SafeArea(
                child: Column(
                  children: [
                    // Profile Image
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        GestureDetector(
                          onTap: () => _openPhoto(
                            context,
                            controller.profileImageUrl.value,
                          ),
                          child: CircleAvatar(
                            radius: 55.r,
                            backgroundColor: AppColors.white,
                            child: ClipOval(
                              child: Obx(() {
                                if (controller.selectedImageFile.value !=
                                    null) {
                                  return Image.file(
                                    File(controller.selectedImageFile.value!.path),
                                    fit: BoxFit.cover,

                                    width: 110.r,
                                    height: 110.r,
                                  );
                                } else {
                                  return SecureFirebaseImage(
                                    pathOrUrl: controller.profileImageUrl.value,
                                    fit: BoxFit.cover,
                                    width: 110.r,
                                    height: 110.r,
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
                                      size: 60,
                                    ),
                                  );
                                }
                              }),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              controller.showImageSourceDialog(context),
                          child: CircleAvatar(
                            radius: 16.r,
                            backgroundColor: AppColors.primary,
                            child: Icon(
                              Icons.camera_alt,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12.h),

                    // ⭐ See Reviews Link
                    GestureDetector(
                      onTap: () => Get.to(() => ReviewsPage(
                        userId: controller.userId,
                        name: controller.nameController.text,
                        role: ReviewRole.customer,
                      )),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.primary, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 18.sp),
                            SizedBox(width: 8.w),
                            SmartText(
                              title: "see_reviews".tr,
                              size: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4.w),
                            Icon(Icons.arrow_forward_ios, size: 12.sp, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    SizedBox(height: 20.h),
                    // Name
                    CustomTextField(
                      controller: controller.nameController,
                      hintText: "full_name".tr,
                      prefixIcon: Icons.person,
                      enabled: false,
                    ),
                    SizedBox(height: 16.h),

                    // Email
                    CustomTextField(
                      controller: controller.emailController,
                      hintText: "email".tr,
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                    ),
                    SizedBox(height: 16.h),

                    // Phone
                    CustomTextField(
                      controller: controller.phoneController,
                      hintText: "phone".tr,
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      enabled: false,
                    ),
                    SizedBox(height: 16.h),

                    // City Dropdown
                    CityDropdown(
                      selectedCity: controller.selectedCity.value,
                      onChanged: (city) =>
                          controller.selectedCity.value = city ?? '',
                      enabled: false,
                    ),

                    SizedBox(height: 30.h),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    ),
  ),
),
    );
  }
}


