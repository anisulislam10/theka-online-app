import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/views/CustomerHome/controllers/home_bottom_sheet_controller.dart';

class MapControllerX extends GetxController {
  final Rx<LatLng> currentLocation = const LatLng(31.5204, 74.3587).obs; // Default to Lahore
  GoogleMapController? mapController;
  RxString currentAddress = "".obs;
  RxBool isAddressLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _handlePermissions();
  }

  /// 🔐 Request location & gallery permissions
  Future<void> _handlePermissions() async {
    // Request both location and gallery permissions (Mobile only)
    if (!kIsWeb) {
      final statuses = await [
        Permission.locationWhenInUse,
        Permission.photos,
      ].request();

      // Handle denied permissions
      if (statuses[Permission.locationWhenInUse]?.isDenied ?? false) {
        Get.snackbar(
          "Permission Required",
          "Location permission is needed for map access.",
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    // If all good, get location
    _getCurrentLocation();
  }

  /// 📍 Get current location from device
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        "Location Disabled",
        "Please enable location services",
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Check location permission (for safety)
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        Get.snackbar(
          "Permission Denied",
          "Location permission is required.",
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    }

    // ✅ Get position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    currentLocation.value = LatLng(position.latitude, position.longitude);

    // Move camera
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLng(currentLocation.value),
      );
    }
    
    // Initial address fetch
    getAddressFromLatLng(currentLocation.value);
  }

  /// 📍 Reverse Geocode LatLng to Address
  Future<void> getAddressFromLatLng(LatLng position) async {
    try {
      isAddressLoading.value = true;
      if (kIsWeb) {
        await _getAddressWeb(position);
        return;
      }
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        String address = "${place.name}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
        // Clean up empty parts
        address = address.replaceAll(", ,", ",").replaceAll(RegExp(r'^, '), '');
        
        currentAddress.value = address;
        
        // Update HomeBottomSheetController
        if (Get.isRegistered<HomeBottomSheetController>()) {
          Get.find<HomeBottomSheetController>().updateLocation(address);
        }
      }
    } catch (e) {
      debugPrint("Error reverse geocoding: $e");
    } finally {
      isAddressLoading.value = false;
    }
  }

  /// 📍 Web-compatible geocoding (Mobile doesn't support geocoding package on web)
  Future<void> _getAddressWeb(LatLng position) async {
    const apiKey = "AIzaSyDOcXPs9sFUONro_BliFWWjxE3pmndqW00";
    final url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == "OK" && (data["results"] as List).isNotEmpty) {
          final address = data["results"][0]["formatted_address"];
          currentAddress.value = address;
          if (Get.isRegistered<HomeBottomSheetController>()) {
            Get.find<HomeBottomSheetController>().updateLocation(address);
          }
        }
      }
    } catch (e) {
      debugPrint("Web reverse geocoding error: $e");
    }
  }

  /// 🎯 Recenter map to current position
  Future<void> recenterMap() async {
    await _getCurrentLocation();
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation.value, 18),
      );
    }
  }

  /// 📍 Update location from search
  void updateLocation(LatLng newLocation, {double zoom = 18}) {
    currentLocation.value = newLocation;
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: newLocation, zoom: zoom),
        ),
      );
    }
  }

  /// Handle Camera Idle (user stopped dragging)
  void onCameraIdle(LatLng center) {
    getAddressFromLatLng(center);
  }
}
