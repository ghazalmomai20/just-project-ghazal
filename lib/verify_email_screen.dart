import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _emailVerified = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  Future<void> _checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // تحديث الحالة من السيرفر

    if (!mounted) return;

    setState(() {
      _emailVerified = user?.emailVerified ?? false;
      _checking = false;
    });

    if (_emailVerified) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent again.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Your Email")),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("We've sent you a verification email."),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _resendVerificationEmail,
                    child: const Text("Resend Email"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _checkEmailVerification,
                    child: const Text("I Verified! Continue"),
                  ),
                ],
              ),
            ),
    );
  }
}