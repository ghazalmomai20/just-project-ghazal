import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContactInfoPage extends StatefulWidget {
  const ContactInfoPage({super.key});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  bool remember = false;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
  }

  Future<void> _loadContactInfo() async {
    final prefs = await SharedPreferences.getInstance();
    phoneController.text = prefs.getString('phoneNumber') ?? '';
    whatsappController.text = prefs.getString('whatsappNumber') ?? '';
    remember = prefs.getBool('rememberContact') ?? false;
    setState(() {});
  }

  Future<void> _saveContactInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setString('phoneNumber', phoneController.text);
      await prefs.setString('whatsappNumber', whatsappController.text);
      await prefs.setBool('rememberContact', true);
    } else {
      await prefs.remove('phoneNumber');
      await prefs.remove('whatsappNumber');
      await prefs.setBool('rememberContact', false);
    }

    // ✅ إصلاح مشكلة استخدام context بعد await
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Contact info saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    const mainColor = Color(0xFF3B3B98);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: mainColor,
        centerTitle: true,
        title: const Text('Contact Information', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            _buildSectionTitle("Phone Number", textColor),
            const SizedBox(height: 8),
            _buildTextField(phoneController, isDark, "+962-7xxx-xxxx"),
            const SizedBox(height: 20),
            _buildSectionTitle("WhatsApp Number", textColor),
            const SizedBox(height: 8),
            _buildTextField(whatsappController, isDark, "+962-7xxx-xxxx"),
            const SizedBox(height: 20),
            Row(
              children: [
                Checkbox(
                  value: remember,
                  activeColor: mainColor,
                  onChanged: (val) {
                    setState(() => remember = val ?? false);
                  },
                ),
                Text(
                  'Remember my settings',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveContactInfo,
                icon: const Icon(Icons.save),
                label: const Text('Save my information'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildTextField(TextEditingController controller, bool isDark, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.grey[200],
        hintStyle: TextStyle(color: Colors.grey[500]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}