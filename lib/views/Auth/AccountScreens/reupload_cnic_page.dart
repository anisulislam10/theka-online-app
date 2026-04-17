import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'reupload_cnic_controller.dart';

class ReuploadCnicPage extends StatelessWidget {
  ReuploadCnicPage({super.key});

  final controller = Get.put(ReuploadCnicController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          "reupload_documents".tr,
          style: TextStyle(color: AppColors.white, fontSize: 18.sp),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Text(
              "reupload_cnic_instructions".tr,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 20.h),

            // ID Front
            _buildDocumentPickerTile(
              title: "government_id_front".tr,
              file: controller.cnicFront,
              onTap: () =>
                  controller.pickDocumentWithOptions(context, controller.cnicFront),
            ),

            SizedBox(height: 12.h),

            // ID Back
            _buildDocumentPickerTile(
              title: "government_id_back".tr,
              file: controller.cnicBack,
              onTap: () =>
                  controller.pickDocumentWithOptions(context, controller.cnicBack),
            ),

            SizedBox(height: 30.h),

            CustomButton(
              text: "submit".tr,
              onPressed: () async {
                await controller.submitNewCnic(context);
              },
            ),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  // Helper widget for document picker tile
  Widget _buildDocumentPickerTile({
    required String title,
    required Rx<XFile?> file,
    required VoidCallback onTap,
  }) {
    return Obx(() {
      final selectedFile = file.value;
      final isSelected = selectedFile != null;
      final isImage =
          isSelected &&
          (selectedFile.path.endsWith('.jpg') ||
              selectedFile.path.endsWith('.jpeg') ||
              selectedFile.path.endsWith('.png') ||
              selectedFile.path.endsWith('.heic'));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : Colors.grey.shade50,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isSelected ? Icons.check_circle : Icons.upload_file,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          isSelected
                              ? selectedFile.path.split('/').last
                              : 'tap_to_upload'.tr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isSelected
                                ? AppColors.primary
                                : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),

          // Show Image Preview if File Selected and is an Image
          if (isSelected && isImage) ...[
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(selectedFile.path),
                width: double.infinity,
                height: 180.h,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180.h,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 40.sp, color: Colors.grey),
                      SizedBox(height: 8.h),
                      Text("Image preview not available",
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12.sp)),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Show a generic file preview if not an image
          if (isSelected && !isImage) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(12.w),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file, color: AppColors.primary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      selectedFile.path.split('/').last,
                      style: TextStyle(fontSize: 13.sp, color: AppColors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: 16.h),
        ],
      );
    });
  }
}
