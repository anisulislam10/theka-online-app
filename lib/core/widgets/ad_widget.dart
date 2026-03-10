import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/ad_controller.dart';
import '../../models/ad_model.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class AdWidget extends StatefulWidget {
  final AdModel ad;
  final bool isSmall;
  final EdgeInsets? margin;

  const AdWidget({
    super.key, 
    required this.ad, 
    this.isSmall = false,
    this.margin,
  });

  @override
  State<AdWidget> createState() => _AdWidgetState();
}

class _AdWidgetState extends State<AdWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Track impression when the widget is initialized
    final AdController adController = Get.isRegistered<AdController>() 
        ? Get.find<AdController>() 
        : Get.put(AdController());
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      adController.trackImpression(widget.ad.id);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AdController adController = Get.find<AdController>();
    final Color bgColor = _parseColor(widget.ad.bgColor);
    final Color textColor = _parseColor(widget.ad.textColor);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () => adController.trackClick(widget.ad),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            constraints: BoxConstraints(
              minHeight: widget.isSmall ? 60.h : widget.ad.height.h,
            ),
            margin: widget.margin ?? EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: LinearGradient(
                colors: [
                  bgColor,
                  bgColor.withOpacity(0.85),
                  bgColor.withOpacity(0.95),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                // Main glow shadow
                BoxShadow(
                  color: bgColor.withOpacity(_isHovered ? 0.4 : 0.25),
                  blurRadius: _isHovered ? 20 : 12,
                  spreadRadius: _isHovered ? 2 : -2,
                  offset: const Offset(0, 8),
                ),
                // Subtle inner bottom shadow
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: Stack(
                children: [
                  // Decorative glass circles
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: -20,
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.04),
                      ),
                    ),
                  ),
                  
                  // AD Label (Positioned for "Perfection")
                  Positioned(
                    top: 10.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.5),
                      ),
                      child: SmartText(
                        title: "ad".tr.toUpperCase(),
                        size: 7.sp,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 16.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Company Logo with Premium Styling
                        if (widget.ad.companyLogo.isNotEmpty && widget.ad.companyLogo.startsWith('http'))
                          Container(
                            margin: EdgeInsets.only(right: 14.w),
                            width: widget.isSmall ? 42.w : 50.w,
                            height: widget.isSmall ? 42.w : 50.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.9),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25.r),
                              child: CachedNetworkImage(
                                imageUrl: widget.ad.companyLogo,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Center(
                                  child: SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(bgColor),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Icon(
                                  Icons.business,
                                  color: bgColor.withOpacity(0.6),
                                  size: widget.isSmall ? 20.sp : 24.sp,
                                ),
                              ),
                            ),
                          ),
                          
                        // Text Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title with FittedBox for "Perfect" horizontal fit
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 180.w),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: SmartText(
                                    title: widget.ad.title,
                                    size: widget.isSmall ? 13.sp : 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              SmartText(
                                title: widget.ad.description,
                                size: widget.isSmall ? 11.sp : 12.sp,
                                color: textColor.withOpacity(0.85),
                                maxLines: widget.isSmall ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                height: 1.2,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(width: 10.w),
                        
                        // Action Indicator
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 0.5,
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: textColor,
                            size: 8.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
