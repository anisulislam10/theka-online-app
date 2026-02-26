import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService extends Translations {
  static const locale = Locale('en');
  static const fallbackLocale = Locale('en');

  static Map<String, Map<String, String>> translations = {};

  static const String _prefKey = 'selected_language';

  @override
  Map<String, Map<String, String>> get keys => translations;

  /// Load translations from JSON and set saved locale
  static Future<void> loadTranslations() async {
    // Load JSON
    String jsonString = await rootBundle.loadString(
      'assets/languages/translations.json',
    );
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    Map<String, String> enMap = {};
    Map<String, String> urMap = {};

    jsonMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        enMap[key] = value['en']?.toString() ?? '';
        urMap[key] = value['ur']?.toString() ?? '';
      }
    });

    translations = {'en': enMap, 'ur': urMap};

    // Load saved language
    final prefs = await SharedPreferences.getInstance();
    String? savedLang = prefs.getString(_prefKey);

    if (savedLang != null) {
      final locale = savedLang == 'ur'
          ? const Locale('ur')
          : const Locale('en');
      Get.updateLocale(locale);
    } else {
      Get.updateLocale(locale); // default
    }
  }

  /// Change language and save to SharedPreferences
  static Future<void> changeLocale(String langCode) async {
    final locale = langCode == 'ur'
        ? const Locale('ur')
        : const Locale('en');
    await Get.updateLocale(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, langCode);
  }
}
