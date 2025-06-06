import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'providers/product_provider.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'splash_screen.dart';
import 'verify_code_page.dart';
import 'home_page.dart';
import 'login_page_v2.dart';
import 'add_product_page.dart';

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
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permission');

      // 🔑 Save FCM Token when user logs in
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          // حفظ FCM Token عند تسجيل الدخول
          NotificationService.saveFCMToken();
          
          // 🤖 بدء منظف الإشعارات العربية عند تسجيل الدخول
          FirestoreNotificationService.startArabicNotificationCleaner();
        } else {
          // مسح FCM Token عند تسجيل الخروج
          NotificationService.clearFCMToken();
          
          // 🛑 إيقاف منظف الإشعارات عند تسجيل الخروج
          FirestoreNotificationService.stopArabicNotificationCleaner();
        }
      });

      // 📲 Foreground Message Handling - تعطيل الإشعارات المحلية
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        // لا تعرض إشعارات محلية - فقط خلي الإشعارات تروح للـ notifications collection
        debugPrint('📲 FCM Message received: ${message.messageId}');
        
        // 🧹 حذف فوري للإشعارات العربية عند استلام رسالة FCM
        Future.delayed(const Duration(milliseconds: 500), () {
          FirestoreNotificationService.removeArabicNotificationsImmediate();
        });
      });

      // معالجة الضغط على الإشعارات
      NotificationService.setupMessageHandlers();

      // الاستماع لتحديث Token
      messaging.onTokenRefresh.listen((String token) {
        debugPrint('🔄 FCM Token refreshed: $token');
        NotificationService.saveFCMToken();
      });
    }
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 🧹 تنظيف شامل للإشعارات عند بدء التطبيق
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performInitialCleanup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 🛑 إيقاف منظف الإشعارات عند إغلاق التطبيق
    FirestoreNotificationService.stopArabicNotificationCleaner();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // عند العودة للتطبيق - تنظيف الإشعارات
        _performInitialCleanup();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // عند إيقاف التطبيق مؤقتاً - لا نوقف المنظف
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  // دالة للتنظيف الأولي
  Future<void> _performInitialCleanup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirestoreNotificationService.cleanupAllDuplicateNotifications();
        debugPrint('🧽 Initial cleanup completed');
      } catch (e) {
        debugPrint('❌ Initial cleanup error: $e');
      }
    }
  }

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
        '/login': (context) => const LoginPageV2(),
        '/add_product': (context) => const AddProductPage(),
        '/edit_product': (context) {
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