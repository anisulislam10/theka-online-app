import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          /// 🎨 Custom Gradient Header
          Container(
            // 🔹 Removed fixed height to allow dynamic sizing
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondary, AppColors.primary],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r),
                bottomRight: Radius.circular(30.r),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Center(
                        child: SmartText(
                          title: "about".tr,
                          size: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 48.w), // Balance for back button
                  ],
                ),
              ),
            ),
          ),

          /// 📄 About Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20.w),
              children: [
                _buildSectionTitle("Theka Online – Hire Faster, Get Hired Smarter"),
                _buildBodyText(
                  "Theka Online is your smart hiring and job-finding companion, designed to bridge the gap between employers and skilled workers in a fast, direct, and reliable way. Whether you are looking to hire a plumber, electrician, carpenter, painter, driver, cleaner, or any other skilled professional — Theka Online helps you find the right person at the right time.",
                ),
                _buildBodyText(
                  "Our platform is simple: Employers can browse detailed profiles of verified skilled workers and contact them instantly via phone or WhatsApp. Job seekers can create professional profiles showcasing their expertise, making it easy for employers to find and hire them without complicated processes.",
                ),
                
                const Divider(),
                
                _buildSectionTitle("For Employers"),
                _buildBulletPoint("Discover Skilled Workers – Search across multiple job categories to find exactly who you need."),
                _buildBulletPoint("View Detailed Profiles – Check skills, work experience, and specialties at a glance."),
                _buildBulletPoint("Instant Communication – Contact workers directly via phone call or WhatsApp—no delays."),
                _buildBulletPoint("Save Time – Skip middlemen and slow hiring processes. Connect directly to the talent."),
                _buildBulletPoint("Local Talent Access – Quickly find workers in your city or nearby areas."),

                const Divider(),

                _buildSectionTitle("For Job Seekers"),
                _buildBulletPoint("Create a Professional Profile – Highlight your work history, special skills, and services."),
                _buildBulletPoint("Get Discovered by Employers – Your profile appears to employers searching in your area."),
                _buildBulletPoint("Direct Calls from Employers – Receive job opportunities instantly via phone or WhatsApp."),
                _buildBulletPoint("Grow Your Career – Build connections with verified employers for long-term work."),
                _buildBulletPoint("Boost Visibility – Update your profile regularly to stay at the top of search results."),

                const Divider(),

                _buildSectionTitle("Key Features"),
                _buildBulletPoint("Profile Browsing – Clear, organized worker profiles for quick decision-making."),
                _buildBulletPoint("Instant Connect – Call or WhatsApp from within the app in just one tap."),
                _buildBulletPoint("Easy Navigation – Simple UI, category-based search, and powerful filtering."),
                _buildBulletPoint("Multilingual Support – English and Urdu support, with more languages coming soon."),
                _buildBulletPoint("Privacy-First – Your exact location is never publicly shared."),
                _buildBulletPoint("Lightweight & Fast – Optimized for low internet usage and quick performance."),
                _buildBulletPoint("Regular Updates – Constant improvements and new features based on your feedback."),

                const Divider(),

                _buildSectionTitle("How It Works"),
                _buildBulletPoint("Employers: Select a category → browse profiles → contact workers directly."),
                _buildBulletPoint("Job Seekers: Create/complete your profile → appear in search results → get contacted by employers."),

                const Divider(),

                _buildSectionTitle("Who It’s For"),
                _buildBulletPoint("Employers & Contractors – Find reliable workers without wasting time."),
                _buildBulletPoint("Businesses – Hire skilled labor for projects, repairs, or ongoing work."),
                _buildBulletPoint("Homeowners – Quickly find trusted workers for home maintenance and improvement."),
                _buildBulletPoint("Job Seekers – Gain visibility, get direct calls, and secure more jobs."),

                const Divider(),

                _buildSectionTitle("Why Choose Theka Online?"),
                _buildBulletPoint("Direct Communication – No complicated chat systems. Call or message instantly."),
                _buildBulletPoint("Verified Listings – We work to ensure profiles are accurate and trustworthy."),
                _buildBulletPoint("Transparent Information – Skills, experience, and contact options at your fingertips."),
                _buildBulletPoint("Save Time & Effort – Find or be found within minutes, not days."),
                _buildBulletPoint("Works Everywhere – Whether in big cities or smaller towns, Theka Online is built for you."),

                const Divider(),

                _buildSectionTitle("Privacy & Security"),
                _buildBodyText("Your trust matters."),
                _buildBulletPoint("We never share your exact location publicly."),
                _buildBulletPoint("Personal details are shown only as part of your public profile if you choose to share them."),
                _buildBulletPoint("We use your data only to improve and deliver our services."),
                _buildBulletPoint("You control what appears on your profile at any time."),
                
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: SmartText(
        title: title,
        size: 18.sp,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: SmartText(
        title: text,
        size: 14.sp,
        color: Colors.black87,
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, left: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Icon(Icons.circle, size: 6.sp, color: AppColors.secondary),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: SmartText(
              title: text,
              size: 14.sp,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
