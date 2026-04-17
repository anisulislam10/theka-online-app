import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/core/services/translation_service.dart';

class LanguageSelector extends StatelessWidget {
  final Color? iconColor;
  final Color? backgroundColor;

  const LanguageSelector({
    super.key,
    this.iconColor = Colors.white,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: Offset(0, 45.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.r),
      ),
      elevation: 4,
      onSelected: (String langCode) {
        TranslationService.changeLocale(langCode);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              Icon(Icons.language, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 10.w),
              const SmartText(
                title: "English",
                size: 14,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'ur',
          child: Row(
            children: [
              Icon(Icons.language, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 10.w),
              const SmartText(
                title: "اردو",
                size: 14,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, color: iconColor, size: 20.sp),
            SizedBox(width: 5.w),
            SmartText(
              title: Get.locale?.languageCode.toUpperCase() ?? "EN",
              color: iconColor,
              size: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ],
        ),
      ),
    );
  }
}
