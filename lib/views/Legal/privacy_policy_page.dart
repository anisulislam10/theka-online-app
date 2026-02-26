import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
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
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: SmartText(
                            title: 'privacy_policy'.tr,
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
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SmartText(
                      title: 'privacy_policy_content'.tr,
                      size: 14.sp,
                      color: Colors.grey[800],
                    ),
                    SizedBox(height: 20.h),
                    
                    _buildSection(
                      'information_we_collect'.tr,
                      'information_we_collect_desc'.tr,
                    ),
                    
                    _buildSection(
                      'how_we_use_info'.tr,
                      'how_we_use_info_desc'.tr,
                    ),
                    
                    _buildSection(
                      'information_sharing'.tr,
                      'information_sharing_desc'.tr,
                    ),
                    
                    _buildSection(
                      'data_security'.tr,
                      'data_security_desc'.tr,
                    ),
                    
                    _buildSection(
                      'your_rights'.tr,
                      'your_rights_desc'.tr,
                    ),
                    
                    _buildSection(
                      'contact_us'.tr,
                      'contact_us_desc'.tr,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmartText(
            title: title,
            size: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
          SizedBox(height: 8.h),
          SmartText(
            title: content,
            size: 14.sp,
            color: Colors.grey[700],
          ),
        ],
      ),
    );
  }
}
