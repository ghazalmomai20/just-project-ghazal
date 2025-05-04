import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Method to send verification code via Firebase HTTP Function
  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://us-central1-just-66-f51b6.cloudfunctions.net/sendVerificationCode',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        print('✅ OTP sent successfully via HTTP function');
        return json.decode(response.body);
      } else {
        print('❌ Failed to send OTP: ${response.body}');
        throw Exception('Failed to send verification code');
      }
    } catch (e) {
      print('❌ Error sending OTP: $e');
      throw Exception('Failed to send verification code. Please try again later.');
    }
  }

  static Future<Map<String, dynamic>> sendVerificationCodeStatic(String email) async {
    return await AuthService().sendVerificationCode(email);
  }

  // ✅ Verify code from Firestore
  Future<bool> verifyCode(String email, String code) async {
    try {
      final docSnapshot = await _firestore.collection('otp_codes').doc(email).get();

      if (!docSnapshot.exists) {
        print('⚠️ No verification code found for this email');
        return false;
      }

      final data = docSnapshot.data();
      final storedCode = data?['code'];
      final expiresAt = data?['expiresAt'] as Timestamp?;

      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        print('⚠️ Verification code has expired');
        return false;
      }

      return code == storedCode;
    } catch (e) {
      print('❌ Error verifying code: $e');
      return false;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('❌ Error signing in: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('❌ Error signing up: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    return await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    return await _auth.sendPasswordResetEmail(email: email);
  }
}