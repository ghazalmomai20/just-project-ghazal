import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'package:just_store_clean/widgets/favorite_button.dart';

class BookDetailsPage extends StatefulWidget {
  final String productId;

  const BookDetailsPage({super.key, required this.productId});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  Map<String, dynamic>? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final doc = await FirebaseFirestore.instance.collection('products').doc(widget.productId).get();
    if (doc.exists) {
      setState(() {
        data = doc.data();
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (data == null) {
      return const Scaffold(
        body: Center(child: Text('Product not found.')),
      );
    }

    final image = data!['imageUrl'] ?? '';
    final title = data!['name'] ?? '';
    final description = data!['description'] ?? '';
    final price = data!['price'] ?? '';
    final phoneNumber = data!['phone'] ?? '';
    final receiverId = data!['ownerId'] ?? '';
    final receiverName = data!['ownerName'] ?? 'User';
    final receiverAvatar = data!['ownerAvatar'] ?? '';

    // ✅ تجهيز البيانات للمفضلة
    final productData = {
      'title': title,
      'description': description,
      'price': price,
      'image': image,
      'category': 'Books',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF3B3B98),
        foregroundColor: Colors.white,
        actions: [
          // ✅ زر المفضلة
          FavoriteButton(
            productId: widget.productId,
            productData: productData,
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
              ),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[300] : Colors.grey[800]),
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
                        title: const Text("📞 Contact Seller"),
                        content: Text("Call this number:\n$phoneNumber"),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
                      ),
                    );
                  },
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                          userName: user?.displayName ?? '',
                          userAvatar: user?.photoURL ?? '',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Chat'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B3B98)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
