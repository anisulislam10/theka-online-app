import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/views/Splash/welcome_screen.dart';

import '../../Auth/Login/login_page.dart';
import '../../Auth/login_type_page.dart';

class ProviderProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  /// --- Reactive State ---
  var isLoading = false.obs;
  var profileImageUrl = ''.obs;
  var selectedCity = ''.obs;
  var selectedImageFile = Rx<XFile?>(null);
  var rating = 0.0.obs; // e.g., 4.6667
  var totalRatings = 0.obs; // e.g., 12

  /// --- Text Controllers ---
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final categoryController = TextEditingController();

  /// --- Service Category Map ---
  var serviceCategories = <String, List<String>>{}.obs;
  final selectedCategory = ''.obs;

  /// --- Lifecycle ---
  @override
  void onInit() {
    super.onInit();
    fetchProviderData();
    // fetchServiceCategories();
  }

  /// --- Fetch Provider Profile from Firestore ---
  Future<void> fetchProviderData() async {
    try {
      isLoading.value = true;
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await _firestore
          .collection('ServiceProviders')
          .doc(uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data()!;
        nameController.text = data['name'] ?? '';
        emailController.text = data['email'] ?? '';
        phoneController.text = data['phone'] ?? '';
        selectedCity.value = data['city'] ?? '';
        categoryController.text = data['serviceCategory'] ?? '';
        profileImageUrl.value = data['profileImage'] ?? '';
        rating.value = (data['rating'] ?? 0.0).toDouble();
        totalRatings.value = (data['totalRatings'] ?? 0);
      }
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_load_profile',
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// --- Pick Image ---
  Future<void> showImageSourceDialog(BuildContext context) async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: SmartText(title: "choose_from_gallery".tr),
              onTap: () {
                Get.back();
                pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: SmartText(title: "take_a_photo".tr),
              onTap: () {
                Get.back();
                pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 75);
    if (picked != null) {
      selectedImageFile.value = picked;
      // Auto-save the image update
      await saveProfileChanges();
    }
  }

  /// --- Upload Image ---
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      final uid = _auth.currentUser!.uid;
      final ref = _storage.ref().child('profile_images/$uid.jpg');
      await ref.putData(await imageFile.readAsBytes());
      return await ref.getDownloadURL();
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'image_upload_failed'.tr,
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
      return null;
    }
  }

  /// --- Save Profile ---
  Future<void> saveProfileChanges() async {
    try {
      isLoading.value = true;
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      String imageUrl = profileImageUrl.value;
      if (selectedImageFile.value != null) {
        final uploadedUrl = await uploadProfileImage(selectedImageFile.value!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        }
      }

      final bool isImageUpdate = selectedImageFile.value != null;

      await _firestore.collection('ServiceProviders').doc(uid).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'city': selectedCity.value,
        'profileImage': imageUrl,
      });

      profileImageUrl.value = imageUrl;
      selectedImageFile.value = null;

      Get.snackbar(
        'success'.tr,
        isImageUpdate ? 'profile_picture_updated_successfully'.tr : 'profile_updated_successfully'.tr,
        backgroundColor: AppColors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_save_profile'.tr,
        backgroundColor: AppColors.error,
        colorText: AppColors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // --- Step 1: Delete from Firestore ---

      // Delete ServiceProvider document
      await _firestore.collection('ServiceProviders').doc(uid).delete();

      // Delete from completedRequests where providerId == uid
      final completedRequestsSnapshot = await _firestore
          .collection('completedRequests')
          .where('providerId', isEqualTo: uid)
          .get();

      for (var doc in completedRequestsSnapshot.docs) {
        await _firestore.collection('completedRequests').doc(doc.id).delete();
      }

      // --- Step 2: Delete from Firebase Storage ---
      final storage = _storage;

      // Helper to delete a file if exists
      Future<void> deleteIfExists(String path) async {
        try {
          final ref = storage.ref().child(path);
          await ref.delete();
        } catch (e) {
          debugPrint('⚠️ No file found at $path or already deleted');
        }
      }

      // Delete CNIC front/back and profile image
      await deleteIfExists('documents/cnic_back/$uid');
      await deleteIfExists('documents/cnic_front/$uid');
      await deleteIfExists('profile_images/$uid.jpg');

      // --- Step 3: Delete from Firebase Auth ---
      await _auth.currentUser?.delete();

      // --- Step 4: Sign out & show confirmation ---
      await _auth.signOut();
      Get.offAll(() => LoginPage());

      Get.snackbar(
        'account_deleted'.tr,
        'account_deleted_message'.tr,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
      );

      // Optionally navigate to login screen
      // Get.offAll(() => LoginScreen());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Get.snackbar(
          'reauth_required'.tr,
          'reauth_required_message'.tr,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'delete_account_error'.tr,
          'delete_account_error_message'.tr,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'delete_account_error'.tr,
        'delete_account_error_message'.tr,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void confirmDeleteAccount() {
    Get.defaultDialog(
      title: "delete_account".tr,
      middleText: "delete_account_warning".tr,
      textCancel: "cancel".tr,
      textConfirm: "delete".tr,
      confirmTextColor: Colors.white,
      buttonColor: AppColors.error,
      onConfirm: () {
        Get.back(); // close dialog
        deleteAccount();
      },
    );
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    categoryController.dispose();
    super.onClose();
  }
}
