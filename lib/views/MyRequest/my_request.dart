import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/views/MyRequest/my_request_controller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickserve/views/CustomerHome/widgets/home_page.dart';
import '../BottomNavbar/bottom_navbar.dart';
import 'package:quickserve/core/widgets/secure_firebase_image.dart';

class MyRequest extends StatelessWidget {
  const MyRequest({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MyRequestController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          /// 🎨 Custom Gradient Header
          Container(
            padding: EdgeInsets.only(bottom: 20.h),
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
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Get.offAll(() => const HomePage());
                        }
                      },
                    ),
                     Expanded(
                      child: Center(
                        child: SmartText(
                          title: 'completed_requests'.tr,
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
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (controller.completedRequests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 100.sp,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16.h),
                      SmartText(
                        title: 'no_completed_requests_yet'.tr,
                        size: 18.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      SizedBox(height: 8.h),
                      SmartText(
                        title: 'your_completed_service_requests_will_appear_here'.tr,
                        size: 14.sp,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshCompletedRequests,
                color: AppColors.primary,
                child: ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: controller.completedRequests.length,
                  itemBuilder: (context, index) {
                    final request = controller.completedRequests[index];
                    return _buildRequestCard(request, controller);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(
    Map<String, dynamic> request,
    MyRequestController controller,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: InkWell(
        onTap: () => _showRequestDetails(request, controller),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Info Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 30.r,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child: request['providerProfileImage'] != null &&
                              request['providerProfileImage'].isNotEmpty
                          ? SecureFirebaseImage(
                              pathOrUrl: request['providerProfileImage'],
                              fit: BoxFit.cover,
                              width: 60.r,
                              height: 60.r,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.person, color: Colors.grey),
                            )
                          : Icon(Icons.person, size: 30.sp, color: Colors.grey),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: SmartText(
                                title: request['providerName'] ?? '',
                                size: 16.sp,
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(Icons.verified, color: Colors.green, size: 16.sp),
                            SizedBox(width: 2.w),
                            SmartText(
                              title: "verified".tr,
                              color: Colors.green,
                              size: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Icon(
                              Icons.business_center,
                              size: 14.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: SmartText(
                                title: request['service'] ?? 'service'.tr,
                                size: 13.sp,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Request Type Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: request['requestType'] == 'Now'
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: SmartText(
                      title: request['requestType'] ?? 'now_request_type'.tr,
                      size: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: request['requestType'] == 'Now'
                          ? AppColors.primary.withOpacity(0.85)
                          : Colors.blue[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // Location
              Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.red, size: 16.sp),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: SmartText(
                      title: request['location'] ?? 'location_not_specified'.tr,
                      size: 13.sp,
                      color: Colors.grey[700],

                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              // Description
              SmartText(
                title: request['description'] ?? 'no_description'.tr,
                size: 13.sp,
                color: Colors.grey[600],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12.h),

              // Rating from Service Provider (if available)
              if (request['providerRating'] != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 16.sp,
                    ),
                    SizedBox(width: 4.w),
                    SmartText(
                      title: 'rating_label'.tr,
                      size: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                    SizedBox(width: 4.w),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < (request['providerRating'] ?? 0).round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber, // Using Amber for visibility as requested
                          size: 14.sp,
                        );
                      }),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],

              // Completed timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      SmartText(
                        title: 'completed'.tr,
                        size: 12.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                  SmartText(
                    title: controller.formatTimestamp(request['acceptedAt']),
                    size: 11.sp,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetails(
    Map<String, dynamic> request,
    MyRequestController controller,
  ) {
    // Find the request index to track updates
    final requestDocId = request['docId'];

    Get.bottomSheet(
      DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Obx(() {
            // Get updated request data from controller
            final updatedRequest = controller.completedRequests.firstWhere(
              (r) => r['docId'] == requestDocId,
              orElse: () => request,
            );
            // FIXED: Check if customer has rated the provider
            final bool hasRated = updatedRequest['customerRating'] != null;

            return Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: ListView(
                controller: scrollController,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Title
                  SmartText(
                    title: 'request_details'.tr,
                    size: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  SizedBox(height: 20.h),

                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 35.r,
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            child: updatedRequest['providerProfileImage'] != null &&
                                    updatedRequest['providerProfileImage']
                                        .isNotEmpty
                                ? SecureFirebaseImage(
                                    pathOrUrl: updatedRequest['providerProfileImage'],
                                    fit: BoxFit.cover,
                                    width: 70.r,
                                    height: 70.r,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const Icon(Icons.person, color: Colors.grey),
                                  )
                                : Icon(Icons.person, size: 35.sp, color: Colors.grey),
                          ),
                        ),

                        SizedBox(width: 12.w),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SmartText(
                                title:
                                    updatedRequest['providerName'] ??
                                    'Service Provider',
                                size: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              SizedBox(height: 4.h),
                              SmartText(
                                title: 'service_provider'.tr,
                                size: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),

                        // 📞 Call Icon
                        GestureDetector(
                          onTap: () =>
                              _openPhoneDialer(updatedRequest['providerPhone']),
                          child: Image.asset(
                            "assets/images/call_icon.png",
                            width: 32.r,
                            height: 32.r,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.call, color: Colors.green, size: 32.sp),
                          ),
                        ),

                        SizedBox(width: 10.w),

                        // WhatsApp Button
                        GestureDetector(
                          onTap: () async {
                            final phone = updatedRequest["providerPhone"];
                            if (phone != null && phone.isNotEmpty) {
                              final cleanPhone =
                                  phone.replaceAll(RegExp(r'\D'), '');
                              final whatsappUrl =
                                  Uri.parse("https://wa.me/$cleanPhone");
                              if (await canLaunchUrl(whatsappUrl)) {
                                await launchUrl(whatsappUrl,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                Get.snackbar(
                                    'Error', 'whatsapp_not_available'.tr);
                              }
                            }
                          },
                          child: Image.asset(
                            "assets/images/whatsapp_icon.png",
                            width: 32.r,
                            height: 32.r,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.chat, color: Colors.green, size: 32.sp),
                          ),
                        ),

                        SizedBox(width: 10.w),

                        // SMS Button
                        GestureDetector(
                          onTap: () async {
                            final phone = updatedRequest["providerPhone"];
                            if (phone != null && phone.isNotEmpty) {
                              final uri = Uri(scheme: 'sms', path: phone);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                Get.snackbar('Error', 'could_not_open_sms'.tr);
                              }
                            }
                          },
                          child: Image.asset(
                            "assets/images/sms_icon.png",
                            width: 32.r,
                            height: 32.r,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.message, color: Colors.blue, size: 32.sp),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Service Info
                  _buildDetailRow(
                    Icons.business_center,
                    'service'.tr,
                    updatedRequest['service'] ?? 'N/A',
                  ),
                  if (updatedRequest['subcategory'] != null)
                    Builder(builder: (context) {
                      String subText = "";
                      if (updatedRequest['subcategory'] is List) {
                        subText = (updatedRequest['subcategory'] as List).join(', ');
                      } else {
                        subText = updatedRequest['subcategory'].toString();
                      }
                      
                      if (subText.isEmpty) return const SizedBox.shrink();
                      
                      return _buildDetailRow(
                        Icons.category,
                        'subcategory'.tr,
                        subText,
                      );
                    }),
                  _buildDetailRow(
                    Icons.location_on,
                    'location'.tr,
                    updatedRequest['location'] ?? 'N/A',
                  ),
                  _buildDetailRow(
                    Icons.schedule,
                    'request_type'.tr,
                    updatedRequest['requestType'] ?? 'N/A',
                  ),
                  SizedBox(height: 16.h),
                  // Description
                  Text(
                    'description'.tr,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(12.w),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: SmartText(
                      title:
                          updatedRequest['description'] ??
                          'No description provided',
                      size: 13.sp,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Request Image if available
                  if (updatedRequest['imageUrl'] != null &&
                      updatedRequest['imageUrl'].isNotEmpty) ...[
                    SmartText(
                      title: 'request_image'.tr,
                      size: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: SecureFirebaseImage(
                        pathOrUrl: updatedRequest['imageUrl'],
                        height: 200.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200.h,
                          color: Colors.grey[100],
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200.h,
                          color: Colors.grey[100],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported, 
                                  size: 40.sp, color: Colors.grey),
                              SizedBox(height: 8.h),
                              Text("Image not available", 
                                  style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                  // Completion Info
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SmartText(
                                title: 'service_completed'.tr,
                                size: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                              SizedBox(height: 4.h),
                              SmartText(
                                title:
                                    '${"completed_on".tr}: ${controller.formatTimestamp(updatedRequest["acceptedAt"])}',
                                size: 12.sp,
                                color: Colors.grey[700],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Show Rating FROM Service Provider (if available)
                  if (updatedRequest['providerRating'] != null) ...[
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.blue,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              SmartText(
                                title: 'rating_from_provider'.tr, // "Rating from Service Provider"
                                size: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < (updatedRequest['providerRating'] ?? 0).round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.blue,
                                size: 24.sp,
                              );
                            }),
                          ),
                          if (updatedRequest['providerReview'] != null &&
                              updatedRequest['providerReview'].isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            SmartText(
                              title: 'Review:',
                              size: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                            SizedBox(height: 4.h),
                            SmartText(
                              title: updatedRequest['providerReview'],
                              size: 13.sp,
                              color: Colors.grey[700],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Show rating if already rated (My Rating)
                  if (hasRated) ...[
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              SmartText(
                                title: 'your_rating'.tr,
                                size: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < (updatedRequest['customerRating'] ?? 0).round()
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 24.sp,
                              );
                            }),
                          ),
                          // FIXED: Check and display customerReview
                          if (updatedRequest['customerReview'] != null &&
                              updatedRequest['customerReview'].isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            SmartText(
                              title: 'Review:',
                              size: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                            SizedBox(height: 4.h),
                            SmartText(
                              title: updatedRequest['customerReview'],
                              size: 13.sp,
                              color: Colors.grey[700],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],

                  // Rate Provider Button (only if not rated yet)
                  if (!hasRated)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          print("Rate button tapped"); // 🔹 Add this

                          _showRatingBottomSheet(context, updatedRequest, controller);
                        },
                        icon: Icon(Icons.star, size: 20.sp),
                        label: SmartText(
                          title: 'rate_service_provider'.tr,
                          size: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ),
                  if (!hasRated) SizedBox(height: 12.h),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: SmartText(
                        title: 'close'.tr,
                        size: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        },
      ),
      isScrollControlled: true,
    );
  }

  void _showRatingBottomSheet(
    BuildContext context,
    Map<String, dynamic> request,
    MyRequestController controller,
  ) {
    final RxInt selectedRating = 0.obs;
    final TextEditingController reviewController = TextEditingController();

    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Title and Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SmartText(
                        title: 'rate_service_provider'.tr,
                        size: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                     GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, color: Colors.grey[700], size: 20.sp),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8.h),
                SmartText(
                  title:
                      '${'how_was_your_experience'.tr} ${request['providerName']}',
                  size: 14.sp,
                  color: Colors.grey[600],
                ),
                SizedBox(height: 24.h),

                // Star Rating
                Center(
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () => selectedRating.value = index + 1,
                          child: Icon(
                            index < selectedRating.value
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 40.sp,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Review TextField
                SmartText(
                  title: 'add_a_review_optional'.tr,
                  size: 14.sp,
                  fontWeight: FontWeight.bold,
                ),

                SizedBox(height: 8.h),
                TextField(
                  controller: reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hint: SmartText(
                      title: 'share_your_experience'.tr,
                      size: 14.sp,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // Submit Button
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isSubmittingRating.value
                          ? null
                          : () {
                              if (selectedRating.value == 0) {
                                Get.snackbar(
                                  'required'.tr,
                                  'please_select_a_rating'.tr,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }

                              controller.submitProviderRating(
                                requestDocId: request['docId'],
                                providerId: request['providerId'],
                                rating: selectedRating.value,
                                review: reviewController.text.trim(),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: controller.isSubmittingRating.value
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : SmartText(
                              title: 'submit_rating'.tr,
                              size: 16.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                SizedBox(height: 2.h),
                SmartText(
                  title: value,
                  size: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openPhoneDialer(String phone) async {
  final uri = Uri(scheme: "tel", path: phone);
  await launchUrl(uri);
}

Future<void> _handleMessage(String phone) async {
  final whatsappUrl = Uri.parse("whatsapp://send?phone=$phone&text=Hello");
  final smsUrl = Uri(scheme: 'sms', path: phone);

  // Try WhatsApp first
  if (await canLaunchUrl(whatsappUrl)) {
    await launchUrl(whatsappUrl);
  } else {
    await launchUrl(smsUrl);
  }
}
