import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quickserve/core/services/notification_service.dart';

/// Listens to Firestore changes and triggers local notifications
/// This is an alternative to FCM that works when app is open/background
class RequestListenerService {
  static final RequestListenerService _instance = RequestListenerService._internal();
  factory RequestListenerService() => _instance;
  RequestListenerService._internal();

  StreamSubscription<QuerySnapshot>? _subscription;

  /// Start listening to completed requests for the current user
  void startListening() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('⚠️ No user logged in, cannot start request listener');
      return;
    }

    debugPrint('👂 Starting request listener for user: $userId');

    // Listen to new completed requests
    _subscription = FirebaseFirestore.instance
        .collection('completedRequests')
        .where('userId', isEqualTo: userId)
        .orderBy('acceptedAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleNewCompletedRequest(change.doc.data()!);
        }
      }
    });
  }

  /// Handle new completed request - show local notification
  void _handleNewCompletedRequest(Map<String, dynamic> requestData) {
    final providerName = requestData['providerName'] ?? 'Service Provider';
    final service = requestData['service'] ?? 'service';

    debugPrint('🎉 New completed request detected!');
    debugPrint('   Provider: $providerName');
    debugPrint('   Service: $service');

    // Show local notification (works even in background on some platforms)
    NotificationService()._showLocalNotification(
      RemoteMessage(
        notification: RemoteMessage.notification(
          title: '🎉 Request Accepted!',
          body: '$providerName has accepted your $service request.',
        ),
        data: {
          'type': 'request_accepted',
          'providerName': providerName,
          'service': service,
        },
      ),
    );
  }

  /// Stop listening
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    debugPrint('🛑 Request listener stopped');
  }
}

// Extension to create RemoteMessage notification
extension RemoteMessageNotification on RemoteMessage {
  static RemoteMessageNotification notification({String? title, String? body}) {
    return RemoteMessageNotification();
  }
}
