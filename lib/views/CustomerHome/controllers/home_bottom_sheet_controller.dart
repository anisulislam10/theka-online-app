import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/views/CustomerHome/controllers/maps_controller.dart';
import 'package:quickserve/views/MyRequest/my_request.dart';
import 'package:quickserve/views/Auth/AuthService/auth_service.dart';

class HomeBottomSheetController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FORM FIELDS
  var location = ''.obs;
  var selectedType = ''.obs; // "Skilled" or "Unskilled"
  var selectedService = ''.obs;
  var selectedSubcategories = <String>[].obs;
  var description = ''.obs;
  var price = ''.obs;
  var selectedTime = 'Anytime'.obs;
  var imageFile = Rx<File?>(null);
  var imageUrl = ''.obs;

  // Service categories
  final skilledCategories = <String>[].obs;
  final unskilledCategories = <String>[].obs;
  final serviceCategories = <String, List<String>>{}.obs;

  // UI states
  var isLoading = false.obs;
  var isUploading = false.obs;
  var isLoadingCategories = false.obs;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Add these variables to HomeBottomSheetController class
  bool isGuestUser() => AuthService.getSavedRole() == 'guest';

  // Add these variables to HomeBottomSheetController class
  var isDialogLoading = true.obs;
  var isCancelled = false.obs;
  Timer? _timeoutTimer;
  StreamSubscription? _requestSubscription;
  final MapControllerX mapController = Get.find<MapControllerX>();

  // Form validation
  bool get isFormValid {
    // Basic fields validation
    bool basicFields = location.value.isNotEmpty &&
        selectedType.value.isNotEmpty &&
        selectedService.value.isNotEmpty &&
        price.value.isNotEmpty &&
        selectedTime.value.isNotEmpty &&
        imageFile.value != null;

    // Subcategory validation (if subcategories exist for the selected service, at least one must be selected)
    bool subcategoryValid = true;
    if (selectedService.value.isNotEmpty &&
        serviceCategories.containsKey(selectedService.value)) {
      final subcategories = serviceCategories[selectedService.value];
      if (subcategories != null && subcategories.isNotEmpty) {
        subcategoryValid = selectedSubcategories.isNotEmpty;
      }
    }

    return basicFields && subcategoryValid;
  }

  @override
  void onInit() {
    super.onInit();
    fetchServiceCategories();
    checkForPendingRequestOnStart();
  }

  @override
  void onClose() {
    _cancelTimeoutTimer();
    _requestSubscription?.cancel();
    super.onClose();
  }

  // ✅ Fetch categories from Firestore
  Future<void> fetchServiceCategories() async {
    try {
      isLoadingCategories.value = true;

      debugPrint('🔍 Fetching service categories...');

      // Clear existing lists
      skilledCategories.clear();
      unskilledCategories.clear();
      serviceCategories.clear();

      // Define category names
      final skilledCategoryNames = [
        'Electrician',
        'Plumber',
        'Painter',
        'Carpenter',
        'Welder',
        'Solar Panel Technicians',
        'Fabricator',
        'AC Services',
        'CCTV Services',
        'Tiles Work',
        'Mason',
      ];

      final unskilledCategoryNames = [
        'Helper',
        'Sweeper',
        'Gardener',
        'Guard',
        'Aya (Baby Caretaker)',
      ];

      // Fetch Skilled categories
      for (var categoryName in skilledCategoryNames) {
        try {
          final doc = await _firestore
              .collection('ServiceCategories')
              .doc('Skilled')
              .collection(categoryName)
              .doc(categoryName)
              .get();

          if (doc.exists) {
            skilledCategories.add(categoryName);

            // Fetch subcategories if they exist
            final data = doc.data();
            if (data != null && data.containsKey('subcategories')) {
              serviceCategories[categoryName] = List<String>.from(
                data['subcategories'],
              );
            } else {
              serviceCategories[categoryName] = [];
            }

            debugPrint('✅ Found Skilled: $categoryName');
          }
        } catch (e) {
          debugPrint('⚠️ Skilled category not found: $categoryName');
        }
      }

      // Fetch Unskilled categories
      for (var categoryName in unskilledCategoryNames) {
        try {
          final doc = await _firestore
              .collection('ServiceCategories')
              .doc('Unskilled')
              .collection(categoryName)
              .doc(categoryName)
              .get();

          if (doc.exists) {
            unskilledCategories.add(categoryName);

            // Fetch subcategories if they exist
            final data = doc.data();
            if (data != null && data.containsKey('subcategories')) {
              serviceCategories[categoryName] = List<String>.from(
                data['subcategories'],
              );
            } else {
              serviceCategories[categoryName] = [];
            }

            debugPrint('✅ Found Unskilled: $categoryName');
          }
        } catch (e) {
          debugPrint('⚠️ Unskilled category not found: $categoryName');
        }
      }

      debugPrint('✅ Skilled Categories: $skilledCategories');
      debugPrint('✅ Unskilled Categories: $unskilledCategories');
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching categories: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Failed to load categories: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoadingCategories.value = false;
    }
  }

  // ✅ Get current category list based on selected type
  List<String> getCurrentCategoryList() {
    return selectedType.value == 'Skilled'
        ? skilledCategories
        : unskilledCategories;
  }

  // UPDATE TYPE
  void updateType(String type) {
    selectedType.value = type;
    // Reset service and subcategory when type changes
    selectedService.value = '';
    selectedSubcategories.clear();
  }

  // UPDATE LOCATION
  void updateLocation(String newLocation) {
    location.value = newLocation;
  }

  // UPDATE SERVICE
  void updateService(String service) {
    selectedService.value = service;
    // Reset subcategory when service changes
    selectedSubcategories.clear();
  }

  // TOGGLE SUBCATEGORY (Multiple Selection)
  void toggleSubcategory(String subcategory) {
    if (selectedSubcategories.contains(subcategory)) {
      selectedSubcategories.remove(subcategory);
    } else {
      selectedSubcategories.add(subcategory);
    }
  }

  // UPDATE DESCRIPTION
  void updateDescription(String newDescription) {
    description.value = newDescription;
  }

  // UPDATE PRICE
  void updatePrice(String newPrice) {
    price.value = newPrice;
  }

  // UPDATE TIME
  void updateTime(String time) {
    selectedTime.value = time;
  }

  // PICK IMAGE FUNCTION
  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        imageFile.value = File(image.path);
        await uploadImage();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to pick image: $e');
    }
  }

  // UPLOAD IMAGE FUNCTION
  Future<void> uploadImage() async {
    if (imageFile.value == null) return;

    try {
      isUploading.value = true;
      final userId = currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('request_images')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(imageFile.value!);
      imageUrl.value = storageRef.fullPath;
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: $e');
    } finally {
      isUploading.value = false;
    }
  }

  // DELETE IMAGE FROM STORAGE
  Future<void> deleteImageFromStorage(String imageUrl) async {
    if (imageUrl.isEmpty) return;

    try {
      final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
      await storageRef.delete();
      debugPrint('✅ Image deleted from storage: $imageUrl');
    } catch (e) {
      debugPrint('⚠️ Error deleting image: $e');
    }
  }

  // CANCEL REQUEST
  Future<void> cancelRequest(DocumentReference docRef, String? imageUrl) async {
    try {
      await docRef.delete();

      if (imageUrl != null && imageUrl.isNotEmpty) {
        await deleteImageFromStorage(imageUrl);
      }

      // if (Get.isDialogOpen ?? false) Get.back();

      Get.snackbar(
        'Cancelled',
        'Your request has been cancelled.',
        backgroundColor: AppColors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('⚠️ Error cancelling request: $e');
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar(
        'Error',
        'Failed to cancel request: $e',
        backgroundColor: AppColors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // GET USER DATA
  Future<Map<String, String>> getUserData() async {
    final user = currentUser;
    if (user == null) {
      return {'userName': 'Unknown User', 'profileImage': '', 'userPhone': ''};
    }

    try {
      final userDoc = await _firestore
          .collection('Customers')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        return {
          'userName': data?['name'] ?? user.displayName ?? 'Unknown User',
          'profileImage': data?['profileImage'] ?? '',
          'userPhone': data?['phone'] ?? user.phoneNumber ?? '',
          'userRating': (data?['rating'] ?? 0.0).toString(),
          'totalRatings': (data?['totalRatings'] ?? 0).toString(),
        };
      }

      return {
        'userName': user.displayName ?? 'Unknown User',
        'profileImage': user.photoURL ?? '',
        'userPhone': user.phoneNumber ?? '',
        'userRating': '0.0',
        'totalRatings': '0',
      };
    } catch (e) {
      debugPrint('⚠️ Error fetching user data: $e');
      return {
        'userName': user.displayName ?? 'Unknown User',
        'profileImage': user.photoURL ?? '',
        'userPhone': user.phoneNumber ?? '',
      };
    }
  }

  // SUBMIT REQUEST FUNCTION
  Future<void> submitRequest() async {
    if (!isFormValid) {
      Get.snackbar(
        'Error',
        'Please fill all required fields',
        backgroundColor: AppColors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (currentUser == null) {
      Get.snackbar(
        'error'.tr,
        'please_login'.tr,
        backgroundColor: AppColors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;

      final userId = currentUser!.uid;
      final userEmail = currentUser!.email ?? 'No email';

      final userData = await getUserData();
      final userName = userData['userName']!;
      final profileImage = userData['profileImage']!;
      final userPhone = userData['userPhone'] ?? '';

      final subcollection = selectedTime.value == 'Now' ? 'Now' : 'AnyTime';

      final requestData = {
        'userId': userId,
        'userEmail': userEmail,
        'userName': userName,
        'profileImage': profileImage,
        'location': location.value,
        'serviceType': selectedType.value, // ✅ Added
        'service': selectedService.value,
        'subcategory': selectedSubcategories.toList(), // Store as List instead of String
        'description': description.value,
        'price': int.tryParse(price.value) ?? 0,
        'imageUrl': imageUrl.value,
        'userPhone': userPhone,
        'userRating': double.tryParse(userData['userRating'] ?? '0.0') ?? 0.0,
        'totalRatings': int.tryParse(userData['totalRatings'] ?? '0') ?? 0,
        'requestType': selectedTime.value,
        'latitude': mapController.currentLocation.value.latitude,
        'longitude': mapController.currentLocation.value.longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      };

      if (selectedTime.value == 'AnyTime') {
        requestData['expiresAt'] = DateTime.now().add(
          const Duration(hours: 24),
        );
      }

      debugPrint('📤 Submitting request with data:');
      debugPrint('   🔧 Type: ${selectedType.value}');
      debugPrint('   🔧 Service: ${selectedService.value}');
      debugPrint('   💰 Price: ${price.value}');

      final docRef = await _firestore
          .collection('Requests')
          .doc(userId)
          .collection(subcollection)
          .add(requestData);

      debugPrint('✅ Request submitted successfully: ${docRef.id}');

      showPendingDialog(docRef);
      clearForm();
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();

      debugPrint('❌ Error submitting request: $e');
      Get.snackbar(
        'Error',
        'Failed to submit request: $e',
        backgroundColor: AppColors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // CHECK FOR PENDING REQUEST ON START
  Future<void> checkForPendingRequestOnStart() async {
    final user = currentUser;
    if (user == null) {
      debugPrint('❌ No user logged in, skipping pending request check');
      return;
    }

    debugPrint('🔍 Checking for pending requests for user: ${user.uid}');

    try {
      for (final sub in ['Now', 'AnyTime']) {
        debugPrint('🔍 Checking subcollection: $sub');

        final snapshot = await _firestore
            .collection('Requests')
            .doc(user.uid)
            .collection(sub)
            .where('status', isEqualTo: 'pending')
            .get();

        debugPrint('📊 Found ${snapshot.docs.length} documents in $sub');

        if (snapshot.docs.isNotEmpty) {
          final sortedDocs = snapshot.docs.toList()
            ..sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;
              if (aTime == null || bTime == null) return 0;
              return bTime.compareTo(aTime);
            });

          final doc = sortedDocs.first;
          final docRef = doc.reference;

          debugPrint('✅ Found pending request in $sub: ${doc.id}');

          showPendingDialog(docRef);
          break;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Error checking for pending request: $e');
      debugPrint('📚 Stack trace: $stackTrace');
    }
  }

  // WAITING DIALOG
  // Replace the existing showPendingDialog method with this updated version
  void showPendingDialog(DocumentReference docRef) {
    debugPrint('🏁 [START] showPendingDialog for ID: ${docRef.id}');
    
    // 1. Atomic Pre-reset: ensure no dangling state or listeners from BEFORE
    _requestSubscription?.cancel();
    _requestSubscription = null;
    _cancelTimeoutTimer();
    
    isCancelled.value = false;
    isDialogLoading.value = true;
    
    // Local guard for this specific dialog instance
    bool dialogClosed = false;

    void closeSafe({String reason = 'Unknown'}) {
      if (dialogClosed) {
        debugPrint('⚠️ [GUARD] closeSafe already triggered. Ignoring reason: $reason');
        return;
      }
      dialogClosed = true;
      debugPrint('🛑 [CLOSE] reason: $reason');
      
      _cancelTimeoutTimer();
      _requestSubscription?.cancel();
      _requestSubscription = null;

      try {
        if (Get.isDialogOpen == true) {
          debugPrint('✅ [POP] Using Navigator for root overlay');
          Navigator.of(Get.overlayContext!, rootNavigator: true).pop();
        } else {
          debugPrint('⚠️ [SKIP] Get.isDialogOpen is false. No pop performed.');
        }
      } catch (e) {
        debugPrint('❌ [ERROR] during pop: $e');
        // Fallback for safety
        if (Get.isDialogOpen == true) Get.back();
      }
    }

    _startTimeoutTimer();

    // Use Future.microtask to ensure previous navigation (if any) is fully settled
    Future.microtask(() {
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false, // Prevent physical back button
          child: Obx(
            () => AlertDialog(
              backgroundColor: Colors.white,
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: 14.w), // Make dialog wider
              titlePadding: EdgeInsets.zero, // Custom padding in title widget
              contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              actionsPadding: EdgeInsets.fromLTRB(10.w, 0, 10.w, 20.h), // Reduce side padding
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   if (isDialogLoading.value)
                    Container(
                      margin: EdgeInsets.all(16.w),
                      height: 180.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        boxShadow: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.05),
                             blurRadius: 10,
                             offset: const Offset(0, 4),
                           ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: mapController.currentLocation.value,
                                zoom: 17,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('center'),
                                  position: mapController.currentLocation.value,
                                ),
                              },
                              zoomControlsEnabled: false,
                              myLocationButtonEnabled: false,
                              compassEnabled: false,
                              mapToolbarEnabled: false,
                            ),
                            Container(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            Center(
                              child: SpinKitPulse(
                                color: AppColors.primary,
                                size: 120.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 24.h), // Slightly reduced padding
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.05),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.r), // Reduced padding
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person_off_rounded,
                              color: AppColors.red,
                              size: 40.sp, // Reduced size
                            ),
                          ),
                          SizedBox(height: 12.h),
                          SmartText(
                            title: "no_professional_found".tr,
                            size: 18.sp, // Slightly reduced
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDialogLoading.value) ...[
                     SizedBox(height: 10.h),
                     SmartText(
                      title: "finding_professional".tr,
                      size: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    SmartText(
                      title: "finding_professional_hint".tr,
                      textAlign: TextAlign.center,
                      size: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ] else 
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: SmartText(
                        title: "please_try_again".tr,
                        textAlign: TextAlign.center,
                        size: 14.sp,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                if (isDialogLoading.value)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 10.h),
                      child: TextButton.icon(
                        onPressed: () async {
                          debugPrint('🛑 [CANCEL] User clicked Cancel (Loading)');
                          isCancelled.value = true;
                          closeSafe(reason: 'Cancel Button UI (Loading)');
                          try {
                            final snapshot = await docRef.get();
                            if (snapshot.exists) {
                              final data = snapshot.data() as Map<String, dynamic>?;
                              final imageUrl = data?['imageUrl'] as String?;
                              await cancelRequest(docRef, imageUrl);
                            }
                          } catch (e) {
                            debugPrint('⚠️ [CLEANUP] Error during cancellation: $e');
                          }
                        },
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: SmartText(
                          title: "cancel".tr,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                        style: TextButton.styleFrom(
                           padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                           backgroundColor: Colors.red.withOpacity(0.05),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
                        ),
                      ),
                    ),
                  )
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Retry Button
                        ElevatedButton.icon(
                          onPressed: () {
                            debugPrint('🔄 [RETRY] User clicked Retry');
                            isDialogLoading.value = true;
                            _startTimeoutTimer();
                          },
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 16), // Smaller icon
                          label: SmartText(
                            title: "retry".tr,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            size: 12, // Smaller text
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 2,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 10.h), // Reduced padding
                          ),
                        ),
                        SizedBox(width: 8.w), // Reduced spacing
                        
                        // Close Button
                        OutlinedButton.icon(
                          onPressed: () {
                            debugPrint('🔘 [CLOSE] User clicked Close');
                            closeSafe(reason: 'Close Button UI');
                          },
                          icon: Icon(Icons.close_rounded, color: Colors.grey[700], size: 16), // Smaller icon
                          label: SmartText(title: "close".tr, color: Colors.grey[700], size: 12, fontWeight: FontWeight.w600), // Smaller text
                          style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h)), // Reduced padding
                        ),
                        SizedBox(width: 8.w), // Reduced spacing

                        // Cancel Button
                        OutlinedButton.icon(
                          onPressed: () async {
                            debugPrint('🛑 [CANCEL] User clicked Cancel');
                            isCancelled.value = true;
                            closeSafe(reason: 'Cancel Button UI');
                            try {
                              final snapshot = await docRef.get();
                              if (snapshot.exists) {
                                final data =
                                    snapshot.data() as Map<String, dynamic>?;
                                final imageUrl = data?['imageUrl'] as String?;
                                await cancelRequest(docRef, imageUrl);
                              }
                            } catch (e) {
                              debugPrint(
                                  '⚠️ [CLEANUP] Error during cancellation: $e');
                            }
                          },
                          icon: const Icon(Icons.cancel_outlined,
                              color: Colors.red, size: 16), // Smaller icon
                          label: SmartText(
                            title: "cancel".tr,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                            size: 12, // Smaller text
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.withOpacity(0.3)),
                            backgroundColor: Colors.red.withOpacity(0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h), // Reduced padding
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    });

    // Listen to status changes
    _requestSubscription = docRef.snapshots().listen((snapshot) {
      if (isCancelled.value) {
        debugPrint('👂 [LISTEN] Change heard, but isCancelled is true. Skipping.');
        // Don't close here, the button already handles it.
        return;
      }

      if (!snapshot.exists) {
        debugPrint('👂 [LISTEN] Document deleted/not found');
        closeSafe(reason: 'Firestore Snapshot: No document');
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>?;
      final status = data?['status'] ?? 'pending';

      if (status == 'completed') {
        debugPrint('👂 [LISTEN] Status is completed');
        closeSafe(reason: 'Request Flow Success: Completed');

        Get.snackbar(
          'Request Completed!',
          'A professional has completed your request.',
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );

        Future.delayed(const Duration(milliseconds: 500), () {
          Get.off(() => MyRequest());
        });
      }
    });
  }

  // Add these helper methods to the controller
  void _startTimeoutTimer() {
    _cancelTimeoutTimer(); // Cancel any existing timer

    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (isDialogLoading.value) {
        isDialogLoading.value = false;
        debugPrint('⏱️ Dialog timeout reached after 30 seconds');
      }
    });
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  // CLEAR FORM
  void clearForm() {
    location.value = '';
    selectedType.value = '';
    selectedService.value = '';
    selectedSubcategories.clear();
    description.value = '';
    price.value = '';
    selectedTime.value = 'Anytime';
    imageFile.value = null;
    imageUrl.value = '';
  }

  // Check if user is authenticated
  bool get isUserAuthenticated => currentUser != null;
}
