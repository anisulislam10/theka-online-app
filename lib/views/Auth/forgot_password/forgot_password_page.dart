import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/widgets/custom_button.dart';
import 'package:quickserve/core/widgets/custom_text_field.dart';
import 'package:quickserve/views/Auth/forgot_password/forgot_password_controller.dart'; // ✅ import custom field

class ForgotPasswordPage extends StatelessWidget {
  ForgotPasswordPage({super.key});

  final ForgotPasswordController controller = Get.put(
    ForgotPasswordController(),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_reset,
                          size: 70.sp,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 20.h),

                        Text(
                          "forgot_password".tr,
                          style: TextStyle(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "forgot_password_subtitle".tr,
                          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40.h),

                        // ✅ Use controller.emailController
                        CustomTextField(
                          controller: controller.emailController,
                          hintText: "email".tr,
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: controller.validateEmail,
                        ),
                        SizedBox(height: 25.h),

                        // ✅ Button with loading indicator (optional)
                        CustomButton(
                          text: "send_reset_link".tr,
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            controller.sendResetLink();
                          },
                        ),
                        SizedBox(height: 20.h),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "back_to_login".tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 10.h,
              left: 16.w,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20.sp),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
