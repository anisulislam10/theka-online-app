import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quickserve/core/widgets/saving_progress_widget.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'account_verification_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class ReuploadCnicController extends GetxController {
  final cnicFront = Rx<XFile?>(null);
  final cnicBack = Rx<XFile?>(null);
  
  Future<XFile?> _pickImageToFile(ImageSource source) async {
    try {
      if (source == ImageSource.camera && !kIsWeb) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          _showErrorDialog(Get.context!, 'Camera permission is required to take a photo');
          return null;
        }
      }
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      return pickedFile;
    } catch (e) {
      _showErrorDialog(Get.context!, 'Failed to pick image: $e');
    }
    return null;
  }

  Future<void> pickDocumentWithOptions(BuildContext context, Rx<XFile?> targetFile) async {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  final file = await _pickImageToFile(ImageSource.camera);
                  if (file != null) targetFile.value = file;
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  final file = await _pickImageToFile(ImageSource.gallery);
                  if (file != null) targetFile.value = file;
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
      isDismissible: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<String> _uploadFileWithProgress(
      XFile file,
      String path,
      Function(double) onProgress,
      ) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final task = ref.putData(await file.readAsBytes());

    task.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      onProgress(progress);
    });

    final snapshot = await task;
    return snapshot.ref.fullPath;
  }

  Future<void> submitNewCnic(BuildContext context) async {
    if (cnicFront.value == null) {
      _showErrorDialog(context, 'Please upload ID front image');
      return;
    }

    if (cnicBack.value == null) {
      _showErrorDialog(context, 'Please upload ID back image');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorDialog(context, 'Authentication failed');
      return;
    }

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => SavingProgressWidget(
          task: (updateProgress) async {
            final userId = currentUser.uid;

            double overallProgress = 0.1;
            updateProgress(overallProgress);

            final cnicFrontUrl = await _uploadFileWithProgress(
              cnicFront.value!,
              'documents/cnic_front/$userId',
                  (progress) {
                updateProgress(0.1 + (progress * 0.4));
              },
            );

            overallProgress = 0.5;
            updateProgress(overallProgress);

            final cnicBackUrl = await _uploadFileWithProgress(
              cnicBack.value!,
              'documents/cnic_back/$userId',
                  (progress) {
                updateProgress(0.5 + (progress * 0.4));
              },
            );

            overallProgress = 0.9;
            updateProgress(overallProgress);

            await FirebaseFirestore.instance
                .collection('ServiceProviders')
                .doc(userId)
                .update({
              'cnicFront': cnicFrontUrl,
              'cnicBack': cnicBackUrl,
              'accountStatus': 'pending',
              'reason': '',
            });

            updateProgress(1.0);
            await Future.delayed(const Duration(milliseconds: 300));
          },
        ),
      );

      Get.offAll(() => const AccountVerificationScreen()); // Go back to the Account Verification screen where it should show the pending state.
      
      Get.snackbar(
        'Success',
        'Your documents have been re-uploaded successfully.',
        backgroundColor: AppColors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      _showErrorDialog(Get.context!, 'Failed to re-upload documents: ${e.toString()}');
    }
  }
}
