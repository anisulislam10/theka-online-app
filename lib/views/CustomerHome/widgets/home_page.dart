import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/core/widgets/custom_drawer.dart';
import 'package:quickserve/core/services/translation_service.dart';
import 'package:quickserve/views/CustomerHome/controllers/maps_controller.dart';
import 'package:quickserve/views/CustomerHome/widgets/home_bottom_sheet.dart';
import 'package:quickserve/core/widgets/language_selector.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapControllerX mapController = Get.put(MapControllerX());

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool exit = await _showExitDialog();
        return exit;
      },
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.white,
          drawer: CustomDrawer(onSwitchMode: () {}),

          body: Stack(
            children: [
              /// 🌍 Google Map Background
              Obx(
                () => GoogleMap(
                  // 🔹 Added top padding so map content isn't hidden by header
                  padding: EdgeInsets.only(top: 130.h, bottom: 300.h), 
                  initialCameraPosition: CameraPosition(
                    target: mapController.currentLocation.value,
                    zoom: 14,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    mapController.mapController = controller;
                  },
                  onTap: (latLng) {
                    // Instantly move center pin to tapped location
                    mapController.updateLocation(latLng, zoom: 14);
                  },
                  onCameraMove: (position) {
                    // Update current location as user drags
                    mapController.currentLocation.value = position.target;
                  },
                  onCameraIdle: () {
                    // Fetch address when user stops dragging
                    mapController.onCameraIdle(mapController.currentLocation.value);
                  },
                  // markers: {
                  //   Marker(
                  //     markerId: const MarkerId('current'),
                  //     position: mapController.currentLocation.value,
                  //     icon: BitmapDescriptor.defaultMarkerWithHue(
                  //       BitmapDescriptor.hueRed,
                  //     ),
                  //     infoWindow: const InfoWindow(title: 'You are here'),
                  //   ),
                  // },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),

              /// 📍 Central Pin Icon (Fallback for location selection)
              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 200.h), // Offset to put tip of pin in center
                  child: Icon(
                    Icons.location_on,
                    color: AppColors.primary,
                    size: 45.sp,
                  ),
                ),
              ),

              /// 🎨 Custom Gradient Header
              /// 🎨 Custom Gradient Header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  // 🔹 Removed fixed height to allow dynamic sizing based on SafeArea
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
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
                    bottom: false, // Only care about top status bar
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 10.h), // Add a bit of breathing room at bottom
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Menu Button
                          Builder(builder: (context) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white),
                                onPressed: () => Scaffold.of(context).openDrawer(),
                              ),
                            );
                          }),
                          
                          // Title
                          Expanded(
                            child: Center(
                              child: SmartText(
                                title: 'request_a_service'.tr,
                                size: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Language Button
                          const LanguageSelector(),

                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// 🎯 Recenter Button
              Positioned(
                bottom: 350.h,
                right: 20.w,
                child: FloatingActionButton(
                  heroTag: "recenterBtn",
                  onPressed: mapController.recenterMap,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.blue),
                ),
              ),

              HomeBottomSheet(),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitDialog() async {
    return await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: SmartText(title: 'exit_app'.tr),
              content: SmartText(title: 'are_you_sure_you_want_to_exit?'.tr),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: SmartText(title: 'no'.tr),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: SmartText(title: 'yes'.tr),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
