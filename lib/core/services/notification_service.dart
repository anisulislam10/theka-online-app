import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:get/get.dart';

/// Handles Firebase Cloud Messaging and Local Notifications
import 'package:quickserve/views/BottomNavbar/bottom_navbar.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM and Local Notifications
  Future<void> initialize() async {
    try {
      debugPrint('🔔 Initializing Notification Service...');

      // Request permission for iOS
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 Permission granted: ${settings.authorizationStatus}');

      // Initialize Local Notifications
      await _initializeLocalNotifications();

      // Get and save FCM token
      await _getAndSaveToken();

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      debugPrint('✅ Notification Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  /// Initialize Flutter Local Notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('🔔 Notification tapped: ${details.payload}');
        // Navigate based on payload
        if (details.payload != null) {
          _handlePayloadNavigation(details.payload!);
        }
      },
    );

    debugPrint('✅ Local Notifications initialized');
  }

  /// Get FCM token and save to Firestore
  Future<void> _getAndSaveToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        debugPrint('🔑 FCM Token: $token');
        await _saveTokenToFirestore(token);

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
      }
    } catch (e) {
      debugPrint('❌ Error getting FCM token: $e');
    }
  }

  /// Save token to current user's Firestore document
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('⚠️ No user logged in, skipping token save');
        return;
      }

      final userId = user.uid;

      // Try to save to Customers collection first
      final customerDoc =
          FirebaseFirestore.instance.collection('Customers').doc(userId);
      final customerSnapshot = await customerDoc.get();

      if (customerSnapshot.exists) {
        await customerDoc.update({'fcmToken': token});
        debugPrint('✅ FCM token saved to Customers/$userId');
        return;
      }

      // If not a customer, try ServiceProviders
      final providerDoc =
          FirebaseFirestore.instance.collection('ServiceProviders').doc(userId);
      final providerSnapshot = await providerDoc.get();

      if (providerSnapshot.exists) {
        await providerDoc.update({'fcmToken': token});
        debugPrint('✅ FCM token saved to ServiceProviders/$userId');
        return;
      }

      debugPrint('⚠️ User document not found in Customers or ServiceProviders');
    } catch (e) {
      debugPrint('❌ Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages (show heads-up notification)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 Foreground message received:');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');

    // Show local notification for heads-up display
    showLocalNotification(message);
  }

  /// Show local notification (Heads-up display) - PUBLIC METHOD
  Future<void> showLocalNotification(RemoteMessage message) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel', // Changed Channel ID to force reset
      'High Importance Notifications', // Channel Name
      channelDescription: 'Notifications for service request updates',
      importance: Importance.max, // Increased importance
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]), // Added vibration pattern
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Theka Online',
      message.notification?.body ?? 'You have a new update',
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap (navigation)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 Notification tapped: ${message.data}');

    // Navigate based on data
    final String? type = message.data['type'];
    final String? payload = message.data['payload']; // Check payload if type is missing

    if (type == 'request_accepted') {
      // Navigate to My Requests page
      Get.toNamed('/my-request'); 
    } else if (payload == 'new_request_now' || payload == 'new_request_anytime') {
      _handlePayloadNavigation(payload!);
    }
  }

  /// Helper to handle text payload navigation
  void _handlePayloadNavigation(String payload) {
    debugPrint('🔔 Navigating for payload: $payload');
    if (payload == 'new_request_now' || payload == 'new_request_anytime') {
      debugPrint('🚀 Navigating to BottomNavbar (Index 0)');
      // Navigate to BottomNavbar (Orders List is index 0)
      // Use Get.offAll to clear stack or just navigate if already in app
      Get.offAll(() => BottomNavbar(initialIndex: 0));
    }
  }

  /// Show simple notification without RemoteMessage (for local triggers)
  Future<void> showSimpleNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel', // Changed Channel ID
      'High Importance Notifications', // Channel Name
      channelDescription: 'Notifications for service request updates',
      importance: Importance.max, // Increased importance
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]), // Added vibration pattern
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );

    debugPrint('✅ Simple notification shown: $title');
  }

  /// Send notification to a specific user (Client-side using HTTP)
  /// NOTE: This requires Firebase Server Key. For production, use Cloud Functions.
  Future<void> sendNotificationToUser({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // This method is a placeholder.
    // For security, notifications should be sent from a backend/Cloud Function.
    // The user would need to implement a Cloud Function or use an HTTP call
    // with their Firebase Server Key.
    
    debugPrint('⚠️ sendNotificationToUser called');
    debugPrint('   Target Token: $fcmToken');
    debugPrint('   Title: $title');
    debugPrint('   Body: $body');
    debugPrint('   Data: $data');
    
    // TODO: Implement server-side notification sending via Cloud Functions
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received:');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');
}
