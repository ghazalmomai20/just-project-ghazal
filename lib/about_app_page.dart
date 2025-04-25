import 'package:flutter/material.dart';
import 'settings_page.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF121212) : const Color(0xFFF3F8FC);
    final headingColor = Colors.grey[800];
    final textColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        title: const Text('About App', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
      ),
      body: Scrollbar(
        thickness: 4,
        radius: const Radius.circular(10),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'JUST STORE is a mobile application designed specifically for university students to buy, sell, and exchange educational and academic products easily and securely.',
                style: TextStyle(color: textColor, fontSize: 15),
              ),
              const SizedBox(height: 20),
              _sectionTitle('Features', headingColor),
              _sectionContent(
                '- Simple and friendly UI.\n'
                '- Post and browse educational items like books, tools, and more.\n'
                '- View user profiles and manage your own items.\n'
                '- Secure authentication via university email.',
                textColor,
              ),
              _sectionTitle('Who is it for?', headingColor),
              _sectionContent(
                'This app is created for university students who want a safe, easy, and academic-focused platform for trading educational materials.',
                textColor,
              ),
              _sectionTitle('Support & Feedback', headingColor),
              _sectionContent(
                'If you encounter any issues or have suggestions to improve the app, please contact us at:\njust_store@gmail.com',
                textColor,
              ),
              const SizedBox(height: 30),
              Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(color: textColor),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '© 2025 JUST STORE Team',
                  style: TextStyle(color: textColor, fontSize: 13),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, Color? color) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: color,
        ),
      ),
    );
  }

  Widget _sectionContent(String text, Color textColor) {
    return Text(
      text,
      style: TextStyle(color: textColor),
    );
  }
}
