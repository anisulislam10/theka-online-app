import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color textColor;
  final double borderRadius;
  final double fontSize;
  final double height;
  final double width;
  final bool isLoading;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final bool outlined;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.borderRadius = 15.0,
    this.fontSize = 16.0,
    this.height = 50.0,
    this.width = double.infinity,
    this.isLoading = false,
    this.icon,
    this.iconColor,
    this.iconSize,
    this.fontWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveBackground =
        backgroundColor ?? AppColors.primary; // ✅ Use default primary color

    return SizedBox(
      width: width,
      height: height.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: outlined ? Colors.transparent : effectiveBackground,
          foregroundColor: textColor,

          // ✅ Prevent button turning white when disabled (loading)
          disabledBackgroundColor: outlined
              ? Colors.transparent
              : effectiveBackground,
          disabledForegroundColor: textColor,

          side: outlined
              ? BorderSide(color: effectiveBackground, width: 2)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius.r),
          ),
          padding: padding,
        ),

        child: isLoading
            ? SizedBox(
                height: 22.w,
                width: 22.w,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: iconColor ?? textColor,
                      size: iconSize ?? 22.sp,
                    ),
                    SizedBox(width: 8.w),
                  ],
                  SmartText(
                    title: text,
                    size: fontSize.sp,
                    color: textColor,
                    fontWeight: fontWeight,
                  ),
                ],
              ),
      ),
    );
  }
}

class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 22.w,
                width: 22.w,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: AppColors.primary, size: 22.sp),
                    SizedBox(width: 8.w),
                  ],
                  SmartText(
                    title: text,
                    size: 16.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
      ),
    );
  }
}
