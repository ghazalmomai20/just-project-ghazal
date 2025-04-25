import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static const _serviceId = 'service_x4z10io';
  static const _templateId = 'template_k2a23lt';
  static const _userId = '_1uQHfgWQLxqy2_aE';

  static Future<void> sendVerificationCode(String email) async {
    final code = _generateCode();

    // Save code in Firestore
    await FirebaseFirestore.instance
        .collection('verifications')
        .doc(email)
        .set({
      'code': code,
      'createdAt': Timestamp.now(),
    });

    // Send email via EmailJS
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _userId,
        'template_params': {
          'to_email': email,
          'code': code,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send verification email');
    }
  }

  static Future<bool> verifyCode(String email, String inputCode) async {
    final doc = await FirebaseFirestore.instance
        .collection('verifications')
        .doc(email)
        .get();

    if (!doc.exists) return false;

    final savedCode = doc['code'];
    return inputCode == savedCode;
  }

  static String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString(); // 6-digit code
  }
}