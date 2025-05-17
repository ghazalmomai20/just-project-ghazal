import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ContactInfoPage extends StatefulWidget {
  const ContactInfoPage({super.key});

  @override
  State<ContactInfoPage> createState() => _ContactInfoPageState();
}

class _ContactInfoPageState extends State<ContactInfoPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  bool remember = false;
  bool _isButtonEnabled = false;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadContactInfo();
    phoneController.addListener(_updateButtonState);
    whatsappController.addListener(_updateButtonState);
  }

  void _updateButtonState() {
    setState(() {
      _isButtonEnabled =
          phoneController.text.trim().isNotEmpty ||
              whatsappController.text.trim().isNotEmpty ||
              remember;
    });
  }

  Future<void> _loadContactInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('profile')
        .doc('contact_info')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      phoneController.text = data['phone'] ?? '';
      whatsappController.text = data['whatsapp'] ?? '';
      remember = data['remember'] ?? false;
      _updateButtonState();
    }
  }

  bool _isValidPhone(String phone) {
    return phone.trim().startsWith('07');
  }

  Future<void> _saveContactInfo() async {
    final phone = phoneController.text.trim();
    final whatsapp = whatsappController.text.trim();

    if (phone.isNotEmpty && !_isValidPhone(phone)) {
      _showError('Phone number must start with 07');
      return;
    }

    if (whatsapp.isNotEmpty && !_isValidPhone(whatsapp)) {
      _showError('WhatsApp number must start with 07');
      return;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('profile')
        .doc('contact_info')
        .set({
      'phone': phone,
      'whatsapp': whatsapp,
      'remember': remember,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Contact info saved!')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('❌ $message')),
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
                    setState(() {
                      remember = val ?? false;
                      _updateButtonState();
                    });
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
                onPressed: _isButtonEnabled ? _saveContactInfo : null,
                icon: const Icon(Icons.save),
                label: const Text('Save my information'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  disabledBackgroundColor: Colors.grey,
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