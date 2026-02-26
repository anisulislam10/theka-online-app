import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/widgets/custom_button.dart';
import 'package:quickserve/core/widgets/custom_text_field.dart';
import 'package:quickserve/views/Auth/ServiceProviderLogin/provider_login_controller.dart';
import 'package:quickserve/views/Auth/Register/ServiceProviderRegister/service_provider_register_page.dart';
import 'package:quickserve/views/Auth/forgot_password/forgot_password_page.dart';

class ServiceProviderLoginPage extends StatelessWidget {
  ServiceProviderLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProviderLoginController());
    final formKey = GlobalKey<FormState>();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 50.h),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Center(
                        child: Text(
                          "Service Provider Login",
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      SizedBox(height: 40.h),

                      // ✅ Email field
                      CustomTextField(
                        controller: controller.emailController,
                        hintText: "Email",
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your email";
                          }
                          if (!GetUtils.isEmail(value)) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // ✅ Password field
                      CustomTextField(
                        controller: controller.passwordController,
                        hintText: "Password",
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your password";
                          }
                          if (value.length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 25.h),

                      // ✅ Login Button
                      Obx(
                        () => CustomButton(
                          text: controller.isLoading.value
                              ? "Logging in..."
                              : "Login",
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              controller.login(context);
                            }
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          isLoading: controller.isLoading.value,
                        ),
                      ),

                      SizedBox(height: 15.h),

                      // Forgot password
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Get.to(() => ForgotPasswordPage());
                          },
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Signup link
                      Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            GestureDetector(
                              onTap: () {
                                Get.to(() => ServiceProviderRegisterPage());
                              },
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
