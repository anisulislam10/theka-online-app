import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/views/BottomNavbar/bottom_navbar.dart';
import 'package:quickserve/views/Auth/AccountScreens/reupload_cnic_page.dart';
import 'package:quickserve/core/widgets/custom_button.dart';

class AccountVerificationScreen extends StatefulWidget {
  const AccountVerificationScreen({super.key});

  @override
  State<AccountVerificationScreen> createState() =>
      _AccountVerificationScreenState();
}

class _AccountVerificationScreenState extends State<AccountVerificationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String verificationStatus = 'pending';
  String reason = ''; // ✅ Add this

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 20,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _listenToVerificationStatus();
  }

  void _listenToVerificationStatus() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint("⚠️ No logged-in user found.");
      return;
    }

    debugPrint("Current User ID: $userId");

    _firestore.collection('ServiceProviders').doc(userId).snapshots().listen((
      snapshot,
    ) {
      if (!snapshot.exists) {
        debugPrint("⚠️ ServiceProvider document not found for $userId");
        return;
      }

      final data = snapshot.data();
      final status = (data?['accountStatus'] ?? 'pending')
          .toString()
          .trim()
          .toLowerCase();
      final fetchedReason = (data?['reason'] ?? '').toString().trim();

      debugPrint("📡 Account status update: $status");
      debugPrint("📝 Reason from Firestore: $fetchedReason");
      debugPrint("👀 Current route: ${Get.currentRoute}");

      if (!mounted) return;

      setState(() {
        verificationStatus = status;
        reason = fetchedReason;
      });

      // ✅ Navigate to BottomNavbar when accepted
      if (status == 'accepted') {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted && Get.currentRoute != '/BottomNavbar') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              debugPrint("🚀 Navigating to BottomNavbar...");
              Get.offAll(() => const BottomNavbar());
            });
          }
        });
      } else if (status == 'declined' || status == 'rejected') {
        _controller.stop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRejected = verificationStatus == 'declined' || verificationStatus == 'rejected';

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
          child: Center(
            child: isRejected
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, color: Colors.redAccent, size: 100.r),
                      SizedBox(height: 20.h),

                      Text(
                        "verification_declined".tr,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 15.h),

                      if (reason.isNotEmpty)
                        Container(
                          padding: EdgeInsets.all(15.r),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "rejection_reason_label".tr,
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                reason,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          "verification_declined_message".tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16.sp,
                            height: 1.5,
                          ),
                        ),
                      SizedBox(height: 30.h),
                      CustomButton(
                        text: "reupload_documents".tr,
                        icon: Icons.upload_file,
                        backgroundColor: AppColors.white,
                        textColor: AppColors.primary,
                        onPressed: () {
                          Get.to(() => ReuploadCnicPage());
                        },
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, -_animation.value),
                            child: Text(
                              "⏳",
                              style: TextStyle(fontSize: 120.sp),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 35.h),
                      Text(
                        "verification_pending".tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "verification_pending_message".tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 16.sp,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 40.h),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
