import 'package:flutter/material.dart';
import 'login_page_v2.dart';
import 'settings_page.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF3F8FC);
    final primaryTextColor = isDark ? Colors.white : Colors.black;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ?Color(0xFF1976D2) : Color(0xFF42A5F5),
        title: Text('Terms & Conditions', style: TextStyle(color: isDark ? Colors.white : Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.white),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Scrollbar(
          thickness: 4,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated: April 7, 2025',
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.blue[200] : const Color(0xFF1746A2)),
                ),
                const SizedBox(height: 15),
                Text(
                  'Welcome to JUST STORE, a mobile application designed specifically for university students to buy, sell, and exchange educational and academic products easily and securely.',
                  style: TextStyle(color: secondaryTextColor),
                ),
                const SizedBox(height: 15),
                _buildSectionTitle('1. Definitions', primaryTextColor),
                _buildParagraph(
                  '"App": Refers to the JUST STORE mobile application.\n'
                  '"User": Any student using the app after registering with a valid university email address.\n'
                  '"Products": Includes books, slides, smart devices, scrubs, graduation robes, lab coats, dental tools, architecture tools, and other permitted educational items.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('2. Registration Requirements', primaryTextColor),
                _buildParagraph(
                  'To use the app, the user must be a university student with a valid university email address.\n'
                  'During registration, the user must provide:\n'
                  '- A valid university email address\n'
                  '- A secure password\n'
                  '- A username\n'
                  'The user is responsible for maintaining the confidentiality of their account credentials.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('3. Use of the App', primaryTextColor),
                _buildParagraph(
                  'It is strictly prohibited to use the app for any illegal or fraudulent activities.\n'
                  'Listing products that are unethical, unlawful, or unrelated to an educational environment is not allowed.\n'
                  'The user bears full responsibility for the quality and accuracy of the products listed.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('4. App Disclaimer', primaryTextColor),
                _buildParagraph(
                  'JUST STORE operates solely as a platform connecting buyers and sellers and does not guarantee the completion of any transaction.\n'
                  'Users are encouraged to communicate with caution and verify the credibility of the other party before making any payments or exchanges.\n'
                  'The app is not liable for any damages or losses resulting from a sale or purchase.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('5. Content', primaryTextColor),
                _buildParagraph(
                  'Users are allowed to upload product images and descriptions only.\n'
                  'Comments or any additional textual content are not permitted.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('6. Intellectual Property', primaryTextColor),
                _buildParagraph(
                  'All intellectual property rights related to the app are reserved by JUST STORE.\n'
                  'No part of the app may be copied or reused without prior written permission.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('7. Modifications', primaryTextColor),
                _buildParagraph(
                  'JUST STORE reserves the right to update or modify these terms at any time.\n'
                  'Users will be notified of any changes, and continued use of the app constitutes implied acceptance of the updated terms.',
                  secondaryTextColor,
                ),
                _buildSectionTitle('8. Support', primaryTextColor),
                _buildParagraph(
                  'For any inquiries or technical support, please contact us at:\nJust_store@gmail.com',
                  secondaryTextColor,
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("✅ THANK YOU")),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text('Accept'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) =>  const LoginPageV2()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                      child: const Text('Decline'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 5),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  Widget _buildParagraph(String text, Color textColor) {
    return Text(text, style: TextStyle(color: textColor));
  }
}
