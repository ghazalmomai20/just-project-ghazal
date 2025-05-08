import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';
import 'providers/product_provider.dart';
import 'splash_screen.dart';
import 'verify_code_page.dart';
import 'home_page.dart';
import 'firebase_options.dart'; // ✅ Generated using flutterfire
import 'notification_service.dart';

// 🔔 Local notifications plugin
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
    // 🔥 Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // 🔔 Initialize local notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    // 📥 Firebase Messaging setup
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 🚨 Request permissions
    await messaging.requestPermission();

    // 🔑 Get and print FCM token
    final String? fcmToken = await messaging.getToken();
    if (fcmToken != null) {
      debugPrint('FCM Token: $fcmToken');
    }

    // 🔔 Handle foreground notifications
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
    debugPrint('❌ Firebase init error: $e');
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
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomePage(),
        '/verify': (context) => const VerifyCodePage(email: 'test@example.com'),
      },
    );
  }
}
