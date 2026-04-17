import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:quickserve/core/widgets/secure_firebase_image.dart';
import 'controller/order_request_controller.dart';

class OrderDetailsBottomSheet {
  static void show(BuildContext context, Map<String, dynamic> request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _OrderDetailsBottomSheetContent(request: request),
      ),
    );
  }
}

class _OrderDetailsBottomSheetContent extends StatefulWidget {
  final Map<String, dynamic> request;

  const _OrderDetailsBottomSheetContent({required this.request});

  @override
  State<_OrderDetailsBottomSheetContent> createState() =>
      __OrderDetailsBottomSheetContentState();
}

class __OrderDetailsBottomSheetContentState
    extends State<_OrderDetailsBottomSheetContent> {
  // Get controller instance
  final OrdersController controller = Get.find<OrdersController>();

  /// Handle accept button press
  Future<void> handleAccept() async {
    final success = await controller.acceptRequest(request: widget.request);

    if (success && mounted) {
      Navigator.pop(context); // Close bottom sheet
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.all(16.w),
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
              SizedBox(height: 16.h),

              // Customer Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 35.r,
                    backgroundColor: Colors.grey[200],
                    child: ClipOval(
                      child: widget.request["profileImage"] != null &&
                              widget.request["profileImage"].isNotEmpty
                          ? SecureFirebaseImage(
                              pathOrUrl: widget.request["profileImage"],
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
                          title: widget.request["userName"] ?? "Unknown User",
                          size: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16.sp),
                            SizedBox(width: 4.w),
                            Text(
                              "${(widget.request["userRating"] ?? 0.0).round()} (${widget.request["totalRatings"] ?? 0} reviews)",
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        SmartText(
                          title:
                              "Need ${widget.request["service"] ?? "Service"}",
                          size: 14.sp,
                          color: Colors.grey[700],
                        ),
                        if (widget.request["subcategory"] != null)
                          Builder(builder: (context) {
                            String subText = "";
                            if (widget.request['subcategory'] is List) {
                              subText = (widget.request['subcategory'] as List).join(', ');
                            } else {
                              subText = widget.request['subcategory'].toString();
                            }
                            
                            if (subText.isEmpty) return const SizedBox.shrink();
                            
                            return SmartText(
                              title: subText,
                              size: 12.sp,
                              color: Colors.grey[600],
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Description Container
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Request Type Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: widget.request["requestType"] == "Now"
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        widget.request["requestType"] ?? "Now",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: widget.request["requestType"] == "Now"
                              ? AppColors.primary.withOpacity(0.85)
                              : Colors.blue[700],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SmartText(
                      title: "PKR ${widget.request["price"] ?? "0"}",
                      size: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Text(widget.request["userPhone"]),
                        Spacer(),

                        // 📞 Call
                        GestureDetector(
                          onTap: () =>
                              _openPhoneDialer(widget.request["userPhone"]),
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
                            final phone = widget.request["userPhone"];
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

                        // 📩 SMS
                        GestureDetector(
                          onTap: () => _openSMS(widget.request["userPhone"]),
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

                    // Location
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppColors.red,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: SmartText(
                            title:
                                widget.request["location"] ??
                                "Location not specified",
                            size: 13.sp,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),

                    // Description
                    SmartText(
                      title: "description_label".tr,
                      size: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 6.h),
                    SmartText(
                      title:
                          widget.request["description"] ??
                          "no_description_provided".tr,
                      size: 13.sp,
                    ),

                    // Show request image if available
                    if (widget.request["imageUrl"] != null &&
                        widget.request["imageUrl"].isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: SecureFirebaseImage(
                          pathOrUrl: widget.request["imageUrl"],
                          height: 160.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 160.h,
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 160.h,
                            width: double.infinity,
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
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16.h),

              // Action Buttons
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.isAcceptingRequest.value
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: SmartText(
                          title: "skip".tr,
                          size: 15.sp,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: controller.isAcceptingRequest.value
                            ? null
                            : handleAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: controller.isAcceptingRequest.value
                            ? SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : SmartText(
                                title: "accept_request".tr,
                                size: 15.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }
}

Widget _circleIcon(IconData icon, Color color) {
  return Container(
    height: 40.h,
    width: 40.w,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    child: Icon(icon, size: 20.sp, color: Colors.white),
  );
}

Future<void> _openPhoneDialer(String phone) async {
  final Uri url = Uri(scheme: 'tel', path: phone);
  await launchUrl(url);
}

Future<void> _openSMS(String phone) async {
  final Uri url = Uri(scheme: 'sms', path: phone);
  await launchUrl(url);
}
