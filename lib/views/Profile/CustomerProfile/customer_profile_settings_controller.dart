import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickserve/core/constants/appTexts.dart';
import 'package:quickserve/views/Splash/welcome_screen.dart';

import '../../Auth/Login/login_page.dart';
import '../../Auth/login_type_page.dart';

class CustomerProfileSettingsController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get userId => _auth.currentUser?.uid ?? '';

  final name = ''.obs;
  final email = ''.obs;
  final phone = ''.obs;
  
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  final selectedCity = ''.obs;
  final profileImageUrl = ''.obs;
  final isLoading = false.obs;
  final userRating = 0.0.obs;
  final totalRatings = 0.obs;

  /// Newly selected local image (not uploaded yet)
  final selectedImageFile = Rx<XFile?>(null);

  /// Load profile data
  Future<void> loadUserProfile() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('Customers').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        
        // Update Observables
        name.value = data['name'] ?? '';
        email.value = data['email'] ?? user.email ?? '';
        phone.value = data['phone'] ?? '';
        selectedCity.value = data['city'] ?? '';
        profileImageUrl.value = data['profileImage'] ?? '';
        userRating.value = (data['rating'] ?? 0).toDouble();
        totalRatings.value = data['totalRatings'] ?? 0;

        // Sync Text Controllers
        nameController.text = name.value;
        emailController.text = email.value;
        phoneController.text = phone.value;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load profile: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Show dialog for selecting image source
  Future<void> showImageSourceDialog(BuildContext context) async {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: SmartText(title: "take_a_photo".tr),
                onTap: () {
                  Get.back();
                  pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: SmartText(title: "choose_from_gallery".tr),
                onTap: () {
                  Get.back();
                  pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: SmartText(title: "cancel".tr),
                onTap: () => Get.back(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick a profile image (preview only, not uploaded yet)
  Future<void> pickProfileImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      // Just store the file for preview
      selectedImageFile.value = pickedFile;
      
      // Auto-save the image update
      await saveProfileChanges();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    }
  }

  /// Upload image to Firebase Storage and return URL
  Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
      await ref.putData(await imageFile.readAsBytes());
      return ref.fullPath;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload image: $e',
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return null;
    }
  }

  /// Save profile updates
  Future<void> saveProfileChanges() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      String? imageUrl = profileImageUrl.value;

      // Upload only if a new image is selected
      if (selectedImageFile.value != null) {
        final uploadedUrl = await uploadProfileImage(selectedImageFile.value!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
          profileImageUrl.value = uploadedUrl;
        }
      }

      final bool isImageUpdate = selectedImageFile.value != null;

      await _firestore.collection('Customers').doc(user.uid).update({
        'name': nameController.text.trim(),
        'city': selectedCity.value,
        'phone': phoneController.text.trim(),
        'profileImage': imageUrl,
      });

      selectedImageFile.value = null;

      Get.snackbar(
        'profile_updated'.tr,
        isImageUpdate ? 'profile_picture_updated_successfully'.tr : 'profile_updated_message'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'save_changes_failed'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Delete account and related data
  Future<void> deleteAccount() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) return;

      // 1. Delete profile image
      try {
        await _storage.ref('profile_images/${user.uid}.jpg').delete();
      } catch (_) {}

      // 2. Delete all request images
      try {
        final requestFolder = _storage.ref('request_images/${user.uid}');
        final list = await requestFolder.listAll();
        for (final item in list.items) {
          await item.delete();
        }
      } catch (_) {}

      // 3. Delete all Firestore subcollection documents under Requests/{uid}
      // 3. Delete all Firestore subcollection documents under Requests/{uid}/now and Requests/{uid}/anytime
      try {
        final requestDocRef = _firestore.collection('Requests').doc(user.uid);

        // Function to delete all docs in a given subcollection
        Future<void> deleteSubcollection(String subName) async {
          final subcollection = requestDocRef.collection(subName);
          final snapshot = await subcollection.get();
          for (final doc in snapshot.docs) {
            await doc.reference.delete();
          }
        }

        // Delete 'now' subcollection
        await deleteSubcollection('now');

        // Delete 'anytime' subcollection
        await deleteSubcollection('anytime');
      } catch (e) {
        debugPrint("⚠️ Failed to delete Requests subcollections: $e");
      }

      // 4. Delete main Firestore documents
      await _firestore.collection('Customers').doc(user.uid).delete();
      await _firestore.collection('Requests').doc(user.uid).delete();

      // 5. Delete Firebase Auth account
      await user.delete();

      // 6. Sign out & navigate
      await _auth.signOut();
      Get.offAll(() => LoginPage()); // update to your login route

      Get.snackbar(
        'account_deleted'.tr,
        'account_deleted_success'.tr,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failed_to_delete_account'.tr,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.onClose();
  }
}
