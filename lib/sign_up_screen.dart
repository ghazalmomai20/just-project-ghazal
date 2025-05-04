import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'verify_code_page.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool agree = false;
  final List<String> takenUsernames = ['admin', 'testuser', 'ghazal'];

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool isUniversityEmail(String email) {
    final allowedDomains = [
      'cit.just.edu.jo',
      'med.just.edu.jo',
      'eng.just.edu.jo',
      'nursing.just.edu.jo',
      'ams.just.edu.jo',
      'ph.just.edu.jo',
      'arch.just.edu.jo',
    ];
    return allowedDomains.any((domain) => email.toLowerCase().endsWith('@$domain'));
  }

  Future<void> _registerWithFirebase() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    try {
      final userCredential = await _authService.signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (userCredential == null) {
        throw Exception("Failed to create account");
      }

      final email = _emailController.text.trim();
      await _authService.sendVerificationCode(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Account created. Verification code sent to your email."),
          duration: Duration(seconds: 4),
        ),
      );

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VerifyCodePage(email: email, isSignUp: true)),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already in use. Try logging in.';
          break;
        case 'invalid-email':
          message = 'The email address is invalid.';
          break;
        case 'weak-password':
          message = 'The password is too weak.';
          break;
        default:
          message = 'Unexpected error: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ $message")),
      );
    } catch (e) {
      if (!mounted) return;
      print("🔥 SIGN UP ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Something went wrong. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _usernameController,
                      hint: 'User Name',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your user name';
                        }
                        if (takenUsernames.contains(value.trim().toLowerCase())) {
                          return 'This username is already in use';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'University Email',
                      icon: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your university email';
                        }
                        if (!isUniversityEmail(value.trim())) {
                          return 'Use a valid JUST email (e.g. name@cit.just.edu.jo)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock,
                      obscure: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter a password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm Password',
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Checkbox(
                          value: agree,
                          onChanged: (val) {
                            setState(() => agree = val ?? false);
                          },
                        ),
                        const Text("I agree to the "),
                        const Text(
                          "Terms & Privacy",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildSignUpButton(),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey.shade800, Colors.black87]
              : [const Color(0xFF3891D6), const Color(0xFF170557)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Let's", style: TextStyle(fontSize: 28, color: Colors.white)),
          Text("Create", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          Text("Your Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
        prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
        filled: true,
        fillColor: isDark ? Colors.grey.shade800 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: isDark ? Colors.blue.shade200 : Colors.blue),
        ),
        errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: agree ? _registerWithFirebase : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3891D6), Color(0xFF170557)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.all(Radius.circular(30)),
          ),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 50),
            child: const Text(
              "Sign Up",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}