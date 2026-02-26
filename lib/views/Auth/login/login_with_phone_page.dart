import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:flutter/services.dart';
import 'package:quickserve/views/BottomNavbar/bottom_navbar.dart';

class LoginWithPhonePage extends StatefulWidget {
  const LoginWithPhonePage({super.key});

  @override
  State<LoginWithPhonePage> createState() => _LoginWithPhonePageState();
}

class _LoginWithPhonePageState extends State<LoginWithPhonePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  String verificationId = "";
  bool isOTPSent = false;
  bool isLoading = false;

  // Send OTP to phone number
  Future<void> sendOTP() async {
    if (phoneController.text.trim().length != 10) {
      Get.snackbar(
        "Invalid Number",
        "Please enter a 10-digit number",
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => isLoading = true);
    String fullPhoneNumber = "+92${phoneController.text.trim()}";

    await _auth.verifyPhoneNumber(
      phoneNumber: fullPhoneNumber,
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        setState(() => isLoading = false);
        Get.snackbar(
          "Error",
          e.message ?? "Failed",
          backgroundColor: AppColors.red,
          colorText: Colors.white,
        );
      },
      codeSent: (verId, _) {
        verificationId = verId;
        setState(() {
          isOTPSent = true;
          isLoading = false;
        });
        Get.snackbar(
          "Success",
          "OTP sent successfully!",
          backgroundColor: AppColors.green,
          colorText: Colors.white,
        );
      },
      codeAutoRetrievalTimeout: (verId) {
        verificationId = verId;
      },
    );
  }

  // Verify OTP
  Future<void> verifyOTP() async {
    if (otpController.text.trim().length != 6) {
      Get.snackbar(
        "Invalid OTP",
        "Please enter the 6-digit OTP",
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpController.text.trim(),
      );

      await _auth.signInWithCredential(credential);
      Get.to(() => BottomNavbar());
      Get.snackbar(
        "Success",
        "Logged in successfully!",
        backgroundColor: AppColors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        e.toString(),
        backgroundColor: AppColors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Login with Phone",
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  "Enter your phone number to receive OTP",
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30.h),

                // Phone number input with fixed +92 prefix
                Row(
                  children: [
                    Container(
                      height: 56.h,
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15.r),
                          bottomLeft: Radius.circular(15.r),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "+92",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "3123456789",
                          filled: true,
                          hintStyle: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[500],
                          ),
                          fillColor: Colors.grey[100],
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 15.h,
                            horizontal: 15.w,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(15.r),
                              bottomRight: Radius.circular(15.r),
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // OTP input if sent
                if (isOTPSent) ...[
                  SizedBox(height: 20.h),
                  Pinput(
                    length: 6,
                    controller: otpController,
                    defaultPinTheme: PinTheme(
                      width: 50.w,
                      height: 55.h,
                      textStyle: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 50.w,
                      height: 55.h,
                      textStyle: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 30.h),
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : isOTPSent
                        ? verifyOTP
                        : sendOTP,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      backgroundColor: AppColors.primary,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isOTPSent ? "Verify OTP" : "Send OTP",
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
