import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/core/services/translation_service.dart';
import 'package:quickserve/core/widgets/custom_button.dart';
import 'package:quickserve/core/widgets/city_drop_down.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:quickserve/core/widgets/language_selector.dart';
import 'service_provider_register_controller.dart';


class DocumentsUploadPage extends StatelessWidget {
  const DocumentsUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ServiceProviderRegisterController>()
        ? Get.find<ServiceProviderRegisterController>()
        : Get.put(ServiceProviderRegisterController());

    // Fetch data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ Retrieve arguments passed from Provider Register Page
      if (Get.arguments != null && Get.arguments is Map) {
        final args = Get.arguments as Map<String, dynamic>;
        if (args.containsKey('name')) controller.savedName.value = args['name'];
        if (args.containsKey('email')) controller.savedEmail.value = args['email'];
        if (args.containsKey('phone')) controller.savedPhone.value = args['phone'];
        if (args.containsKey('password')) controller.savedPassword.value = args['password'];
        if (args.containsKey('city')) controller.selectedCity.value = args['city'];
        
        debugPrint("📥 Received Arguments in Documents Page:");
        debugPrint("   Name: ${controller.savedName.value}");
        debugPrint("   Phone: ${controller.savedPhone.value}");
        
        // Also update the UI text controllers if they are empty
        if (controller.nameController.text.isEmpty) controller.nameController.text = controller.savedName.value;
        if (controller.emailController.text.isEmpty) controller.emailController.text = controller.savedEmail.value;
      }

      // Only fetch if categories are empty (avoid duplicate fetches)
      if (controller.skilledCategories.isEmpty &&
          controller.unskilledCategories.isEmpty) {
        controller.fetchServiceCategories(context);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: Text(
          "complete_profile".tr,
          style: TextStyle(color: AppColors.white, fontSize: 18.sp),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: LanguageSelector(
              iconColor: AppColors.white,
            ),
          ),
        ],
      ),

      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),

                // Welcome message with user info
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ], // Professional Gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Profile image
                      Container(
                        padding: EdgeInsets.all(2.w), // Border width
                        decoration: BoxDecoration(
                          color: Colors.white, // Border color
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          width: 60.r,
                          height: 60.r,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(
                            child: controller.currentUserPhotoUrl.value.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: controller.currentUserPhotoUrl.value,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) => const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Icon(Icons.person, size: 30.sp, color: Colors.grey),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SmartText(
                              title: "welcome".tr,
                              size: 14.sp,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            SizedBox(height: 4.h),
                            SmartText(
                              title: controller.currentUserName.value,
                              size: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Service Type Selection
                SmartText(
                  title: "select_service_type".tr,
                  size: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: 8.h),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => RadioListTile<String>(
                            title: SmartText(
                              title: 'skilled'.tr,
                              color: AppColors.black,
                              size: 14.sp,
                            ),
                            value: 'Skilled',
                            groupValue: controller.selectedType.value,
                            onChanged: (val) {
                              controller.selectedType.value = val!;
                              controller.selectedCategory.value = '';
                              controller.selectedSubcategories.clear();
                            },
                            activeColor: AppColors.primary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Obx(
                          () => RadioListTile<String>(
                            title: SmartText(
                              title: 'helper'.tr,
                              color: AppColors.black,
                              size: 14.sp,
                            ),
                            value: 'Unskilled',
                            groupValue: controller.selectedType.value,
                            onChanged: (val) {
                              controller.selectedType.value = val!;
                              controller.selectedCategory.value = '';
                              controller.selectedSubcategories.clear();
                            },
                            activeColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // Category Selection
                if (controller.selectedType.isNotEmpty)
                  Obx(() {
                    final categories = controller.getCurrentCategoryList();

                    if (categories.isEmpty) {
                      return Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Text(
                                'No categories available',
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SmartText(
                          title: "select_profession".tr,
                          size: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        SizedBox(height: 8.h),
                        Obx(() {
                          return DropdownButtonFormField<String>(
                            value:
                                controller.selectedCategory.value.isEmpty
                                ? null
                                : controller.selectedCategory.value,
                            hint: SmartText(title: 'select_profession'.tr),
                            isExpanded: true,
                            items: categories
                                .map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.selectCategory(value);
                              }
                            },
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),

                SizedBox(height: 20.h),

                // Subcategories (Skills) Selection
                Obx(() {
                  if (controller.selectedCategory.value.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final subcats = controller.availableSubcategories;

                  if (subcats.isEmpty) {
                    return Container();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SmartText(
                            title: "select_skills".tr,
                            size: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: SmartText(
                                title: 'select_at_least_3_skills'.tr,
                                size: 12.sp,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: subcats.map((subcat) {
                            return Obx(() {
                              final isSelected = controller
                                  .selectedSubcategories
                                  .contains(subcat);
                              return Column(
                                children: [
                                  CheckboxListTile(
                                    title: Text(
                                      subcat,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.black,
                                      ),
                                    ),
                                    value: isSelected,
                                    onChanged: (value) {
                                      controller.toggleSubcategory(subcat);
                                    },
                                    activeColor: AppColors.primary,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                  ),
                                  if (subcat != subcats.last)
                                    const Divider(height: 1, thickness: 1),
                                ],
                              );
                            });
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                }),

                SizedBox(height: 20.h),

                // Document Section
                SmartText(
                  title: "upload_documents".tr,
                  size: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),

                SizedBox(height: 16.h),

                // ID Front
                _buildDocumentPickerTile(
                  title: "government_id_front".tr,
                  file: controller.cnicFront,
                  onTap: () =>
                      controller.pickDocumentWithOptions(controller.cnicFront),
                ),

                SizedBox(height: 12.h),

                // ID Back
                _buildDocumentPickerTile(
                  title: "government_id_back".tr,
                  file: controller.cnicBack,
                  onTap: () =>
                      controller.pickDocumentWithOptions(controller.cnicBack),
                ),

                SizedBox(height: 30.h),

                CustomButton(
                  text: "submit".tr,
                  onPressed: () async {
                    await controller.submitRegistration(context);
                  },
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        );
      }),
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
                        SmartText(
                          title: title,
                          size: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        SizedBox(height: 4.h),
                        SmartText(
                          title: isSelected
                              ? selectedFile.path.split('/').last
                              : 'tap_to_upload'.tr,
                          size: 12.sp,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade600,

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
