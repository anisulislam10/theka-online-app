import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Pure Dart service to send FCM notifications via HTTP
/// NOTE: For production, the server key should be stored securely (backend/env)
class FCMSenderService {
  // TODO: Replace with your Firebase Server Key from Firebase Console
  // Go to: Firebase Console -> Project Settings -> Cloud Messaging -> Server key
  static const String _serverKey = 'YOUR_FIREBASE_SERVER_KEY_HERE';
  
  /// Send push notification to a specific FCM token
  static Future<bool> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('📤 Sending FCM notification...');
      debugPrint('   Title: $title');
      debugPrint('   Body: $body');
      
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': fcmToken,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'priority': 'high',
          },
          'data': data ?? {},
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Notification sent successfully');
        return true;
      } else {
        debugPrint('❌ Failed to send notification: ${response.statusCode}');
        debugPrint('   Response: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
      return false;
    }
  }

  /// Send "Request Accepted" notification to customer
  static Future<void> sendRequestAcceptedNotification({
    required String customerFcmToken,
    required String providerName,
    required String service,
    required String requestId,
  }) async {
    await sendNotification(
      fcmToken: customerFcmToken,
      title: '🎉 Request Accepted!',
      body: '$providerName has accepted your $service request.',
      data: {
        'type': 'request_accepted',
        'requestId': requestId,
        'providerName': providerName,
      },
    );
  }
}
