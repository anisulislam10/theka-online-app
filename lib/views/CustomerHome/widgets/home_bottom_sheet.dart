import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickserve/core/constants/api_key.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/core/widgets/custom_button.dart';
import 'package:quickserve/views/CustomerHome/controllers/home_bottom_sheet_controller.dart';
import 'package:quickserve/views/CustomerHome/controllers/maps_controller.dart';
import 'package:quickserve/controllers/ad_controller.dart';
import 'package:quickserve/core/widgets/ad_widget.dart';
import 'package:quickserve/core/utils/category_seeder.dart'; // Import Seeder
import 'dart:async';
import 'package:dots_indicator/dots_indicator.dart';

class HomeBottomSheet extends StatefulWidget {
  const HomeBottomSheet({super.key});

  @override
  State<HomeBottomSheet> createState() => _HomeBottomSheetState();
}

class _HomeBottomSheetState extends State<HomeBottomSheet> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  final MapControllerX mapController = Get.find<MapControllerX>();
  final HomeBottomSheetController homeController = Get.put(
    HomeBottomSheetController(),
  );

  bool _isLoadingLocation = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Ad Slider state
  final PageController _adPageController = PageController();
  final RxInt _currentAdIndex = 0.obs;
  Timer? _adTimer;

  @override
  void initState() {
    super.initState();
    // Set up listeners for controller changes
    ever(homeController.location, (value) {
      if (_locationController.text != value) {
        _locationController.text = value;
      }
    });
    
    // Also sync manual typing back to controller
    _locationController.addListener(() {
      if (_locationController.text != homeController.location.value) {
        homeController.updateLocation(_locationController.text);
      }
    });

    ever(
      homeController.description,
      (value) => _descriptionController.text = value,
    );
    ever(homeController.price, (value) => _priceController.text = value);

    _startAdTimer();
  }

  void _startAdTimer() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final adController = Get.find<AdController>();
      final ads = adController.ads.where(
        (a) => a.position == 'mobile' || a.position == 'customer',
      ).toList();
      
      if (ads.length > 1) {
        int nextIndex = (_currentAdIndex.value + 1) % ads.length;
        if (_adPageController.hasClients) {
          _adPageController.animateToPage(
            nextIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  // Temporary function to restore DB
  Future<void> _restoreDatabase() async {
    setState(() => _isLoadingLocation = true); // Repurpose loading state
    await CategorySeeder.seedCategories();
    await homeController.fetchServiceCategories(); // Refresh local list
    setState(() => _isLoadingLocation = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Database Restored! Categories added.')),
    );
  }

  // Temporary function to restore DB


  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _adPageController.dispose();
    _adTimer?.cancel();
    super.dispose();
  }

  /// 📍 Get Current Location & Convert to Address
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        final place = placemarks.first;
        final address =
            "${place.name}, ${place.locality}, ${place.administrativeArea}";

        homeController.updateLocation(address);

        // Update map controller
        mapController.updateLocation(
          LatLng(position.latitude, position.longitude),
        );

        // Hide keyboard
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }

    setState(() => _isLoadingLocation = false);
  }

  /// Service Type Selection Widget (Skilled/Unskilled Radio Buttons)
  Widget _buildServiceTypeSelection() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmartText(
            title: 'select_service'.tr,
            size: 15.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),

          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => homeController.updateType('Skilled'),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 10.h,
                      horizontal: 10.w,
                    ),
                    decoration: BoxDecoration(
                      color: homeController.selectedType.value == 'Skilled'
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: homeController.selectedType.value == 'Skilled'
                            ? AppColors.primary
                            : AppColors.lightGrey,
                        width: 1.5.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'Skilled',
                          groupValue: homeController.selectedType.value,
                          onChanged: (value) {
                            if (value != null) {
                              homeController.updateType(value);
                            }
                          },
                          activeColor: AppColors.primary,
                        ),

                        SizedBox(width: 5.w),
                        Expanded(
                          child: SmartText(
                            title: 'skilled'.tr,
                            size: 14.sp,
                            fontWeight: FontWeight.w600,
                            color:
                                homeController.selectedType.value ==
                                    'skilled'.tr
                                ? AppColors.primary
                                : AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => homeController.updateType('Unskilled'),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 12.w,
                    ),
                    decoration: BoxDecoration(
                      color: homeController.selectedType.value == 'Unskilled'
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: homeController.selectedType.value == 'Unskilled'
                            ? AppColors.primary
                            : AppColors.lightGrey,
                        width: 1.5.w,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'Unskilled',
                          groupValue: homeController.selectedType.value,
                          onChanged: (value) {
                            if (value != null) {
                              homeController.updateType(value);
                            }
                          },
                          activeColor: AppColors.primary,
                        ),

                        SizedBox(width: 5.w),
                        Expanded(
                          child: SmartText(
                            title: 'helper'.tr,
                            size: 14.sp,
                            fontWeight: FontWeight.w600,
                            color:
                                homeController.selectedType.value == 'Unskilled'
                                ? AppColors.primary
                                : AppColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    });
  }

  /// Service Selection Widget
  Widget _buildServiceSelection() {
    return Obx(() {
      if (homeController.isLoadingCategories.value) {
        return Center(child: CircularProgressIndicator());
      }

      // Only show service selection if type is selected
      if (homeController.selectedType.value.isEmpty) {
        return const SizedBox.shrink();
      }

      // Get categories based on selected type
      final categories = homeController.getCurrentCategoryList();

      if (categories.isEmpty) {
        return Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.7),
              width: 1.5.w,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary.withOpacity(0.7),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SmartText(
                  title: 'no_services_available'.tr,
                  size: 13.sp,
                  color: AppColors.primary.withOpacity(0.7),
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
            title: 'select_service'.tr,
            size: 15.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
          SizedBox(height: 5.h),

          /// Dropdown for main categories
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.lightGrey, width: 1.5.w),
            ),
            child: DropdownButton<String>(
              isExpanded: true,
              value: homeController.selectedService.value.isEmpty
                  ? null
                  : homeController.selectedService.value,
              hint: SmartText(title: 'select_a_service'.tr, size: 14.sp),
              underline: const SizedBox(),
              onChanged: (value) {
                if (value != null) {
                  homeController.updateService(value);
                }
              },
              items: categories
                  .map(
                    (service) => DropdownMenuItem<String>(
                      value: service,
                      child: Text(service, style: TextStyle(fontSize: 14.sp)),
                    ),
                  )
                  .toList(),
            ),
          ),

          SizedBox(height: 10.h),

          /// Show subcategories if a service is selected
          if (homeController.selectedService.value.isNotEmpty &&
              homeController.serviceCategories.containsKey(
                homeController.selectedService.value,
              ) &&
              homeController
                  .serviceCategories[homeController.selectedService.value]!
                  .isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmartText(
                  title: 'select_subcategory'.tr,
                  size: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColors.lightGrey, width: 1.w),
                  ),
                  child: Wrap(
                    spacing: 10.w,
                    runSpacing: 8.h,
                    children: homeController
                        .serviceCategories[homeController
                            .selectedService
                            .value]!
                        .map(
                          (sub) => GestureDetector(
                            onTap: () {
                              homeController.toggleSubcategory(sub);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    homeController.selectedSubcategories.contains(sub)
                                    ? AppColors.primary
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.5.w,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Checkbox icon
                                  Icon(
                                    homeController.selectedSubcategories.contains(sub)
                                        ? Icons.check_box
                                        : Icons.check_box_outline_blank,
                                    size: 18.sp,
                                    color:
                                        homeController.selectedSubcategories.contains(sub)
                                        ? AppColors.white
                                        : AppColors.primary,
                                  ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    sub,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          homeController
                                                  .selectedSubcategories
                                                  .contains(sub)
                                          ? AppColors.white
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
        ],
      );
    });
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SmartText(
          title: 'description_optional'.tr,
          size: 15.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: _descriptionController,
          onChanged: homeController.updateDescription,
          maxLines: 3,
          style: TextStyle(fontSize: 12.sp),
          decoration: InputDecoration(
            hint: SmartText(title: 'describe_service'.tr, size: 12.sp),
            filled: true,
            fillColor: AppColors.lightGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SmartText(
          title: 'price_offer'.tr,
          size: 15.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: 5.h),
        TextField(
          controller: _priceController,
          onChanged: homeController.updatePrice,
          keyboardType: TextInputType.number,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hint: SmartText(title: 'enter_price'.tr, size: 12.sp),
            filled: true,
            fillColor: AppColors.lightGrey,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 14.w, right: 6.w),
              child: SmartText(
                title: 'rs_prefix'.tr,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                size: 16.sp,
              ),
            ),
            prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: EdgeInsets.symmetric(
              vertical: 16.h,
              horizontal: 16.w,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SmartText(
          title: 'when_needed'.tr,
          size: 15.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        SizedBox(height: 5.h),
        Row(
          children: [
            Expanded(child: _buildCompactTimeButton('Now', Icons.flash_on)),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildCompactTimeButton('Anytime', Icons.schedule),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactTimeButton(String time, IconData icon) {
    return Obx(() {
      final isSelected = homeController.selectedTime.value == time;
      return GestureDetector(
        onTap: () => homeController.updateTime(time),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.lightGrey,
              width: 1.2.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: isSelected ? AppColors.white : AppColors.primary,
              ),
              SizedBox(width: 6.w),
              SmartText(
                title: time.toLowerCase().tr,
                size: 13.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.black,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildImageUpload() {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SmartText(
            title: 'upload_image'.tr,
            size: 15.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          SizedBox(height: 5.h),
          InkWell(
            onTap: homeController.pickImage,
            child: Container(
              width: double.infinity,
              height: 120.h,
              decoration: BoxDecoration(
                color: AppColors.lightGrey,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.grey.withOpacity(0.3),
                  width: 1.w,
                ),
              ),
              child: homeController.isUploading.value
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    )
                  : homeController.imageFile.value != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.file(
                        homeController.imageFile.value!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40.sp,
                          color: AppColors.grey,
                        ),
                        SizedBox(height: 8.h),
                        SmartText(
                          title: 'upload_photo_of_issue'.tr,
                          size: 13.sp,
                          color: AppColors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.50,
      minChildSize: 0.50,
      maxChildSize: 1.0,
      snap: true,
      snapSizes: const [0.50, 1.0],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h, bottom: 16.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20.w, 
                    0, 
                    20.w, 
                    MediaQuery.of(context).viewInsets.bottom + 20.h // ✅ Keyboard padding
                  ),
                  children: [
                    SmartText(
                      title: 'where_service_needed'.tr,
                      size: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Flexible( // ✅ Fix overflow
                          child: GooglePlaceAutoCompleteTextField(
                            textEditingController: _locationController,
                            googleAPIKey: GoogleAPIKey.apiKey,
                            inputDecoration: InputDecoration(
                              hint: SmartText(
                                title: "search_location".tr,
                                color: Colors.grey,
                                size: 14.sp,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                            ),
                            debounceTime: 600,
                            isLatLngRequired: true,
                            getPlaceDetailWithLatLng: (Prediction prediction) {
                              if (prediction.lat != null &&
                                  prediction.lng != null) {
                                final lat =
                                    double.tryParse(prediction.lat!) ?? 0.0;
                                final lng =
                                    double.tryParse(prediction.lng!) ?? 0.0;
                                final selectedLatLng = LatLng(lat, lng);

                                mapController.updateLocation(
                                  selectedLatLng,
                                  zoom: 18,
                                );

                                homeController.updateLocation(
                                  prediction.description ?? "",
                                );

                                _sheetController.animateTo(
                                  0.25,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );

                                FocusScope.of(context).unfocus();
                              }
                            },
                            itemClick: (Prediction prediction) {
                              homeController.updateLocation(
                                prediction.description ?? "",
                              );
                              FocusScope.of(context).unfocus();
                            },
                            radius: 50000,
                            seperatedBuilder: Divider(
                              height: 1,
                              color: Colors.grey[200],
                            ),
                            containerHorizontalPadding: 0,
                            itemBuilder:
                                (context, index, Prediction prediction) {
                                  return Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 12.h,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8.w),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color: Colors.blue.shade600,
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: SmartText(
                                            title: prediction.description ?? "",
                                            size: 14.sp,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(right: 8.w),
                          child: Obx(() {
                            final isLoading = _isLoadingLocation || mapController.isAddressLoading.value;
                            return IconButton(
                              icon: isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue.shade600,
                                        ),
                                      ),
                                    )
                                  : Icon(Icons.my_location, color: Colors.blue),
                              onPressed: isLoading
                                  ? null
                                  : _getCurrentLocation,
                            );
                          }),
                        ),
                      ],
                    ),

                    SizedBox(height: 15.h),
                    
                    // Ads Slider Section
                    Obx(() {
                      final adController = Get.isRegistered<AdController>() 
                          ? Get.find<AdController>() 
                          : Get.put(AdController());
                      
                      final ads = adController.ads.where(
                        (a) => a.position == 'mobile' || a.position == 'customer',
                      ).toList();

                      if (ads.isEmpty) return const SizedBox.shrink();
                      
                      if (ads.length == 1) {
                        return AdWidget(ad: ads.first);
                      }

                      return Column(
                        children: [
                          SizedBox(
                            height: 115.h, // Increased slightly for safety
                            child: PageView.builder(
                              controller: _adPageController,
                              onPageChanged: (index) => _currentAdIndex.value = index,
                              itemCount: ads.length,
                              itemBuilder: (context, index) {
                                return AdWidget(
                                  ad: ads[index],
                                  margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Obx(() => DotsIndicator(
                            dotsCount: ads.length,
                            position: _currentAdIndex.value.toDouble(),
                            decorator: DotsDecorator(
                              size: Size.square(6.0.r),
                              activeSize: Size(12.0.r, 6.0.r),
                              activeColor: AppColors.primary,
                              color: AppColors.grey.withOpacity(0.3),
                              activeShape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0.r),
                              ),
                            ),
                          )),
                        ],
                      );
                    }),

                    SizedBox(height: 15.h),
                    _buildServiceTypeSelection(),

                    SizedBox(height: 10.h),
                    _buildServiceSelection(), // Updated with filtering

                    SizedBox(height: 10.h),
                    _buildDescriptionField(),

                    SizedBox(height: 10.h),
                    _buildPriceInput(),

                    SizedBox(height: 10.h),
                    _buildCompactTimeSelection(),

                    SizedBox(height: 10.h),
                    _buildImageUpload(),

                    SizedBox(height: 10.h),

                    /// Find Professional Button
                    Obx(() {
                      final isEnabled =
                          homeController.isFormValid &&
                          !homeController.isLoading.value &&
                          homeController.isUserAuthenticated;

                      return CustomButton(
                        text: 'find_professional'.tr,
                        onPressed: isEnabled
                            ? () {
                                FocusScope.of(context).unfocus();
                                homeController.submitRequest();
                              }
                            : () {},
                        isLoading: homeController.isLoading.value,
                        backgroundColor: isEnabled
                            ? AppColors.primary
                            : AppColors.grey,
                        height: 60.h,
                        width: double.infinity,
                        fontSize: 16.sp,
                        borderRadius: 12,
                        textColor: Colors.white,
                      );
                    }),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
