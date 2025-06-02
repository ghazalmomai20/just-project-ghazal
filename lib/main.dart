import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// ignore: unused_import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';
import 'providers/product_provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'splash_screen.dart';
import 'verify_code_page.dart';
import 'home_page.dart';
import 'login_page_v2.dart'; // ✅ تأكد من وجود صفحة login_page.dart
import 'add_product_page.dart'; // ✅ إضافة import لصفحة إضافة المنتج

// 🔔 Local notifications plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 📥 Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📥 [Background] Message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔥 Firebase Initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // 🔔 Local Notification Initialization
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // 📥 FCM Setup
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 🚨 Request Notification Permissions
    await messaging.requestPermission();

    // 🔑 Print FCM Token
    final String? fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      debugPrint('FCM Token: $fcmToken');
    }

    // 📲 Foreground Message Handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        NotificationService.showNotification(
          title: notification.title ?? 'No title',
          body: notification.body ?? 'No message body',
        );
      }
    });
  } catch (e) {
    debugPrint('❌ Firebase initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: const SplashScreen(), // 🟢 تظهر أولاً
      routes: {
        '/home': (context) => const HomePage(),
        '/verify': (context) => const VerifyCodePage(email: 'test@example.com'),
        '/login': (context) => const LoginPageV2(), // ✅ تأكد من تعريفها
        '/add_product': (context) => const AddProductPage(), // ✅ route لإضافة منتج جديد
        '/edit_product': (context) {
          // ✅ route لتعديل المنتج مع استقبال البيانات
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AddProductPage(
            postId: args['postId'],
            postData: args['postData'],
          );
        },
      },
    );
  }
} 