import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          /// 🎨 Custom Gradient Header
          Container(
            // 🔹 Removed fixed height to allow dynamic sizing
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondary, AppColors.primary],
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
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: SmartText(
                          title: "about".tr,
                          size: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 48.w), // Balance for back button
                  ],
                ),
              ),
            ),
          ),

          /// 📄 About Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                _buildSectionTitle("about_title_subtitle".tr),
                _buildBodyText("about_description_1".tr),
                _buildBodyText("about_description_2".tr),
                
                const Divider(),
                
                _buildSectionTitle("about_for_employers".tr),
                _buildBulletPoint("about_employer_point_1".tr),
                _buildBulletPoint("about_employer_point_2".tr),
                _buildBulletPoint("about_employer_point_3".tr),
                _buildBulletPoint("about_employer_point_4".tr),
                _buildBulletPoint("about_employer_point_5".tr),

                const Divider(),

                _buildSectionTitle("about_for_job_seekers".tr),
                _buildBulletPoint("about_worker_point_1".tr),
                _buildBulletPoint("about_worker_point_2".tr),
                _buildBulletPoint("about_worker_point_3".tr),
                _buildBulletPoint("about_worker_point_4".tr),
                _buildBulletPoint("about_worker_point_5".tr),

                const Divider(),

                _buildSectionTitle("about_key_features".tr),
                _buildBulletPoint("about_feature_1".tr),
                _buildBulletPoint("about_feature_2".tr),
                _buildBulletPoint("about_feature_3".tr),
                _buildBulletPoint("about_feature_4".tr),
                _buildBulletPoint("about_feature_5".tr),
                _buildBulletPoint("about_feature_6".tr),
                _buildBulletPoint("about_feature_7".tr),

                const Divider(),

                _buildSectionTitle("about_how_it_works".tr),
                _buildBulletPoint("about_how_it_works_employer".tr),
                _buildBulletPoint("about_how_it_works_worker".tr),

                const Divider(),

                _buildSectionTitle("about_who_its_for".tr),
                _buildBulletPoint("about_who_its_for_1".tr),
                _buildBulletPoint("about_who_its_for_2".tr),
                _buildBulletPoint("about_who_its_for_3".tr),
                _buildBulletPoint("about_who_its_for_4".tr),

                const Divider(),

                _buildSectionTitle("about_why_choose_us".tr),
                _buildBulletPoint("about_reason_1".tr),
                _buildBulletPoint("about_reason_2".tr),
                _buildBulletPoint("about_reason_3".tr),
                _buildBulletPoint("about_reason_4".tr),
                _buildBulletPoint("about_reason_5".tr),

                const Divider(),

                _buildSectionTitle("about_privacy_security".tr),
                _buildBodyText("about_privacy_note".tr),
                _buildBulletPoint("about_privacy_point_1".tr),
                _buildBulletPoint("about_privacy_point_2".tr),
                _buildBulletPoint("about_privacy_point_3".tr),
                _buildBulletPoint("about_privacy_point_4".tr),
                
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: SmartText(
        title: title,
        size: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: SmartText(
        title: text,
        size: 14.sp,
        color: Colors.black87,
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Icon(Icons.circle, size: 6.sp, color: AppColors.secondary),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: SmartText(
              title: text,
              size: 14.sp,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
