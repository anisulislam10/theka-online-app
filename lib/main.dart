import 'package:firebase_core/firebase_core.dart';
import 'package:quickserve/views/Auth/AuthService/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quickserve/core/services/translation_service.dart';
import 'package:quickserve/core/services/notification_service.dart';
import 'package:quickserve/views/Splash/splash_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp();
  await TranslationService.loadTranslations();
  // Initialize Auth Service (SharedPreferences)
  await AuthService.init();
  
  // Initialize Notification Service
  await NotificationService().initialize();
  
  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          translations: TranslationService(),
          locale: Get.locale ?? const Locale('en'),
          fallbackLocale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('ur')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SplashPage(),
        );
      },
    );
  }
}
