import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/utils.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class SavingProgressWidget extends StatefulWidget {
  final Future<void> Function(Function(double) updateProgress) task;

  const SavingProgressWidget({super.key, required this.task});

  @override
  State<SavingProgressWidget> createState() => _SavingProgressWidgetState();
}

class _SavingProgressWidgetState extends State<SavingProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double progress = 0.0;
  bool _taskCompleted = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: -15,
      end: 15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Run the actual task with progress callback
    _runTask();
  }

  Future<void> _runTask() async {
    try {
      await widget.task(_updateProgress);

      if (!mounted) return;

      // Mark task as completed
      _taskCompleted = true;

      // Ensure we show 100% briefly before closing
      setState(() => progress = 100.0);

      // Wait a moment for user to see 100%
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && _taskCompleted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // If there's an error, close the dialog and let the error propagate
      if (mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }

  void _updateProgress(double value) {
    if (mounted && !_taskCompleted) {
      setState(() {
        progress = (value * 100).clamp(0.0, 100.0);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent dismissing by back button during save
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 180.h,
            width: 220.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(25.r),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _animation.value),
                      child: Icon(
                        Icons.cloud_upload_rounded,
                        size: 55.sp,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
                SizedBox(height: 20.h),
                SmartText(
                  title: "saving_data".tr,
                  size: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),

                SizedBox(height: 8.h),
                Text(
                  '${progress.toInt()}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.white.withOpacity(0.9),
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
