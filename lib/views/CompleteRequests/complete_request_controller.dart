import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class CompleteRequestController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable list for completed requests
  RxList<Map<String, dynamic>> completedRequests = <Map<String, dynamic>>[].obs;

  // Loading state
  RxBool isLoading = false.obs;
  RxBool isSubmittingRating = false.obs;

  // Provider ID
  RxString providerId = ''.obs;

  // Stream subscription
  StreamSubscription<QuerySnapshot>? _completedRequestsSubscription;

  @override
  void onInit() {
    super.onInit();
    initializeController();
  }

  /// Initialize controller
  Future<void> initializeController() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      providerId.value = uid;
      listenToCompletedRequests();
    }
  }

  /// Listen to completed requests in real-time
  void listenToCompletedRequests() {
    try {
      isLoading.value = true;
      print('🔄 Starting listener for completed requests...');
      print('🎯 Provider ID: ${providerId.value}');

      _completedRequestsSubscription = _firestore
          .collection('completedRequests')
          .where('providerId', isEqualTo: providerId.value)
          .orderBy('acceptedAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              List<Map<String, dynamic>> tempList = [];

              print('📦 Received ${snapshot.docs.length} completed requests');
              print('🔍 SNAPSHOT DEBUG:');
              print('   - Total docs: ${snapshot.docs.length}');
              print('   - Snapshot metadata: ${snapshot.metadata}');

              for (var doc in snapshot.docs) {
                print('');
                print('   ╔════════════════════════════════════');
                print('   ║ Processing Document: ${doc.id}');
                print('   ╚════════════════════════════════════');

                Map<String, dynamic> data = doc.data();
                data['docId'] = doc.id; // Store document ID

                print('   📄 Doc ${doc.id}:');
                print('      - ALL FIELDS: ${data.keys.toList()}');
                print('      - providerRating: ${data['providerRating']}');
                print('      - providerReview: ${data['providerReview']}');
                print('      - customerRating: ${data['customerRating']}');
                print('      - customerReview: ${data['customerReview']}');
                print('      - ratedAt: ${data['ratedAt']}');
                print(
                  '      - ratedByCustomerAt: ${data['ratedByCustomerAt']}',
                );

                tempList.add(data);
              }

              print('');
              print('✅ Final tempList length: ${tempList.length}');
              print('✅ Setting completedRequests.value...');

              completedRequests.value = tempList;
              isLoading.value = false;
              print('✅ Completed requests updated: ${tempList.length} total');
            },
            onError: (error) {
              print('❌ Error in completed requests listener: $error');
              isLoading.value = false;
              Get.snackbar(
                'Error',
                'Failed to load completed requests: $error',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          );
    } catch (e) {
      print('❌ Error setting up completed requests listener: $e');
      isLoading.value = false;
    }
  }

  /// Submit rating for customer
  Future<void> submitCustomerRating({
    required String requestDocId,
    required String customerId,
    required int rating,
    required String review,
  }) async {
    try {
      print('');
      print('═════════════════════════════════════');
      print('⭐ STARTING RATING SUBMISSION');
      print('═════════════════════════════════════');
      print('📝 Request Doc ID: $requestDocId');
      print('👤 Customer ID: $customerId');
      print('⭐ Rating: $rating');
      print('💬 Review: $review');

      isSubmittingRating.value = true;

      // 🔹 1. Get old rating BEFORE updating the document
      final requestSnapshot = await _firestore
          .collection('completedRequests')
          .doc(requestDocId)
          .get();
      final requestData = requestSnapshot.data() as Map<String, dynamic>?;
      final int? oldRating = requestData?['providerRating'] as int?;

      // 🔹 2. Update the completed request document with rating
      await _firestore
          .collection('completedRequests')
          .doc(requestDocId)
          .update({
            'providerRating': rating,
            'providerReview': review,
            'ratedAt': FieldValue.serverTimestamp(),
          });
      print('✅ Document updated successfully!');

      // Get customer document reference
      print('');
      print('📤 Step 2: Updating customer rating...');
      DocumentReference customerRef = _firestore
          .collection('Customers')
          .doc(customerId);

      // Get current customer data
      DocumentSnapshot customerDoc = await customerRef.get();

      if (customerDoc.exists) {
        Map<String, dynamic> customerData =
            customerDoc.data() as Map<String, dynamic>;

        print('   Current customer rating: ${customerData['rating']}');
        print('   Current total ratings: ${customerData['totalRatings']}');

        int totalRatings = customerData['totalRatings'] ?? 0;
        double currentRating = (customerData['rating'] ?? 0.0).toDouble();

        double newRating;
        int newTotalRatings;

        if (oldRating != null) {
          // If already rated, replace the old rating in the average
          print('   ⚠️ Request was already rated ($oldRating). Updating average...');
          newTotalRatings = totalRatings > 0 ? totalRatings : 1;
          newRating = ((currentRating * totalRatings) - oldRating + rating) / newTotalRatings;
        } else {
          // If not rated, add new rating to the average
          newTotalRatings = totalRatings + 1;
          newRating = ((currentRating * totalRatings) + rating) / newTotalRatings;
        }

        print('   New rating: $newRating');
        print('   New total ratings: $newTotalRatings');

        // Update customer document
        await customerRef.update({
          'rating': newRating,
          'totalRatings': newTotalRatings,
        });
        print('✅ Customer rating updated!');
      } else {
        print('⚠️ Customer document does not exist, creating rating fields...');
        // If customer doesn't have rating fields, create them
        await customerRef.set({
          'rating': rating.toDouble(),
          'totalRatings': 1,
        }, SetOptions(merge: true));
        print('✅ Customer rating fields created!');
      }

      isSubmittingRating.value = false;

      print('');
      print('✅ RATING SUBMISSION COMPLETE');
      print('═════════════════════════════════════');
      print('');

      Get.back(); // Close rating bottom sheet
      Get.back(); // Close request details bottom sheet
      
      Future.delayed(const Duration(milliseconds: 200), () {
        Get.snackbar(
          'Success',
          'your_rating_submitted'.tr,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      });

      // Add a small delay to ensure the listener picks up the change
      await Future.delayed(Duration(milliseconds: 500));
      print('⏳ Waiting for listener to update...');
    } catch (e) {
      isSubmittingRating.value = false;
      print('');
      print('❌ ERROR SUBMITTING RATING');
      print('═════════════════════════════════════');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      print('═════════════════════════════════════');
      print('');

      Get.snackbar(
        'Error',
        'Failed to submit rating: $e',
        backgroundColor: Colors.red,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Manual refresh
  Future<void> refreshCompletedRequests() async {
    print('🔄 Manual refresh triggered');
    // Real-time listener will automatically update
  }

  /// Format timestamp for display
  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    try {
      DateTime dateTime;

      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'N/A';
      }

      return DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
    } catch (e) {
      print('Error formatting timestamp: $e');
      return 'N/A';
    }
  }

  @override
  void onClose() {
    // Cancel stream subscription
    _completedRequestsSubscription?.cancel();
    super.onClose();
  }
}
