/*
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appAssets.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/core/services/translation_service.dart';
import 'package:quickserve/core/widgets/custom_google_button.dart';
import 'package:quickserve/views/Auth/CustomerLogin/customer_login_controller.dart';
import 'package:quickserve/views/Auth/Register/ServiceProviderRegister/service_provider_register_controller.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: SmartText(title: "exit_app".tr),
            content: SmartText(title: "are_you_sure_you_want_to_exit?".tr),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: SmartText(title: "no".tr),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: SmartText(title: "yes".tr, color: Colors.red),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final customerLoginController = Get.put(LoginController(), permanent: true);
    final providerController = Get.put(
      ServiceProviderRegisterController(),
      permanent: true,
    );

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          automaticallyImplyLeading: false,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.language, color: Colors.black),
              onPressed: () {
                Locale current = Get.locale ?? const Locale('en', 'US');
                if (current.languageCode == 'en') {
                  TranslationService.changeLocale('ur');
                } else {
                  TranslationService.changeLocale('en');
                }
              },
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: 80.h),

              Image.asset(AppImages.applogo, width: 180.w, height: 180.h),

              SizedBox(height: 20.h),
              SmartText(title: "welcome_to_theka_online".tr, size: 24.sp),

              SizedBox(height: 20.h),

              /// CUSTOMER GOOGLE LOGIN
              Obx(
                () => CustomGoogleButton(
                  isLoading: customerLoginController.isLoading.value,
                  text: "continue_as_customer".tr,
                  onPressed: () {
                    customerLoginController.signInWithGoogleCustomer();
                  },
                ),
              ),

              SizedBox(height: 20.h),

              /// PROVIDER GOOGLE LOGIN
              Obx(
                () => CustomGoogleButton(
                  isLoading: providerController.isLoading.value,
                  text: "continue_as_service_provider".tr,
                  onPressed: () {
                    providerController.signInWithGoogle(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/
