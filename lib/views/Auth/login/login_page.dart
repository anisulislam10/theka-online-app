import 'package:quickserve/core/widgets/secure_firebase_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/widgets/custom_button.dart';
import 'package:quickserve/core/widgets/custom_text_field.dart';
import 'package:quickserve/views/Auth/forgot_password/forgot_password_page.dart';
import 'package:quickserve/core/widgets/language_selector.dart';
import '../login_type_page.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA), // Detailed modern grey
        body: Stack(
          children: [
            // Header Background
            Container(
              height: 320.h,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.secondary, AppColors.primary],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40.r),
                  bottomRight: Radius.circular(40.r),
                ),
              ),
            ),

            // Top-right Language Selector
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  children: [
                    SizedBox(height: 30.h),

                    // Logo
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(4.r),
                      child: ClipOval(
                        child: SecureFirebaseImage(
                          pathOrUrl: 'https://play-lh.googleusercontent.com/UOGpk5_SOc9SfmhOt2iHKULwVVlRzDwIZzTM0XXrkpfbXn6YyugxWk2lA-Y6Y-WkriF3dFBk7_hqjZz2NbMh=w480-h960-rw',
                          height: 110.h,
                          width: 110.h,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 110.h,
                            width: 110.h,
                            color: Colors.grey[100],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 110.h,
                            width: 110.h,
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported, color: Colors.grey, size: 30.sp),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 20.h),
                    Text(
                      "welcome_back".tr,
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "login_subtitle".tr,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),

                    SizedBox(height: 35.h),

                    // Main Login Card
                    Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 30.h,
                        horizontal: 24.w,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 25,
                            spreadRadius: 0,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Custom Toggle
                            Obx(
                              () => Container(
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (!controller.isPhoneLogin.value)
                                            controller.toggleLoginMethod();
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: controller.isPhoneLogin.value
                                                ? Colors.white
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                            boxShadow:
                                                controller.isPhoneLogin.value
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "phone_tab".tr,
                                              style: TextStyle(
                                                color:
                                                    controller
                                                        .isPhoneLogin
                                                        .value
                                                    ? Colors.black
                                                    : Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (controller.isPhoneLogin.value)
                                            controller.toggleLoginMethod();
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 10.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                !controller.isPhoneLogin.value
                                                ? Colors.white
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                            boxShadow:
                                                !controller.isPhoneLogin.value
                                                ? [
                                                    BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              "email_tab".tr,
                                              style: TextStyle(
                                                color:
                                                    !controller
                                                        .isPhoneLogin
                                                        .value
                                                    ? Colors.black
                                                    : Colors.grey[600],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 25.h),

                            // ==================== PHONE LOGIN SECTION ====================
                            Obx(() {
                              if (controller.isPhoneLogin.value) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Phone number row
                                    Row(
                                      children: [
                                        Container(
                                          height: 55.h,
                                          padding: EdgeInsets.symmetric(horizontal: 15.w),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[50],
                                            borderRadius: BorderRadius.circular(14.r),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "+92",
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: TextFormField(
                                            controller: controller.phoneController,
                                            keyboardType: TextInputType.number,
                                            maxLength: 10,
                                            enabled: !controller.showOtpSection.value,
                                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                                            validator: (value) {
                                              if (value == null || value.trim().isEmpty) {
                                                return "enter_phone_number".tr;
                                              }
                                              if (value.trim().length != 10) {
                                                return "invalid_phone".tr;
                                              }
                                              if (!value.trim().startsWith('3')) {
                                                return "Phone must start with 3";
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              counterText: "",
                                              hintText: "phone_hint_login".tr,
                                              filled: true,
                                              fillColor: controller.showOtpSection.value
                                                  ? Colors.grey[100]
                                                  : Colors.grey[50],
                                              hintStyle: TextStyle(fontSize: 15.sp, color: Colors.grey[400]),
                                              contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14.r),
                                                borderSide: BorderSide(color: Colors.grey[300]!),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14.r),
                                                borderSide: BorderSide(color: Colors.grey[300]!),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14.r),
                                                borderSide: BorderSide(color: AppColors.primary),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14.r),
                                                borderSide: const BorderSide(color: Colors.red),
                                              ),
                                              focusedErrorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(14.r),
                                                borderSide: const BorderSide(color: Colors.red, width: 2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),


                                    SizedBox(height: 10.h),

                                    // Send OTP / Verify button
                                    Obx(() => CustomButton(
                                      text: controller.isLoading.value
                                          ? "processing".tr
                                          : "login".tr,
                                      onPressed: () {
                                        if (!controller.isLoading.value) {
                                          controller.loginWithPhone(context);
                                        }
                                      },
                                    )),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            }),

                            // ==================== EMAIL LOGIN SECTION ====================
                            Obx(() {
                              if (!controller.isPhoneLogin.value) {
                                return Column(
                                  children: [
                                    CustomTextField(
                                      controller: controller.emailController,
                                      hintText: "email".tr,
                                      prefixIcon: Icons.email_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return "enter_email".tr;
                                        }
                                        if (!GetUtils.isEmail(value.trim())) {
                                          return "invalid_email".tr;
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16.h),
                                    CustomTextField(
                                      controller: controller.passwordController,
                                      hintText: "password".tr,
                                      prefixIcon: Icons.lock_rounded,
                                      obscureText: true,
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return "password_required".tr;
                                        }
                                        if (value.length < 6) {
                                          return "password_min_6".tr;
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 10.h),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () =>
                                            Get.to(() => ForgotPasswordPage()),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 5.w,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          "forgot_password".tr,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 20.h),
                                    Obx(
                                      () => CustomButton(
                                        text: controller.isLoading.value
                                            ? "logging_in".tr
                                            : "login".tr,
                                        onPressed: () {
                                          if (!controller.isLoading.value) {
                                            controller.loginWithEmail(context);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            }),

                            SizedBox(height: 25.h),

                            /*
                            // Social Login Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey[300])),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                                  child: Text(
                                    "or_login_with".tr,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey[300])),
                              ],
                            ),

                            SizedBox(height: 25.h),

                            // Facebook Login Button
                            OutlinedButton(
                              onPressed: () => controller.signInWithFacebook(context),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                backgroundColor: Colors.white,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.facebook, color: const Color(0xFF1877F2), size: 24.sp),
                                  SizedBox(width: 12.w),
                                  Text(
                                    "continue_with_facebook".tr,
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            */
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 30.h),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "new_to_theka".tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.to(() => RegisterTypePage()),
                          child: Text(
                            "create_account".tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5.h),
                    TextButton(
                      onPressed: () => controller.loginAsGuest(),
                      child: Text(
                        "continue_as_guest".tr,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            // Top-right Language Selector
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16.w,
              child: const LanguageSelector(),
            ),
          ],
        ),
      ),
    );
  }
}
