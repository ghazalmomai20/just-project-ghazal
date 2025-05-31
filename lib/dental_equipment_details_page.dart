import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'package:just_store_clean/widgets/favorite_button.dart';

class DentalEquipmentDetailsPage extends StatelessWidget {
  final String image;
  final String title;
  final String description;
  final String price;
  final String phoneNumber;
  final String receiverId;
  final String receiverName;
  final String receiverAvatar;

  const DentalEquipmentDetailsPage({
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

    // ✅ بيانات المنتج لزر المفضلة
    final productData = {
      'title': title,
      'description': description,
      'price': price,
      'image': image,
      'category': 'Dental Equipment',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF3B3B98),
        foregroundColor: Colors.white,
        actions: [
          FavoriteButton(
            productId: "$title-$price", // أو productId الحقيقي لو متوفر
            productData: productData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
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
              style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const Text('Contact Seller', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 15),
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
