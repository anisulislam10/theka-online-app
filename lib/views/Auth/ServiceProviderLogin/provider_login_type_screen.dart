import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/views/Auth/ServiceProviderLogin/service_provider_login_page.dart';

class ProviderLoginTypeScreen extends StatelessWidget {
  const ProviderLoginTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Login As",
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 30.h),
                Text(
                  "Choose your preferred login method for Service Provider",
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40.h),

                // Login with Email Button (Active)
                ElevatedButton.icon(
                  onPressed: () => Get.to(() => ServiceProviderLoginPage()),
                  icon: Icon(Icons.email_outlined, color: Colors.white),
                  label: Text(
                    "Login with Email",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: Size(double.infinity, 50.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                    elevation: 5,
                  ),
                ),
                SizedBox(height: 20.h),

                // Login with Phone Button (Disabled)
                Opacity(
                  opacity: 0.5,
                  child: Stack(
                    children: [
                      OutlinedButton.icon(
                        onPressed: null, // Disabled
                        icon: Icon(
                          Icons.phone_outlined,
                          color: Colors.grey[400],
                        ),
                        label: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Login with Phone",
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[400],
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: Colors.orange[300]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                "Coming Soon",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50.h),
                          side: BorderSide(color: Colors.grey[300]!, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          disabledForegroundColor: Colors.grey[400],
                          disabledBackgroundColor: Colors.grey[50],
                        ),
                      ),
                    ],
                  ),
                ),
/*
                SizedBox(height: 15.h),

                // Info Badge for Phone Login
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: Colors.blue[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16.sp,
                        color: Colors.blue[700],
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          "Phone login will be available in the next update",
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.blue[900],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),*/

                SizedBox(height: 20.h),

                // Note
                Text(
                  "For now, please use email login to access your account",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}