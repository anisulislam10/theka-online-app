import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/core/widgets/custom_button.dart';
import 'package:quickserve/core/widgets/custom_text_field.dart';
import 'package:quickserve/core/widgets/city_drop_down.dart';
import 'service_provider_register_controller.dart';

class ServiceProviderRegisterPage extends StatelessWidget {
  const ServiceProviderRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ServiceProviderRegisterController());

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
                  colors: [
                    AppColors.secondary,
                    AppColors.primary,
                  ],
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
                        SizedBox(height: 70.h), // Adjust space for pinned back button
                        
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
                            child: CachedNetworkImage(
                              imageUrl: 'https://play-lh.googleusercontent.com/UOGpk5_SOc9SfmhOt2iHKULwVVlRzDwIZzTM0XXrkpfbXn6YyugxWk2lA-Y6Y-WkriF3dFBk7_hqjZz2NbMh=w480-h960-rw',
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SmartText(
                            title: "join_as_provider".tr,
                            size: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SmartText(
                            title: "create_account_subtitle_provider".tr,
                            size: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        SizedBox(height: 25.h),

                        // Form Card
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 25.h, horizontal: 20.w),
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
                                onTap: () => controller.pickImage(),
                                child: Obx(() => Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.primary, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          )
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 50.r,
                                        backgroundColor: Colors.grey[100],
                                        backgroundImage: controller.selectedImageFile.value != null
                                            ? FileImage(File(controller.selectedImageFile.value!.path))
                                            : null,
                                        child: controller.selectedImageFile.value == null
                                            ? Icon(Icons.person, size: 50.sp, color: Colors.grey[400])
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
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: Icon(Icons.camera_alt, color: Colors.white, size: 16.sp),
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
                                  if (value != null && value.trim().isNotEmpty) {
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
                                        fillColor: Colors.grey[50],
                                        hintStyle: TextStyle(
                                          fontSize: 15.sp,
                                          color: Colors.grey[400],
                                        ),
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
                                          borderSide: BorderSide(color: Colors.red),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(14.r),
                                          borderSide: BorderSide(color: Colors.red, width: 2),
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CityDropdown(
                                        selectedCity: controller.selectedCity.value.isEmpty
                                            ? "select_city_label".tr
                                            : controller.selectedCity.value,
                                        onChanged: (city) {
                                          controller.selectedCity.value = city ?? '';
                                          state.didChange(city);
                                        },
                                      ),
                                      if (state.hasError)
                                        Padding(
                                          padding: EdgeInsets.only(left: 12.w, top: 5.h),
                                          child: Text(
                                            state.errorText!,
                                            style: TextStyle(color: Colors.red, fontSize: 12.sp),
                                          ),
                                        ),
                                    ],
                                  );
                                }
                              ),
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

                              // OTP Section
                              Obx(() {
                                if (controller.showOtpSection.value) {
                                  return Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(12.w),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(10.r),
                                          border: Border.all(color: Colors.blue.withOpacity(0.1)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.mark_email_unread_outlined, color: Colors.blue, size: 20.sp),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: SmartText(
                                                title: "${"otp_sent_to".tr} ${controller.phoneController.text}",
                                                size: 13.sp,
                                                color: Colors.blue[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 15.h),
                                      CustomTextField(
                                        controller: controller.otpController,
                                        hintText: "enter_6_digit_otp".tr,
                                        prefixIcon: Icons.password_rounded,
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return "enter_otp".tr;
                                          }
                                          if (value.trim().length != 6) {
                                            return "enter_otp".tr;
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 10.h),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () => controller.resendOtp(context),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: SmartText(
                                            title: "resend_otp".tr,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                            size: 13.sp,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 10.h),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              }),

                              // Register/Send OTP Button
                              Obx(
                                    () => CustomButton(
                                  text: controller.isLoading.value
                                      ? "processing".tr
                                      : controller.showOtpSection.value
                                      ? "verify_and_continue".tr
                                      : "send_otp".tr,
                                  onPressed: () {
                                    if (!controller.isLoading.value) {
                                      if (controller.showOtpSection.value) {
                                        controller.verifyOtpAndContinue(context);
                                      } else {
                                        controller.sendOtp(context);
                                      }
                                    }
                                  },
                                ),
                              ),
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
                        icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
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
