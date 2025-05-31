import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'package:just_store_clean/widgets/favorite_button.dart';

class ArtsCraftsDetailsPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final String price;
  final String phoneNumber;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;

  const ArtsCraftsDetailsPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    required this.price,
    required this.phoneNumber,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    // ✅ تجهيز بيانات المنتج لإرسالها إلى زر المفضلة
    final productData = {
      'title': title,
      'description': description,
      'price': price,
      'image': image,
      'category': 'Arts', // عدّلها حسب الكاتيجوري الحالي
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        title: Text(title),
        centerTitle: true,
        foregroundColor: Colors.white,
        actions: [
          // ✅ زر المفضلة داخل AppBar
          FavoriteButton(
            productId: "$title-$price", // أو أي ID فريد
            productData: productData,
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[300] : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '$price JD',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Contact Seller',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Call Seller'),
                        content: Text('Phone: $phoneNumber'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          receiverId: receiverId,
                          receiverName: receiverName,
                          receiverAvatar: receiverAvatar,
                          userName: user?.displayName ?? 'Guest',
                          userAvatar: user?.photoURL ?? '',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B3B98),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
