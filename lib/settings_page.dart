// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:share_plus/share_plus.dart';

import 'theme_provider.dart';
import 'profile_page.dart';
import 'terms_conditions_page.dart';
import 'privacy_policy_page.dart';
import 'about_app_page.dart';
import 'rate_app_page.dart';
import 'home_page.dart';
import 'chat_list_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsOn = false;
  final int _unreadMessages = 5;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadSettings();
  }

  Future<void> _initializeNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsOn = prefs.getBool('notificationsOn') ?? false;
      _userName = prefs.getString('username') ?? 'User';
    });

    if (notificationsOn) {
      _showTestNotification();
    }
  }

  Future<void> _saveNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsOn', value);
  }

  Future<void> _showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel_id',
      'Test Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      0,
      '🔔 Notifications Enabled',
      'You will now receive app notifications!',
      notificationDetails,
    );
  }

  Future<void> _cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor:Color(0xFF1976D2),
        centerTitle: true,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          _buildSettingsTile(Icons.person, 'Edit Profile', Colors.green, () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfilePage(userName: _userName),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            "General Settings",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.brightness_6, color: Colors.orange),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle light/dark theme'),
            value: themeProvider.isDarkMode,
            onChanged: (val) => themeProvider.toggleTheme(val),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: Colors.amber),
            title: const Text('Notifications'),
            value: notificationsOn,
            onChanged: (val) {
              setState(() {
                notificationsOn = val;
              });
              _saveNotifications(val);
              val ? _showTestNotification() : _cancelAllNotifications();
            },
          ),
          const Divider(),
          _buildSettingsTile(
            Icons.description,
            'Terms & Conditions',
            Colors.indigo,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsAndConditionsPage()),
              );
            },
          ),
          _buildSettingsTile(
            Icons.lock,
            'Privacy Policy',
            Colors.red,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
              );
            },
          ),
          _buildSettingsTile(
            Icons.star,
            'Rate This App',
            Colors.purple,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RateAppPage()),
              );
            },
          ),
          _buildSettingsTile(Icons.share, 'Share This App', Colors.pink, () {
            Share.share(
              'Check out this awesome app Just Store!\nhttps://JUSTSTORE.com/juststore',
              subject: 'Just Store App 🌟',
            );
          }),
          _buildSettingsTile(Icons.info_outline, 'About', Colors.teal, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutAppPage()),
            );
          }),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor:Color(0xFF1976D2),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatListPage()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProfilePage(userName: _userName)),
            );
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(
            label: '',
            icon: Stack(
              children: [
                const Icon(Icons.chat),
                if (_unreadMessages > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_unreadMessages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
      IconData icon,
      String title,
      Color iconColor,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}