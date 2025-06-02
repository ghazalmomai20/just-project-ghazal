import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'settings_page.dart';

class RateAppPage extends StatefulWidget {
  const RateAppPage({super.key});

  @override
  State<RateAppPage> createState() => _RateAppPageState();
}

class _RateAppPageState extends State<RateAppPage> {
  String? selectedEmoji;
  double? rating;
  final TextEditingController feedbackController = TextEditingController();

  void _selectEmoji(String emojiKey) {
    setState(() {
      selectedEmoji = emojiKey;
      switch (emojiKey) {
        case 'bad':
          rating = 0.5;
          break;
        case 'ok':
          rating = 0.7;
          break;
        case 'good':
          rating = 0.9;
          break;
        case 'amazing':
          rating = 1.0;
          break;
      }
    });
  }

  Future<void> _submitFeedback() async {
    if (rating != null) {
      final prefs = await SharedPreferences.getInstance();
      final newRating = {
        'rating': rating,
        'feedback': feedbackController.text,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final String? ratingsJson = prefs.getString('app_ratings');
      List<Map<String, dynamic>> allRatings = [];

      if (ratingsJson != null) {
        allRatings = List<Map<String, dynamic>>.from(
          (json.decode(ratingsJson) as List).map((x) => Map<String, dynamic>.from(x)),
        );
      }

      allRatings.add(newRating);
      await prefs.setString('app_ratings', json.encode(allRatings));

      // ✅ حل المشكلة: تأكدي إن الـ context بعده موجود
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Feedback submitted successfully!')),
      );

      setState(() {
        selectedEmoji = null;
        rating = null;
        feedbackController.clear();
      });
    }
  }

  void _cancel() {
    setState(() {
      selectedEmoji = null;
      rating = null;
      feedbackController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:Color(0xFF1976D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
        ),
        title: const Text('APP Rate', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Image.asset('assets/bag_icon.png', height: 90),
                  const SizedBox(width: 12),
                  const Text(
                    'Hello Friends',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                      fontFamily: 'AgentOrange',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RichText(
                text: TextSpan(
                  text: 'What do you think about ',
                  style: TextStyle(color: textColor, fontSize: 16),
                  children: const [
                    TextSpan(
                      text: 'Just Store',
                      style: TextStyle(color:Color(0xFF1976D2), fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ' app?'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildEmojiWithLabel('bad', 'assets/emoji_bad.png', 'Bad'),
                  _buildEmojiWithLabel('ok', 'assets/emoji_ok.png', 'OK!'),
                  _buildEmojiWithLabel('good', 'assets/emoji_good.png', 'Good'),
                  _buildEmojiWithLabel('amazing', 'assets/emoji_amazing.png', 'Amazing'),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '✪ Let us know if you have ideas to improve the app:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:Color(0xFF1976D2),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: feedbackController,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDark ? Colors.grey[900] : Colors.white,
                  hintText: 'Type here...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1746A2),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text('SUBMIT', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1746A2),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: const Text('CANCEL', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Color(0xFF3B3B98),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.home, color: Colors.white),
              Icon(Icons.chat, color: Colors.white),
              Icon(Icons.person, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiWithLabel(String key, String assetPath, String label) {
    final isSelected = selectedEmoji == key;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _selectEmoji(key),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Color(0xFF1976D2), width: 3)
                  : null,
            ),
            child: Image.asset(assetPath, height: 60, width: 60),
          ),
        ),
        const SizedBox(height: 6),
        Text(label),
      ],
    );
  }
}