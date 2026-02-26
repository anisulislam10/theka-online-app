import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';

Widget documentPickerTile({
  required String title,
  required Rx<File?> file,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Obx(() {
      final hasImage =
          file.value != null &&
          [
            'jpg',
            'jpeg',
            'png',
            'gif',
          ].contains(file.value!.path.split('.').last.toLowerCase());

      return Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: const Color.fromARGB(15, 128, 0, 128),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.primary, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Icon(Icons.upload_file, color: AppColors.primary, size: 28.sp),
              ],
            ),

            // Image preview (only if exists)
            if (hasImage)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Image.file(
                    file.value!,
                    width: double.infinity,
                    height: 180.h,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      );
    }),
  );
}
