import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/core/widgets/secure_firebase_image.dart';
import 'controller/order_request_controller.dart';
import 'order_details_bottom_sheet.dart';
import 'package:quickserve/controllers/ad_controller.dart';
import 'package:quickserve/core/widgets/ad_widget.dart';
import 'package:quickserve/core/widgets/language_selector.dart';
import 'dart:async';
import 'dart:ui';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';


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
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: 100.h),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        child: Column(
                          children: [
                            // 🔍 Top Scanning Status (Premium Animated)
                            _buildSearchingHeader(controller),
                            
                            SizedBox(height: 10.h),

                            // 👥 Discover Your Next Customer (Hero Section)
                            _buildCustomerSlider(controller),
                            
                             SizedBox(height: 10.h),

                            // 📊 Market Insights Section (Top Growth Cities)
                            _buildMarketInsights(controller),
                            
                            SizedBox(height: 10.h),
                            
                            // 📡 Live Activity Feed
                            _buildLiveActivitySection(controller),
                          ],
                        ),
                      ),
                      // Ad Widget (placed at bottom)
                      _buildAdWidget(),
                    ],
                  ),
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
                                  backgroundColor: Colors.grey[200],
                                  child: ClipOval(
                                    child: request["profileImage"] != null &&
                                            request["profileImage"].isNotEmpty
                                        ? SecureFirebaseImage(
                                            pathOrUrl: request["profileImage"],
                                            fit: BoxFit.cover,
                                            width: 60.r,
                                            height: 60.r,
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 30.sp,
                                            color: Colors.grey,
                                          ),
                                  ),
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
                                        size: 14.sp,
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
                                            title: subText,
                                            size: 11.sp,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          );
                                        }),
                                      ),

                                      SizedBox(width: 8.w),

                                      Icon(
                                        Icons.event,
                                        size: 14.sp,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 4.w),

                                      Expanded(
                                        child: SmartText(
                                          title:
                                              request["requestType"] ?? "Now",
                                          size: 11.sp,
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

  Widget _buildSearchingHeader(OrdersController controller) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        children: [
          // Animated Searching Icon with Glow (Fixed size to prevent layout shifts)
          SizedBox(
            width: 80.r,
            height: 80.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _AnimatedPulse(color: AppColors.primary),
                Container(
                  width: 50.r,
                  height: 50.r,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.radar_rounded, color: Colors.white, size: 24.sp),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 20.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: SmartText(
                        title: "scanning_market".tr,
                        size: 17.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    const _DotLoader(),
                  ],
                ),
                SizedBox(height: 6.h),
                SmartText(
                  title: "currently_no_request_available".tr,
                  size: 11.5.sp,
                  color: Colors.grey[600],
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketInsights(OrdersController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
        border: Border.all(color: AppColors.primary.withOpacity(0.05), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Gradient Title
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: Icon(Icons.auto_graph_rounded, color: AppColors.primary, size: 24.sp),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SmartText(
                        title: "market_insights".tr,
                        size: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SmartText(
                        title: "live_demand_distribution".tr,
                        size: 11.sp,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                _buildLiveBadge(),
              ],
            ),
          ),

          // High-End Stats Row
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                _buildPremiumStatCard("service_demand".tr, "${controller.totalCustomersCount.value}+", Icons.trending_up_rounded, AppColors.primary),
                SizedBox(width: 10.w),
                _buildPremiumStatCard("city_outreach".tr, "${controller.cityDistribution.length}", Icons.public_rounded, AppColors.secondary),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // The Graph Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Row(
              children: [
                Container(
                  width: 4.w,
                  height: 16.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                SizedBox(width: 10.w),
                SmartText(
                  title: "top_growth_cities".tr,
                  size: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 25.h),
          
          // Enhanced Graph
          SizedBox(
            height: 220.h,
            child: Padding(
              padding: EdgeInsets.only(right: 25.w, left: 15.w, bottom: 20.h),
              child: Obx(() {
                if (controller.cityDistribution.isEmpty) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3));
                }

                final sortedCities = controller.cityDistribution.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));
                final topCities = sortedCities.take(5).toList();

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (topCities.map((e) => (e.value as num).toDouble()).reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => AppColors.primary,
                        tooltipRoundedRadius: 12,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${topCities[groupIndex].key}\n',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: '${rod.toY.toInt()} ' + "active_users".tr,
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 10.sp),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < topCities.length) {
                              return Padding(
                                padding: EdgeInsets.only(top: 12.h),
                                child: SmartText(
                                  title: topCities[index].key,
                                  size: 10.sp,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 35.h,
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(topCities.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: topCities[index].value.toDouble(),
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.primary.withOpacity(0.4)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            width: 22.w,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildPremiumStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18.sp),
            ),
            SizedBox(height: 15.h),
            SmartText(title: value, color: Colors.black87, size: 20.sp, fontWeight: FontWeight.bold),
            SmartText(title: label, color: Colors.grey[500], size: 10.sp, fontWeight: FontWeight.w600),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BlinkingDot(),
          SizedBox(width: 8.w),
          SmartText(title: "live_pulse".tr, color: Colors.green[700]!, size: 10.sp, fontWeight: FontWeight.bold),
        ],
      ),
    );
  }

  Widget _buildCustomerSlider(OrdersController controller) {
    return Obx(() {
      final customers = controller.recentActivity
          .where((a) => a['type'] == 'registration' && a['name'] != null)
          .toList();

      if (customers.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: SmartText(
              title: "discover_next_customer".tr,
              size: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 95.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: customers.length,
              itemBuilder: (context, index) {
                final customer = customers[index];
                final name = customer['name'] ?? 'User';
                final photoUrl = customer['profileImage'];

                return Container(
                  width: 75.w,
                  margin: EdgeInsets.only(right: 12.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
                        ),
                        child: CircleAvatar(
                          radius: 25.w,
                          backgroundColor: Colors.grey[200],
                          child: ClipOval(
                            child: photoUrl != null && photoUrl.toString().isNotEmpty
                              ? SecureFirebaseImage(
                                  pathOrUrl: photoUrl,
                                  fit: BoxFit.cover,
                                  width: 50.w,
                                  height: 50.w,
                                  )
                              : Icon(Icons.person, color: Colors.grey[400], size: 24.w),
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      SmartText(
                        title: name.split(' ')[0], // First name
                        size: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLiveActivitySection(OrdersController controller) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8.w),
                SmartText(
                  title: "live_activity".tr,
                  size: 14.sp,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                ),
                const Spacer(),
                SmartText(
                  title: "Market Pulse: Active",
                  size: 11.sp,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          Obx(() {
            if (controller.recentActivity.isEmpty) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      SizedBox(height: 10.h),
                      SmartText(title: "Analyzing market...", size: 12.sp, color: Colors.grey),
                    ],
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: controller.recentActivity.length > 5 ? 5 : controller.recentActivity.length,
              itemBuilder: (context, index) {
                return _buildActivityItem(controller.recentActivity[index]);
              },
            );
          }),
          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final type = activity['type'] ?? 'registration';
    final name = activity['name'] ?? 'Customer';
    final city = activity['city'] ?? 'Nearby';
    final timestamp = activity['timestamp'] as Timestamp?;
    final timeStr = timestamp != null 
        ? DateFormat('hh:mm a').format(timestamp.toDate())
        : '';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: type == 'system' 
                  ? [AppColors.secondary.withOpacity(0.2), AppColors.secondary.withOpacity(0.05)]
                  : [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.05)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              type == 'system' ? Icons.bolt_rounded : Icons.person_add_rounded,
              size: 20.sp,
              color: type == 'system' ? AppColors.secondary : AppColors.primary,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.black87, fontSize: 13.5.sp, fontFamily: 'Jameel'),
                    children: [
                      TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: type == 'system' ? ' ' : ' just registered from '),
                      TextSpan(
                        text: type == 'system' ? (activity['message'] ?? '') : city, 
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary.withOpacity(0.8))
                      ),
                    ],
                  ),
                ),
                if (timeStr.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 5.h),
                    child: SmartText(
                      title: timeStr,
                      size: 10.sp,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[300], size: 20.sp),
        ],
      ),
    );
  }
}

/// --- Helper Components for Redesign ---

class _AnimatedPulse extends StatefulWidget {
  final Color color;
  const _AnimatedPulse({required this.color});

  @override
  State<_AnimatedPulse> createState() => _AnimatedPulseState();
}

class _AnimatedPulseState extends State<_AnimatedPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Inner Pulse
        FadeTransition(
          opacity: ReverseAnimation(_controller),
          child: ScaleTransition(
            scale: Tween(begin: 1.0, end: 2.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.3),
              ),
            ),
          ),
        ),
        // Outer Pulse
        FadeTransition(
          opacity: ReverseAnimation(_controller),
          child: ScaleTransition(
            scale: Tween(begin: 1.0, end: 2.8).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOut),
            ),
            child: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color.withOpacity(0.2), width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotLoader extends StatefulWidget {
  const _DotLoader();

  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = IntTween(begin: 0, end: 3).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        String dots = '.' * (_animation.value + 1);
        return SmartText(title: dots, color: AppColors.primary, size: 16.sp, fontWeight: FontWeight.bold);
      },
    );
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
            height: 90.h,
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

class _BlinkingDot extends StatefulWidget {
  @override
  _BlinkingDotState createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8.r,
        height: 8.r,
        decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
      ),
    );
  }
}

String _limitWords(String text, int limit) {
  final words = text.trim().split(" ");

  if (words.length <= limit) return text;

  final limited = words.take(limit).join(" ");
  return "$limited...";
}
