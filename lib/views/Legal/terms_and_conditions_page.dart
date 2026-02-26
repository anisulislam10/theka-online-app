import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

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
              padding: EdgeInsets.symmetric(horizontal: 16.w),
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
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: SmartText(
                            title: 'terms_and_conditions'.tr,
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
                      title: 'terms_and_conditions_content'.tr,
                      size: 14.sp,
                      color: Colors.grey[800],
                    ),
                    SizedBox(height: 20.h),
                    
                    _buildSection(
                      'acceptance_of_terms'.tr,
                      'acceptance_of_terms_desc'.tr,
                    ),
                    
                    _buildSection(
                      'use_of_service'.tr,
                      'use_of_service_desc'.tr,
                    ),
                    
                    _buildSection(
                      'user_accounts'.tr,
                      'user_accounts_desc'.tr,
                    ),
                    
                    _buildSection(
                      'provider_responsibilities'.tr,
                      'provider_responsibilities_desc'.tr,
                    ),
                    
                    _buildSection(
                      'customer_responsibilities'.tr,
                      'customer_responsibilities_desc'.tr,
                    ),
                    
                    
                    
                   
                    _buildSection(
                      'changes_to_terms'.tr,
                      'changes_to_terms_desc'.tr,
                    ),

                    SizedBox(height: 20.h),
                    Center(
                      child: Column(
                        children: [
                          SmartText(
                            title: 'contact_us'.tr,
                            size: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          SizedBox(height: 8.h),
                          SmartText(
                            title: 'contact_us_desc'.tr,
                            size: 14.sp,
                            color: Colors.grey[700],
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 40.h), // Added significant bottom margin
                        ],
                      ),
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
