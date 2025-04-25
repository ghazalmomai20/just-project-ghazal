import 'package:flutter/material.dart';
import 'settings_page.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.white),
        ),
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
                'We are committed to protecting your privacy. This privacy policy explains the information we collect, how we use it, and how we protect it.',
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 20),

              sectionTitle('Information We Collect', headingColor),
              sectionContent(
                '- Personal Information: Name, email address, phone number.\n'
                '- Transaction Information: Product details such as title, description, and price.\n'
                '- Device Information: Device type, operating system, and usage duration.',
                textColor,
              ),

              sectionTitle('How We Use the Information', headingColor),
              sectionContent(
                '- To facilitate buying and selling transactions.\n'
                '- To communicate with users about orders and transactions.\n'
                '- To improve our services and personalize the user experience.',
                textColor,
              ),

              sectionTitle('Information Security', headingColor),
              sectionContent(
                'We use appropriate security measures to protect personal information from unauthorized access, use, or alteration. Sensitive data is encrypted during transmission.',
                textColor,
              ),

              sectionTitle('User Rights', headingColor),
              sectionContent(
                '- Users have the right to access and correct their personal information.\n'
                '- Users can request the deletion of their personal information.',
                textColor,
              ),

              sectionTitle('Changes to Privacy Policy', headingColor),
              sectionContent(
                'We reserve the right to update this privacy policy. Users will be notified of any changes by updating the date at the top of this page.',
                textColor,
              ),

              sectionTitle('Contact Us', headingColor),
              sectionContent(
                'If you have any questions about this policy, feel free to contact us at:\njust_store@gmail.com',
                textColor,
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget sectionTitle(String title, Color? color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget sectionContent(String text, Color textColor) {
    return Text(
      text,
      style: TextStyle(color: textColor),
    );
  }
}
