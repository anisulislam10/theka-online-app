import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickserve/core/constants/appAssets.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class CustomGoogleButton extends StatelessWidget {
  final bool isLoading;
  final String text;
  final VoidCallback onPressed;

  const CustomGoogleButton({
    super.key,
    required this.isLoading,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 2,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGoogleIcon(),
            SizedBox(width: 12.w),
            isLoading
                ? SizedBox(
                    height: 20.h,
                    width: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black87,
                    ),
                  )
                : SmartText(
                    title: text,
                    color: Colors.black87,
                    size: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return Image.asset(
      AppImages.google,
      height: 24.h,
      width: 24.w,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(Icons.error, size: 24.sp),
    );
  }
}
