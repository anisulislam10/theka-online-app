import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'controller/order_request_controller.dart';
import 'order_details_bottom_sheet.dart';
import 'package:quickserve/controllers/ad_controller.dart';
import 'package:quickserve/core/widgets/ad_widget.dart';
import 'package:quickserve/core/widgets/language_selector.dart';
import 'dart:async';
import 'package:dots_indicator/dots_indicator.dart';


class OrdersList extends StatelessWidget {
  const OrdersList({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the permanent controller instance created in BottomNavbar
    final OrdersController controller = Get.find<OrdersController>();

    return Scaffold(
      backgroundColor: AppColors.white,
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Online/Offline Toggle (Centered)
                    Obx(
                      () => GestureDetector(
                        onTap: controller.toggleOnlineStatus,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 180.w,
                          height: 45.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                alignment: controller.isOnline.value
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  width: 100.w,
                                  height: 45.h,
                                  decoration: BoxDecoration(
                                    color: controller.isOnline.value
                                        ? AppColors.green
                                        : AppColors.red,
                                    borderRadius: BorderRadius.circular(30.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 5,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: SmartText(
                                    title: controller.isOnline.value
                                        ? "online".tr
                                        : "offline".tr,
                                    color: AppColors.white,
                                    size: 15.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Language Button (Right)
                    const Align(
                      alignment: Alignment.centerRight,
                      child: LanguageSelector(),
                    ),

                  ],
                ),
              ),
            ),
          ),
          // Tabs Section (Now | Anytime)
          Container(
            color: Colors.white,
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.changeTab(0),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: controller.selectedTab.value == 0
                                  ? AppColors.primary
                                  : Colors.grey[400]!,
                              width: 3.h,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: SmartText(
                          title:
                              "${'now_request_type'.tr} (${controller.nowRequests.length})",
                          size: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: controller.selectedTab.value == 0
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.changeTab(1),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: controller.selectedTab.value == 1
                                  ? AppColors.primary
                                  : Colors.grey[400]!,
                              width: 3.h,
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: SmartText(
                          title:
                              "${'anytime_request_type'.tr} (${controller.anytimeRequests.length})",
                          size: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: controller.selectedTab.value == 1
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // List of Requests
          Expanded(
            child: Obx(() {
              if (controller.isLoadingNow.value || controller.isLoadingAnytime.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredRequests = controller.filteredRequests;

              if (filteredRequests.isEmpty) {
                return ListView(
                  padding: EdgeInsets.only(top: 10.h, left: 4.w, right: 4.w, bottom: 20.h),
                  children: [
                    _buildAdWidget(),
                    SizedBox(height: 50.h),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 80.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16.h),
                          SmartText(
                            title: "no_requests_available".tr,
                            size: 16.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: EdgeInsets.only(top: 10.h, left: 4.w, right: 4.w, bottom: 20.h),
                itemCount: filteredRequests.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildAdWidget();
                  }

                  final request = filteredRequests[index - 1];
                  return GestureDetector(
                    onTap: () {
                      // Check if user is online before opening bottom sheet
                      if (controller.isOnline.value) {
                        OrderDetailsBottomSheet.show(context, request);
                      } else {
                        // Show a message that user needs to be online
                        Get.snackbar(
                          "snackbar_offline_title".tr,
                          "snackbar_offline_message".tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.withOpacity(0.8),
                          colorText: Colors.white,
                          margin: EdgeInsets.all(16.w),
                          borderRadius: 8.r,
                          duration: const Duration(seconds: 2),
                        );
                      }
                    },
                    child: Card(
                      margin: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Image + Name
                            Column(
                              children: [
                                CircleAvatar(
                                  radius: 30.r,
                                  backgroundImage:
                                      request["profileImage"] != null &&
                                              request["profileImage"].isNotEmpty
                                          ? NetworkImage(request["profileImage"])
                                          : null,
                                  child:
                                      request["profileImage"] == null ||
                                              request["profileImage"].isEmpty
                                          ? Icon(
                                              Icons.person,
                                              size: 30.sp,
                                              color: Colors.grey,
                                            )
                                          : null,
                                ),
                                SizedBox(height: 6.h),
                                SizedBox(
                                  width: 70.w,
                                  child: SmartText(
                                    title: request["userName"] ?? "user_default".tr,
                                    size: 11.sp,
                                    fontWeight: FontWeight.bold,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 12.sp),
                                    SizedBox(width: 2.w),
                                    Text(
                                      (request["userRating"] ?? 0.0).round().toString(),
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(width: 12.w),

                            // Info Section
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Title + Price
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: SmartText(
                                          title:
                                              "${"need".tr} ${request["service"] ?? "Service"}",
                                          size: 16.sp,
                                          fontWeight: FontWeight.bold,

                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SmartText(
                                        title: "PKR ${request["price"] ?? "0"}",
                                        size: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  SmartText(
                                    title:
                                        request["location"] ??
                                        "location_not_specified".tr,
                                    color: Colors.grey[700],
                                    size: 12.sp,

                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6.h),
                                  SmartText(
                                    title: _limitWords(
                                      request["description"] ??
                                          "no_description".tr,
                                      20,
                                    ),
                                    size: 13.sp,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 8.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.category,
                                        size: 16.sp,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 4.w),

                                      Expanded(
                                        child: Builder(builder: (context) {
                                          String subText = "";
                                          if (request['subcategory'] is List) {
                                            subText = (request['subcategory'] as List)
                                                .join(', ');
                                          } else {
                                            subText = request['subcategory']
                                                    ?.toString() ??
                                                "general_category".tr;
                                          }
                                          return SmartText(
                                            title: _limitWords(subText, 15),
                                            size: 12.sp,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }),
                                      ),

                                      SizedBox(width: 8.w),

                                      Icon(
                                        Icons.event,
                                        size: 16.sp,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 4.w),

                                      Expanded(
                                        child: SmartText(
                                          title:
                                              request["requestType"] ?? "Now",
                                          size: 12.sp,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAdWidget() {
    return _AdSliderWidget();
  }
}

class _AdSliderWidget extends StatefulWidget {
  @override
  State<_AdSliderWidget> createState() => _AdSliderWidgetState();
}

class _AdSliderWidgetState extends State<_AdSliderWidget> {
  final PageController _pageController = PageController();
  final RxInt _currentIndex = 0.obs;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final adController = Get.find<AdController>();
      final ads = adController.ads.where(
        (a) => a.position == 'mobile' || a.position == 'provider',
      ).toList();

      if (ads.length > 1) {
        int nextIndex = (_currentIndex.value + 1) % ads.length;
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final adController = Get.isRegistered<AdController>()
          ? Get.find<AdController>()
          : Get.put(AdController());

      final ads = adController.ads.where(
        (a) => a.position == 'mobile' || a.position == 'provider',
      ).toList();

      if (ads.isEmpty) return const SizedBox.shrink();

      if (ads.length == 1) {
        return AdWidget(ad: ads.first, isSmall: true);
      }

      return Column(
        children: [
          SizedBox(
            height: 90.h, // Increased slightly for safety
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => _currentIndex.value = index,
              itemCount: ads.length,
              itemBuilder: (context, index) {
                return AdWidget(
                  ad: ads[index], 
                  isSmall: true,
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                );
              },
            ),
          ),
          SizedBox(height: 6.h),
          Obx(() => DotsIndicator(
            dotsCount: ads.length,
            position: _currentIndex.value.toDouble(),
            decorator: DotsDecorator(
              size: Size.square(5.0.r),
              activeSize: Size(10.0.r, 5.0.r),
              activeColor: AppColors.primary,
              color: AppColors.grey.withOpacity(0.3),
              activeShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0.r),
              ),
            ),
          )),
          SizedBox(height: 8.h),
        ],
      );
    });
  }
}

String _limitWords(String text, int limit) {
  final words = text.trim().split(" ");

  if (words.length <= limit) return text;

  final limited = words.take(limit).join(" ");
  return "$limited...";
}
