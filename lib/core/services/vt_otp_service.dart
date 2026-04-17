import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:quickserve/core/constants/api_key.dart';

/// VeevoTech CPAAS OTP Service
/// Sends real SMS OTPs using the VeevoTech v3 API and verifies them locally.
class VtOtpService {
  VtOtpService._();
  static final VtOtpService instance = VtOtpService._();

  static const String _baseUrl = 'https://api.veevotech.com/v3/sendsms';
  static const String _senderNum = 'Default';
  static const int _otpExpiryMinutes = 5;

  // In-memory OTP store: phone → {otp, expiry}
  final Map<String, _OtpEntry> _store = {};

  /// Generates a random 6-digit OTP, sends it via VeevoTech, and stores it.
  Future<VtOtpResult> sendOtp(String phone) async {
    try {
      final otp = _generateOtp();
      final message =
          'Your TheekaOnline verification code is $otp. Valid for $_otpExpiryMinutes minutes. Do not share it with anyone.';

      debugPrint('📤 VtOtpService: Sending OTP to $phone');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'apikey': VeevoTechAPIKey.apiKey,
          'receivernum': phone,
          'sendernum': _senderNum,
          'textmessage': message,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final status = data['STATUS'] as String? ?? '';
        final errorFilter = data['ERROR_FILTER'] as String? ?? '';
        final errorDesc = data['ERROR_DESCRIPTION'] as String? ?? '';

        if (status == 'SUCCESSFUL') {
          _store[phone] = _OtpEntry(
            otp: otp,
            expiry: DateTime.now().add(Duration(minutes: _otpExpiryMinutes)),
          );
          debugPrint('✅ VtOtpService: OTP sent successfully (ID: ${data['MESSAGE_ID']})');
          return VtOtpResult.success();
        } else {
          debugPrint('❌ VtOtpService: API error – $errorFilter: $errorDesc');
          return VtOtpResult.failure(_friendlyError(errorFilter, errorDesc));
        }
      } else {
        debugPrint('❌ VtOtpService: HTTP ${response.statusCode}');
        return VtOtpResult.failure('Network error. Please try again.');
      }
    } catch (e) {
      debugPrint('❌ VtOtpService: Exception – $e');
      return VtOtpResult.failure('Failed to send OTP. Check your connection.');
    }
  }

  /// Verifies the OTP entered by the user.
  VtOtpVerifyResult verifyOtp(String phone, String enteredOtp) {
    final entry = _store[phone];

    if (entry == null) {
      return VtOtpVerifyResult.notFound;
    }

    if (DateTime.now().isAfter(entry.expiry)) {
      _store.remove(phone);
      return VtOtpVerifyResult.expired;
    }

    if (entry.otp == enteredOtp.trim()) {
      _store.remove(phone); // invalidate after success
      return VtOtpVerifyResult.valid;
    }

    return VtOtpVerifyResult.invalid;
  }

  /// Resends OTP (replaces any existing entry).
  Future<VtOtpResult> resendOtp(String phone) => sendOtp(phone);

  /// Generates a 6-digit numeric OTP string.
  String _generateOtp() {
    final rand = Random.secure();
    return List.generate(6, (_) => rand.nextInt(10)).join();
  }

  /// Maps VeevoTech error filters to user-friendly messages.
  String _friendlyError(String errorFilter, String errorDesc) {
    switch (errorFilter) {
      case 'INVALID_NUMBER':
        return 'Invalid phone number. Please use international format.';
      case 'INSUFFICIENT_BALANCE':
      case 'LOW_BALANCE':
        return 'SMS service temporarily unavailable. Please try again later.';
      case 'INVALID_API_KEY':
        return 'SMS configuration error. Please contact support.';
      case 'UNSUPPORTED_COUNTRY':
        return 'Your country is not supported for SMS delivery.';
      case 'TECHNICAL_ISSUE':
        return 'Technical issue on our end. Please try again shortly.';
      default:
        return errorDesc.isNotEmpty ? errorDesc : 'Failed to send OTP. Please try again.';
    }
  }
}

// ─── Internal Models ───────────────────────────────────────────────────────

class _OtpEntry {
  final String otp;
  final DateTime expiry;
  _OtpEntry({required this.otp, required this.expiry});
}

class VtOtpResult {
  final bool isSuccess;
  final String? errorMessage;

  VtOtpResult._({required this.isSuccess, this.errorMessage});

  factory VtOtpResult.success() => VtOtpResult._(isSuccess: true);
  factory VtOtpResult.failure(String message) =>
      VtOtpResult._(isSuccess: false, errorMessage: message);
}

enum VtOtpVerifyResult {
  valid,    // OTP matched and not expired
  invalid,  // OTP does not match
  expired,  // OTP found but past expiry
  notFound, // No OTP was ever sent for this phone
}
