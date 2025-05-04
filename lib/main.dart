import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'theme_provider.dart';
import 'providers/product_provider.dart';
import 'splash_screen.dart';
import 'verify_code_page.dart';
import 'home_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase initialized successfully');
  } catch (e) {
    debugPrint('❌ Error initializing Firebase: $e');
  }

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

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
        '/verify': (context) => const VerifyCodePage(email: 'test@example.com'), // فقط للتجريب
        // '/create_password': (context) => CreatePasswordPage(), ← أضفها إذا تحتاج
        // '/reset_password': (context) => ResetPasswordPage(), ← أضفها أيضًا إذا لازم
      },
    );
  }
}