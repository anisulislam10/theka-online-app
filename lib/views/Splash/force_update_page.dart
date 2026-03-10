import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.update_rounded,
                size: 100.sp,
                color: AppColors.primary,
              ),
              SizedBox(height: 30.h),
              SmartText(
                title: "update_required".tr,
                size: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 15.h),
              SmartText(
                title: "please_update_app_message".tr,
                size: 16.sp,
                color: AppColors.darkGrey,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 15.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: () async {
                    final Uri url = Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.shaplogicians.theka_online&hl=en',
                    );
                    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                      Get.snackbar("Error", "Could not launch Play Store");
                    }
                  },
                  child: SmartText(
                    title: "update_now".tr,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
