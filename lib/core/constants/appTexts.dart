// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:google_fonts/google_fonts.dart';

// class InterText extends StatelessWidget {
//   final String title;
//   final double? size;
//   final Color? color;
//   final FontWeight? fontWeight;
//   final double? letterSpacing;
//   final TextAlign? textAlign;
//   final int? maxLines;
//   final TextOverflow? overflow;
//   final double? height;
//   final TextDecoration? decoration;

//   const InterText({
//     super.key,
//     required this.title,
//     this.size,
//     this.color,
//     this.fontWeight,
//     this.letterSpacing,
//     this.textAlign,
//     this.maxLines,
//     this.overflow,
//     this.height,
//     this.decoration,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       title,
//       textAlign: textAlign ?? TextAlign.start,
//       maxLines: maxLines,
//       overflow: overflow,
//       style: GoogleFonts.inter(
//         fontSize: (size ?? 14).sp,
//         color: color ?? Colors.black,
//         fontWeight: fontWeight ?? FontWeight.w400,
//         letterSpacing: letterSpacing,
//         height: height,
//       ),
//     );
//   }
// }

// class UrduText extends StatelessWidget {
//   final String title;
//   final double? size;
//   final Color? color;
//   final FontWeight? fontWeight;
//   final double? height;
//   final TextAlign? textAlign;

//   const UrduText({
//     super.key,
//     required this.title,
//     this.size,
//     this.color,
//     this.fontWeight,
//     this.height,
//     this.textAlign,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       title,
//       textAlign: textAlign ?? TextAlign.right,
//       style: TextStyle(
//         fontFamily: "Jameel",
//         fontSize: (size ?? 18).sp,
//         color: color ?? Colors.black,
//         fontWeight: fontWeight ?? FontWeight.w400,
//         height: height,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SmartText extends StatelessWidget {
  final String title;
  final double? size;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;
  final double? letterSpacing;

  const SmartText({
    super.key,
    required this.title,
    this.size,
    this.color,
    this.fontWeight,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.height,
    this.letterSpacing,
  });

  bool get isUrdu => Get.locale?.languageCode == 'ur';

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: textAlign ?? (isUrdu ? TextAlign.right : TextAlign.left),
      maxLines: maxLines,
      overflow: overflow,
      style: isUrdu
          ? TextStyle(
              fontFamily: "Jameel",
              fontSize: (size ?? 16).sp,
              color: color ?? Colors.black,
              fontWeight: fontWeight ?? FontWeight.w400,
              height: height,
              letterSpacing: letterSpacing,
            )
          : GoogleFonts.inter(
              fontSize: (size ?? 16).sp,
              color: color ?? Colors.black,
              fontWeight: fontWeight ?? FontWeight.w400,
              height: height,
              letterSpacing: letterSpacing,
            ),
    );
  }
}
