import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/views/OrdersList/orders_list.dart';
import 'package:quickserve/views/Profile/ServiceProviderProfile/provider_profile_page.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../CompleteRequests/complete_request.dart';
import 'package:quickserve/views/OrdersList/controller/order_request_controller.dart'; // Import OrdersController
import 'dart:io' show exit;

class BottomNavbar extends StatefulWidget {
  final int initialIndex;
  const BottomNavbar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavbar> createState() => _BottomNavbarState();
}

class _BottomNavbarState extends State<BottomNavbar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = Get.arguments?['index'] ?? widget.initialIndex;
    print('🏗️ BottomNavbar initialized with index: $_selectedIndex');
    // Initialize OrdersController immediately to start listening for requests
    // and ensure it stays alive even when switching tabs.
    Get.put(OrdersController(), permanent: true);
  }

  final List<Widget> _pages = [
    OrdersList(),
    CompleteRequest(),
    ProviderProfilePage(),
  ];

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      // Go to index 0 instead of exiting
      setState(() {
        _selectedIndex = 0;
      });
      return false; // Prevent default back action
    } else {
      // Already on index 0 → show exit dialog
      bool shouldExit = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: SmartText(title: "exit_app_title".tr),
          content: SmartText(title: "exit_app_content".tr),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: SmartText(title: "no".tr),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: SmartText(title: "yes".tr),
            ),
          ],
        ),
      );

      if (shouldExit) {
        // Exit the app (Mobile only)
        if (!kIsWeb) {
          exit(0);
        }
      }
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.1)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 8.h),
              child: GNav(
                rippleColor: Colors.blue.shade100,
                hoverColor: Colors.blue.shade50,
                gap: 8,
                activeColor: Colors.white,
                iconSize: 24.sp,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                duration: const Duration(milliseconds: 400),
                tabBackgroundColor: AppColors.primary,
                color: AppColors.primary,
                selectedIndex: _selectedIndex,
                onTabChange: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                  
                  // Refresh requests when switching to Orders tab (Index 0)
                  if (index == 0) {
                    final controller = Get.find<OrdersController>();
                    controller.refreshRequests();
                  }
                },
                tabs: [
                  GButton(
                    icon: Icons.shopping_bag_outlined,
                    text: 'bottom_nav_orders'.tr,
                  ),
                  GButton(
                    icon: Icons.account_balance_wallet_outlined,
                    text: 'bottom_nav_requests'.tr,
                  ),
                  GButton(
                    icon: Icons.settings_outlined,
                    text: 'bottom_nav_settings'.tr,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
