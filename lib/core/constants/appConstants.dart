import 'dart:convert';

import 'package:crypto/crypto.dart';

class AppConstant {
  static String? userToken;
  static String? userUID;

  // Save to memory variables
  static void setUserToken(String token) {
    userToken = token;
  }

  static void setUserUID(String uid) {
    userUID = uid;
  }

  static String hashUserId(String? userId) {
    final bytes = utf8.encode(userId ?? "");
    final hashed = sha256.convert(bytes);
    return hashed.toString();
  }

  // Get from memory variables
  static String? getUserToken() {
    return userToken;
  }

  static String? getUserUID() {
    return userUID;
  }

  // Clear session
  static void clearSession() {
    userToken = null;
    userUID = null;
  }
}
