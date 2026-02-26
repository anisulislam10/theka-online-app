import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:quickserve/core/constants/appColors.dart';
import 'package:quickserve/core/constants/appTexts.dart';

enum ReviewRole { customer, provider }

class ReviewsController extends GetxController {
  final String userId;
  final ReviewRole role;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  RxList<Map<String, dynamic>> reviews = <Map<String, dynamic>>[].obs;
  RxBool isLoading = true.obs;

  ReviewsController({required this.userId, required this.role});

  @override
  void onInit() {
    super.onInit();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    try {
      isLoading.value = true;
      debugPrint('🔍 Fetching reviews for $userId as $role');
      
      Query query;
      if (role == ReviewRole.customer) {
        // Fetch ALL completed requests for this customer
        query = _firestore
            .collection('completedRequests')
            .where('userId', isEqualTo: userId);
      } else {
        // Fetch ALL completed requests for this provider
        query = _firestore
            .collection('completedRequests')
            .where('providerId', isEqualTo: userId);
      }

      final snapshot = await query.get();
      debugPrint('📦 Found ${snapshot.docs.length} total completed requests');

      List<Map<String, dynamic>> allReviews = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        if (role == ReviewRole.customer) {
          // Look for reviews given BY providers TO this customer
          if (data['providerRating'] != null) {
            allReviews.add(data);
          }
        } else {
          // Look for reviews given BY customers TO this provider
          if (data['customerRating'] != null) {
            allReviews.add(data);
          }
        }
      }

      // Sort in memory: newest first
      allReviews.sort((a, b) {
        final timestampA = (role == ReviewRole.customer ? a['ratedAt'] : a['ratedByCustomerAt']) as Timestamp?;
        final timestampB = (role == ReviewRole.customer ? b['ratedAt'] : b['ratedByCustomerAt']) as Timestamp?;
        
        if (timestampA == null) return 1;
        if (timestampB == null) return -1;
        return timestampB.compareTo(timestampA);
      });

      debugPrint('✅ Filtered to ${allReviews.length} records with ratings');
      reviews.value = allReviews;
    } catch (e) {
      debugPrint('❌ Error fetching reviews: $e');
      Get.snackbar('Error', 'failed_to_load_reviews'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
    }
    return '';
  }
}

class ReviewsPage extends StatelessWidget {
  final String userId;
  final String name;
  final ReviewRole role;

  const ReviewsPage({
    super.key,
    required this.userId,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReviewsController(userId: userId, role: role), tag: userId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: SmartText(
          title: "${'reviews_for'.tr} $name",
          size: 18.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (controller.reviews.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.fetchReviews,
            child: ListView(
              children: [
                SizedBox(height: 100.h),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 80.sp, color: Colors.grey[300]),
                      SizedBox(height: 16.h),
                      SmartText(
                        title: "no_reviews_yet".tr,
                        size: 16.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8.h),
                      TextButton(
                        onPressed: controller.fetchReviews,
                        child: Text('Refresh'.tr),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchReviews,
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: controller.reviews.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final review = controller.reviews[index];
              final int rating = ((role == ReviewRole.customer 
                  ? (review['providerRating'] ?? 0)
                  : (review['customerRating'] ?? 0)) as num).toInt();
              
              final String comment = (role == ReviewRole.customer 
                  ? review['providerReview'] 
                  : review['customerReview']) ?? '';
              
              final String reviewerName = (role == ReviewRole.customer 
                  ? review['providerName'] 
                  : review['userName']) ?? 'User';
              
              final dynamic timestamp = role == ReviewRole.customer 
                  ? review['ratedAt'] 
                  : review['ratedByCustomerAt'];

              return Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SmartText(
                              title: reviewerName,
                              size: 15.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SmartText(
                            title: controller.formatTimestamp(timestamp),
                            size: 11.sp,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: List.generate(5, (i) {
                          return Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16.sp,
                          );
                        }),
                      ),
                      if (comment.isNotEmpty) ...[
                        SizedBox(height: 10.h),
                        SmartText(
                          title: comment,
                          size: 13.sp,
                          color: Colors.black87,
                          maxLines: 10,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
