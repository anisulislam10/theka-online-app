import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../../BottomNavbar/bottom_navbar.dart';
import 'package:quickserve/core/services/notification_service.dart'; // Import NotificationService

class OrdersController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable lists for requests
  RxList<Map<String, dynamic>> nowRequests = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> anytimeRequests = <Map<String, dynamic>>[].obs;

  // Loading states
  RxBool isLoadingNow = false.obs;
  RxBool isLoadingAnytime = false.obs;
  RxBool isAcceptingRequest = false.obs;

  // Online/Offline status
  RxBool isOnline = false.obs;

  // Selected tab (0 = Now, 1 = Anytime)
  RxInt selectedTab = 0.obs;

  // Provider's service category and details
  RxString providerServiceCategory = ''.obs;
  RxString providerName = ''.obs;
  RxString providerId = ''.obs;
  RxString providerPhone = ''.obs;
  RxString providerProfileImage = ''.obs;

  // Stream subscriptions
  StreamSubscription<QuerySnapshot>? _nowSubscription;
  StreamSubscription<QuerySnapshot>? _anytimeSubscription;

  // Flags to prevent notification on initial load
  bool _isFirstLoadNow = true;
  bool _isFirstLoadAnytime = true;

  @override
  void onInit() {
    super.onInit();
    print('🎮 OrdersController onInit called');
    initializeController();
  }

  /// Initialize controller - fetch provider category then start listening
  Future<void> initializeController() async {
    await fetchProviderServiceCategory();
    if (providerServiceCategory.value.isNotEmpty) {
      listenToNowRequests();
      listenToAnytimeRequests();
    }
  }

  /// Fetch current provider's service category and details
  Future<void> fetchProviderServiceCategory() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        print('❌ No user logged in');
        return;
      }

      providerId.value = uid;

      DocumentSnapshot providerDoc = await _firestore
          .collection('ServiceProviders')
          .doc(uid)
          .get();

      if (providerDoc.exists) {
        Map<String, dynamic> data = providerDoc.data() as Map<String, dynamic>;
        providerServiceCategory.value = data['serviceCategory'] ?? '';
        providerName.value = data['name'] ?? '';
        providerPhone.value = data['phone'] ?? '';
        providerProfileImage.value = data['profileImage'] ?? '';
        isOnline.value = data['isOnline'] ?? false; // ✅ Sync online status

        print('✅ Provider Details:');
        print('   Name: ${providerName.value}');
        print('   Category: ${providerServiceCategory.value}');
        print('   Phone: ${providerPhone.value}');
        print('   Online: ${isOnline.value}');
      }
    } catch (e) {
      print('❌ Error fetching provider category: $e');
      Get.snackbar(
        'Error',
        'Failed to fetch your service category: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Listen to "Now" requests in real-time (filtered by provider's category)
  void listenToNowRequests() {
    try {
      // Create new subscription if not exists
      _nowSubscription?.cancel();
      
      isLoadingNow.value = true;
      print('🔄 Starting real-time listener for Now requests...');
      print('🎯 Filtering by service: ${providerServiceCategory.value}');

      _nowSubscription = _firestore
          .collectionGroup('Now')
          .where('service', isEqualTo: providerServiceCategory.value)
          .where('status', isEqualTo: 'pending') // Only show pending requests
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
          List<Map<String, dynamic>> tempList = [];

          print('📦 Received ${snapshot.docs.length} Now requests');

          // Check for new additions (Notification Trigger)
          if (!_isFirstLoadNow) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data() as Map<String, dynamic>;
                // Trigger Notification
                NotificationService().showSimpleNotification(
                  title: 'New Service Request!',
                  body: 'A new ${data['service'] ?? 'service'} request is available near you.',
                  payload: 'new_request_now',
                );
              }
            }
          }
          _isFirstLoadNow = false; // Mark initial load as done

          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            data['requestType'] = 'Now';

            // Extract userId from document path
            String path = doc.reference.path;
            List<String> pathParts = path.split('/');
            if (pathParts.length >= 2) {
              data['userId'] = pathParts[1];
            }

            print('   ✅ ${data['service']} - ${data['userName'] ?? 'User'}');
            tempList.add(data);
          }

          nowRequests.value = tempList;
          isLoadingNow.value = false;
          print('✅ Now requests updated: ${tempList.length} total');
        },
        onError: (error) {
          print('❌ Error in Now requests listener: $error');
          print('🔗 POTENTIAL MISSING INDEX: If you see a URL above, click it to create the index!');
          isLoadingNow.value = false;
        },
      );
    } catch (e) {
      print('❌ Error setting up Now requests listener: $e');
      isLoadingNow.value = false;
    }
  }

  /// Listen to "Anytime" requests in real-time (filtered by provider's category)
  void listenToAnytimeRequests() {
    try {
      // Create new subscription if not exists
      _anytimeSubscription?.cancel();

      isLoadingAnytime.value = true;
      print('🔄 Starting real-time listener for Anytime requests...');
      print('🎯 Filtering by service: ${providerServiceCategory.value}');

      _anytimeSubscription = _firestore
          .collectionGroup('AnyTime')
          .where('service', isEqualTo: providerServiceCategory.value)
          .where('status', isEqualTo: 'pending') // Only show pending requests
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
          List<Map<String, dynamic>> tempList = [];

          print('📦 Received ${snapshot.docs.length} Anytime requests');

          // Check for new additions (Notification Trigger)
          if (!_isFirstLoadAnytime) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added) {
                final data = change.doc.data() as Map<String, dynamic>;
                // Trigger Notification
                NotificationService().showSimpleNotification(
                  title: 'New Service Request!',
                  body: 'A new ${data['service'] ?? 'service'} request is available near you.',
                  payload: 'new_request_anytime',
                );
              }
            }
          }
          _isFirstLoadAnytime = false; // Mark initial load as done

          for (var doc in snapshot.docs) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            data['requestType'] = 'Anytime';

            // Extract userId from document path
            String path = doc.reference.path;
            List<String> pathParts = path.split('/');
            if (pathParts.length >= 2) {
              data['userId'] = pathParts[1];
            }

            print('   ✅ ${data['service']} - ${data['userName'] ?? 'User'}');
            tempList.add(data);
          }

          anytimeRequests.value = tempList;
          isLoadingAnytime.value = false;
          print('✅ Anytime requests updated: ${tempList.length} total');
        },
        onError: (error) {
          print('❌ Error in Anytime requests listener: $error');
          print('🔗 POTENTIAL MISSING INDEX: If you see a URL above, click it to create the index!');
          isLoadingAnytime.value = false;
        },
      );
    } catch (e) {
      print('❌ Error setting up Anytime requests listener: $e');
      isLoadingAnytime.value = false;
    }
  }

  /// Accept a request and add to completedRequests collection
  Future<bool> acceptRequest({
    required Map<String, dynamic> request,
  }) async {
    try {
      isAcceptingRequest.value = true;
      print('🔄 Accepting request...');

      final userId = request['userId'];
      final requestType = request['requestType'];
      final requestId = request['id'];

      if (userId == null || requestType == null || requestId == null) {
        throw Exception('Missing request information');
      }

      // Determine subcollection name
      final subcollection = requestType == 'Now' ? 'Now' : 'AnyTime';

      print('📝 Request Details:');
      print('   Customer: ${request['userName']}');
      print('   Customer Phone: ${request['userPhone'] ?? 'Not provided'}');
      print('   Provider: ${providerName.value}');
      print('   Provider Phone: ${providerPhone.value}');
      print('   Type: $requestType ($subcollection)');

      // Use batch write for atomic operations
      WriteBatch batch = _firestore.batch();

      // 1. Update request status to 'accepted' in original location
      DocumentReference requestRef = _firestore
          .collection('Requests')
          .doc(userId)
          .collection(subcollection)
          .doc(requestId);

      batch.update(requestRef, {
        'status': 'completed',
        'acceptedAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
        'providerId': providerId.value,
        'providerName': providerName.value,
        'providerPhone': providerPhone.value,
        'providerProfileImage': providerProfileImage.value,
        'providerCategory': providerServiceCategory.value,
      });

      // 2. Create document in completedRequests collection
      DocumentReference completedRef = _firestore
          .collection('completedRequests')
          .doc(); // Auto-generate ID

      // Prepare completed request data with all details
      Map<String, dynamic> completedRequestData = {
        // Request Info
        'requestId': requestId,
        'requestType': requestType,
        'service': request['service'] ?? '',
        'subcategory': request['subcategory'] ?? '',
        'description': request['description'] ?? '',
        'location': request['location'] ?? '',
        'imageUrl': request['imageUrl'] ?? '',
        'price': request['price'] ?? 0,

        // Customer Info
        'userId': userId,
        'userName': request['userName'] ?? 'Unknown User',
        'userEmail': request['userEmail'] ?? '',
        'userPhone': request['userPhone'] ?? '',
        'userProfileImage': request['profileImage'] ?? '',
        'userRating': request['userRating'] ?? 0.0,
        'totalRatings': request['totalRatings'] ?? 0,

        // Provider Info
        'providerId': providerId.value,
        'providerName': providerName.value,
        'providerPhone': providerPhone.value,
        'providerProfileImage': providerProfileImage.value,
        'providerCategory': providerServiceCategory.value,

        // Status & Timestamps
        'status': 'completed',
        'acceptedAt': FieldValue.serverTimestamp(),
        'createdAt': request['createdAt'], // Original creation time
        'completedAt': FieldValue.serverTimestamp(), // Mark as completed instantly when accepted
      };

      batch.set(completedRef, completedRequestData);

      // Commit the batch
      await batch.commit();

      print('✅ Request accepted successfully!');
      print('✅ Added to completedRequests collection');
      print('📞 Customer Phone: ${request['userPhone'] ?? 'Not provided'}');
      print('📞 Provider Phone: ${providerPhone.value}');

      Get.snackbar(
        'Success',
        'Request accepted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.colorScheme.onPrimary,
        duration: const Duration(seconds: 2),
      );
      /// ✅ Navigate to BottomNavbar with the “Requests” tab (index = 1)
      Future.delayed(const Duration(seconds: 1), () {
        Get.offAll(() => const BottomNavbar(), arguments: {'index': 1});
      });

      return true;
    } catch (e) {
      print('❌ Error accepting request: $e');
      Get.snackbar(
        'Error',
        'Failed to accept request: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
      return false;
    } finally {
      isAcceptingRequest.value = false;
    }
  }

  /// Toggle online/offline status
  void toggleOnlineStatus() {
    isOnline.value = !isOnline.value;
    updateOnlineStatusInFirestore();
  }

  /// Update online status in Firestore
  Future<void> updateOnlineStatusInFirestore() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      await _firestore.collection('ServiceProviders').doc(uid).update({
        'isOnline': isOnline.value,
        'lastSeen': FieldValue.serverTimestamp(),
      });

      print('✅ Online status updated: ${isOnline.value}');
    } catch (e) {
      print('❌ Error updating online status: $e');
    }
  }

  /// Change selected tab
  void changeTab(int index) {
    selectedTab.value = index;
  }

  /// Manual refresh
  Future<void> refreshRequests() async {
    await fetchProviderServiceCategory();
    listenToNowRequests();
    listenToAnytimeRequests();
    print('🔄 Refreshed state');
  }

  /// Get filtered requests based on selected tab
  List<Map<String, dynamic>> get filteredRequests {
    return selectedTab.value == 0 ? nowRequests : anytimeRequests;
  }

  /// Get loading state based on selected tab
  bool get isLoading {
    return selectedTab.value == 0 ? isLoadingNow.value : isLoadingAnytime.value;
  }

  @override
  void onClose() {
    print('🗑️ OrdersController onClose called');
    // Cancel stream subscriptions to prevent memory leaks
    _nowSubscription?.cancel();
    _anytimeSubscription?.cancel();
    super.onClose();
  }
}
