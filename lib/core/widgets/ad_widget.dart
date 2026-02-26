import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/ad_controller.dart';
import '../../models/ad_model.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class AdWidget extends StatelessWidget {
  final AdModel ad;
  final bool isSmall;

  const AdWidget({super.key, required this.ad, this.isSmall = false});

  @override
  Widget build(BuildContext context) {
    // If the controller isn't registered yet, we need to handle it
    // Usually, it's put in bindings or main, but we can Get.find or Get.put
    final AdController controller = Get.isRegistered<AdController>() 
        ? Get.find<AdController>() 
        : Get.put(AdController());
    
    // Track impression when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.trackImpression(ad.id);
    });

    return InkWell(
      onTap: () => controller.trackClick(ad),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          minHeight: isSmall ? 60.h : ad.height.h,
        ),
        margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: _parseColor(ad.bgColor).withOpacity(0.9),
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            colors: [
              _parseColor(ad.bgColor),
              _parseColor(ad.bgColor).withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _parseColor(ad.bgColor).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          "AD",
                          style: TextStyle(
                            color: _parseColor(ad.textColor),
                            fontSize: 8.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: SmartText(
                          title: ad.title,
                          size: isSmall ? 13.sp : 15.sp,
                          fontWeight: FontWeight.bold,
                          color: _parseColor(ad.textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  SmartText(
                    title: ad.description,
                    size: isSmall ? 11.sp : 12.sp,
                    color: _parseColor(ad.textColor).withOpacity(0.9),
                    maxLines: isSmall ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: 10.w),
            Icon(
              Icons.open_in_new,
              color: _parseColor(ad.textColor),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexColor) {
    try {
      String hex = hexColor.toUpperCase().replaceAll("#", "");
      if (hex.length == 6) {
        hex = "FF$hex";
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return Colors.blue;
    }
  }
}
