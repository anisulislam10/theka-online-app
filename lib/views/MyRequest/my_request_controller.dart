import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:quickserve/core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class MyRequestController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable list for completed requests
  RxList<Map<String, dynamic>> completedRequests = <Map<String, dynamic>>[].obs;

  // Loading state
  RxBool isLoading = false.obs;
  RxBool isSubmittingRating = false.obs;

  // User/Customer ID
  RxString userId = ''.obs;

  // Stream subscription
  StreamSubscription<QuerySnapshot>? _completedRequestsSubscription;
  
  // Track if this is first load (to avoid showing notification on initial load)
  bool _isFirstLoad = true;

  @override
  void onInit() {
    super.onInit();
    initializeController();
  }

  /// Initialize controller
  Future<void> initializeController() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      userId.value = uid;
      listenToCompletedRequests();
    }
  }

  /// Listen to completed requests in real-time
  void listenToCompletedRequests() {
    try {
      isLoading.value = true;
      print('🔄 Starting listener for completed requests...');
      print('🎯 User ID: ${userId.value}');

      _completedRequestsSubscription = _firestore
          .collection('completedRequests')
          .where('userId', isEqualTo: userId.value)
          .orderBy('acceptedAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              List<Map<String, dynamic>> tempList = [];

              print('📦 Received ${snapshot.docs.length} completed requests');

              // Check for new requests (only show notification after first load)
              if (!_isFirstLoad) {
                for (var change in snapshot.docChanges) {
                  if (change.type == DocumentChangeType.added) {
                    _showRequestAcceptedNotification(change.doc.data()!);
                  }
                }
              }
              
              _isFirstLoad = false;

              for (var doc in snapshot.docs) {
                Map<String, dynamic> data = doc.data();
                data['docId'] = doc.id; // Store document ID
                tempList.add(data);
              }

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

  /// Submit rating for service provider
  Future<void> submitProviderRating({
    required String requestDocId,
    required String providerId,
    required int rating,
    required String review,
  }) async {
    try {
      isSubmittingRating.value = true;

      // 🔹 1. Get old rating BEFORE updating the document
      final requestSnapshot = await _firestore
          .collection('completedRequests')
          .doc(requestDocId)
          .get();
      final requestData = requestSnapshot.data() as Map<String, dynamic>?;
      final int? oldRating = requestData?['customerRating'] as int?;

      // 🔹 2. Update the completed request document
      await _firestore.collection('completedRequests').doc(requestDocId).update(
        {
          'customerRating': rating, // Customer's rating of provider
          'customerReview': review, // Customer's review of provider
          'ratedByCustomerAt': FieldValue.serverTimestamp(),
        },
      );

      // Get service provider document reference
      DocumentReference providerRef = _firestore
          .collection('ServiceProviders')
          .doc(providerId);

      // Get current provider data
      DocumentSnapshot providerDoc = await providerRef.get();

      if (providerDoc.exists) {
        Map<String, dynamic> providerData =
            providerDoc.data() as Map<String, dynamic>;

        // Calculate new rating
        int totalRatings = providerData['totalRatings'] ?? 0;
        double currentRating = (providerData['rating'] ?? 0.0).toDouble();

        double newRating;
        int newTotalRatings;

        if (oldRating != null) {
          // If already rated, replace the old rating in the average
          newTotalRatings = totalRatings > 0 ? totalRatings : 1;
          newRating = ((currentRating * totalRatings) - oldRating + rating) / newTotalRatings;
        } else {
          // If not rated, add new rating to the average
          newTotalRatings = totalRatings + 1;
          newRating = ((currentRating * totalRatings) + rating) / newTotalRatings;
        }

        // Update provider document
        await providerRef.update({
          'rating': newRating,
          'totalRatings': newTotalRatings,
        });
      } else {
        // If provider doesn't have rating fields, create them
        await providerRef.set({
          'rating': rating.toDouble(),
          'totalRatings': 1,
        }, SetOptions(merge: true));
      }

      isSubmittingRating.value = false;
      
      // CLOSE BOTTOM SHEET FIRST
      Get.back();
      
      // THEN SHOW SUCCESS message after a tiny delay to ensure navigation completes
      Future.delayed(const Duration(milliseconds: 200), () {
        Get.snackbar(
          'Success',
          'your_rating_submitted'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      });
      
      print('✅ Rating submitted and bottom sheet closed');
    } catch (e) {
      isSubmittingRating.value = false;
      print('❌ Error submitting rating: $e');
      Get.snackbar(
        'Error',
        'Failed to submit rating: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
    }
  }

  /// Show notification when request is accepted
  void _showRequestAcceptedNotification(Map<String, dynamic> requestData) {
    final providerName = requestData['providerName'] ?? 'Service Provider';
    final service = requestData['service'] ?? 'service';

    debugPrint('🎉 New request accepted! Showing notification...');
    debugPrint('   Provider: $providerName');
    debugPrint('   Service: $service');

    // Show notification directly
    NotificationService().showSimpleNotification(
      title: '🎉 Request Accepted!',
      body: '$providerName has accepted your $service request.',
      payload: 'request_accepted',
    );
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

      // Full Format Example: Jan 25, 2025 - 08:45 PM
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
