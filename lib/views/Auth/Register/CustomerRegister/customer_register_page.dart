import 'dart:io';
import 'package:quickserve/core/widgets/secure_firebase_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/core/widgets/custom_button.dart';
import 'package:quickserve/core/widgets/custom_text_field.dart';
import 'package:quickserve/views/Auth/Register/CustomerRegister/customer_register_controller.dart';
import '../../../../core/widgets/city_drop_down.dart';

class CustomerRegisterPage extends StatelessWidget {
  CustomerRegisterPage({super.key});
  final controller = Get.put(CustomerRegisterController());

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
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

            SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 70.h,
                        ), // Adjust space for pinned back button
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
                              height: 90.h,
                              width: 90.h,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 90.h,
                                width: 90.h,
                                color: Colors.grey[100],
                                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 90.h,
                                width: 90.h,
                                color: Colors.grey[200],
                                child: Icon(Icons.image_not_supported, color: Colors.grey, size: 30.sp),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 15.h),
                        SmartText(
                          title: "create_account_title".tr,
                          size: 26.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        SizedBox(height: 5.h),
                        SmartText(
                          title: "sign_up_as_customer".tr,
                          size: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),

                        SizedBox(height: 25.h),

                        // Form Card
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 25.h,
                            horizontal: 20.w,
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
                              children: [
                                // Profile Image Picker
                                GestureDetector(
                                  onTap: () => controller.pickImage(context),
                                  child: Obx(() => Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.primary,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(
                                                    0.1,
                                                  ),
                                                  blurRadius: 10,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              radius: 50.r,
                                              backgroundColor: Colors.grey[100],
                                              backgroundImage:
                                                  controller
                                                              .selectedImageFile
                                                              .value !=
                                                          null
                                                      ? FileImage(
                                                          File(
                                                            controller
                                                                .selectedImageFile
                                                                .value!
                                                                .path,
                                                          ),
                                                        )
                                                      : null,
                                              child:
                                                  controller
                                                              .selectedImageFile
                                                              .value ==
                                                          null
                                                      ? Icon(
                                                          Icons.person,
                                                          size: 50.sp,
                                                          color:
                                                              Colors.grey[400],
                                                        )
                                                      : null,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding: EdgeInsets.all(6.r),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.camera_alt,
                                                color: Colors.white,
                                                size: 16.sp,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )),
                                ),
                                SizedBox(height: 20.h),

                                // Name Field
                                CustomTextField(
                                  controller: controller.nameController,
                                  hintText: "full_name".tr,
                                  prefixIcon: Icons.person_rounded,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "enter_name".tr;
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 15.h),

                                // Email Field (Optional)
                                CustomTextField(
                                  controller: controller.emailController,
                                  hintText: "your_email".tr,
                                  prefixIcon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value != null &&
                                        value.trim().isNotEmpty) {
                                      if (!GetUtils.isEmail(value.trim())) {
                                        return "invalid_email".tr;
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 15.h),

                                // Phone Number Field (Required)
                                Row(
                                  children: [
                                    Container(
                                      height: 55.h,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 15.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(
                                          14.r,
                                        ),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
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
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return "enter_phone_number".tr;
                                          }
                                          if (value.trim().length != 10) {
                                            return "invalid_phone".tr;
                                          }
                                          return null;
                                        },
                                        decoration: InputDecoration(
                                          counterText: "",
                                          hintText: "phone_hint_login".tr,
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          hintStyle: TextStyle(
                                            fontSize: 15.sp,
                                            color: Colors.grey[400],
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            vertical: 16.h,
                                            horizontal: 16.w,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              14.r,
                                            ),
                                            borderSide: BorderSide(
                                              color: Colors.red,
                                            ),
                                          ),
                                          focusedErrorBorder:
                                              OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14.r),
                                                borderSide: BorderSide(
                                                  color: Colors.red,
                                                  width: 2,
                                                ),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15.h),

                                // City Dropdown
                                FormField<String>(
                                  validator: (value) {
                                    if (controller.selectedCity.value.isEmpty) {
                                      return "select_city".tr;
                                    }
                                    return null;
                                  },
                                  builder: (state) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        CityDropdown(
                                          selectedCity:
                                              controller
                                                  .selectedCity
                                                  .value
                                                  .isEmpty
                                              ? "select_city_label".tr
                                              : controller.selectedCity.value,
                                          onChanged: (city) {
                                            controller.selectedCity.value =
                                                city ?? '';
                                            state.didChange(city);
                                          },
                                        ),
                                        if (state.hasError)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              left: 12.w,
                                              top: 5.h,
                                            ),
                                            child: Text(
                                              state.errorText!,
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                                SizedBox(height: 15.h),

                                // Precise Location / Address Field
                                Obx(() => CustomTextField(
                                      controller: controller.addressController,
                                      hintText: "Precise Address / Location",
                                      prefixIcon: Icons.location_on_rounded,
                                      suffixIcon: controller.isFetchingLocation.value
                                          ? Container(
                                              padding: EdgeInsets.all(12.r),
                                              width: 30.w,
                                              height: 30.w,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : IconButton(
                                              icon: Icon(
                                                Icons.my_location,
                                                color: AppColors.primary,
                                              ),
                                              onPressed: () =>
                                                  controller.getCurrentLocation(),
                                            ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return "Please provide your location";
                                        }
                                        return null;
                                      },
                                    )),
                                SizedBox(height: 15.h),

                                // Password Field
                                CustomTextField(
                                  controller: controller.passwordController,
                                  hintText: "password".tr,
                                  prefixIcon: Icons.lock_rounded,
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "password_required".tr;
                                    }
                                    if (value.length < 6) {
                                      return "password_min_6".tr;
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 20.h),

                                // OTP Section (shown after OTP is sent)
                                Obx(() => controller.showOtpSection.value
                                    ? Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            "Enter the 6-digit OTP sent to +92${controller.phoneController.text}",
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.grey[600],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          SizedBox(height: 12.h),
                                          TextFormField(
                                            controller: controller.otpController,
                                            keyboardType: TextInputType.number,
                                            maxLength: 6,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 22.sp,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 8,
                                            ),
                                            decoration: InputDecoration(
                                              counterText: "",
                                              hintText: "000000",
                                              hintStyle: TextStyle(
                                                fontSize: 20.sp,
                                                color: Colors.grey[400],
                                                letterSpacing: 6,
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey[50],
                                              contentPadding: EdgeInsets.symmetric(
                                                vertical: 16.h,
                                                horizontal: 16.w,
                                              ),
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
                                                borderSide: BorderSide(color: AppColors.primary, width: 2),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 6.h),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Obx(() => TextButton(
                                              onPressed: controller.isLoading.value
                                                  ? null
                                                  : () => controller.resendOtp(context),
                                              child: Text(
                                                "Resend OTP",
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )),
                                          ),
                                          SizedBox(height: 4.h),
                                        ],
                                      )
                                    : const SizedBox.shrink()),

                                // Primary Action Button
                                Obx(
                                  () => CustomButton(
                                    text: controller.isLoading.value
                                        ? "processing".tr
                                        : controller.showOtpSection.value
                                            ? "verify_and_register".tr
                                            : "sign_up".tr,
                                    onPressed: () {
                                      if (!controller.isLoading.value) {
                                        if (controller.showOtpSection.value) {
                                          controller.verifyOtpAndRegister(context);
                                        } else {
                                          controller.sendOtp(context);
                                        }
                                      }
                                    },
                                  ),
                                ),

                                SizedBox(height: 20.h),

                                /*
                                // OR Divider
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.grey[300])),
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                                      child: Text(
                                        "or_register_with".tr,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 13.sp,
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.grey[300])),
                                  ],
                                ),

                                SizedBox(height: 20.h),

                                // Facebook Button
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
                      ],
                    ),
                  ),

                  Positioned(
                    top: 10.h,
                    left: 24.w,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
