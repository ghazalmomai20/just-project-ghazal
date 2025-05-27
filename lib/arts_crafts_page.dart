import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'arts_crafts_details_page.dart';

class ArtsCraftsPage extends StatefulWidget {
  const ArtsCraftsPage({super.key});

  @override
  State<ArtsCraftsPage> createState() => _ArtsCraftsPageState();
}

class _ArtsCraftsPageState extends State<ArtsCraftsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        title: const Text('Arts & Crafts', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _search = val),
              decoration: InputDecoration(
                hintText: 'Search arts...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('arts_products')
                    .orderBy('title')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No products found.'));
                  }

                  final filtered = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title']?.toString().toLowerCase() ?? '';
                    return title.contains(_search.toLowerCase());
                  }).toList();

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final data = filtered[index].data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: data['imageUrl'] != null
                              ? Image.network(data['imageUrl'], width: 60, fit: BoxFit.cover)
                              : const Icon(Icons.image_not_supported, size: 40),
                          title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(data['description'] ?? ''),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ArtsCraftsDetailsPage(
                                    image: data['imageUrl'] ?? '',
                                    title: data['title'] ?? '',
                                    description: data['description'] ?? '',
                                    price: data['price'] ?? '',
                                    phoneNumber: data['phoneNumber'] ?? '',
                                    receiverId: data['ownerId'] ?? '',
                                    receiverName: data['ownerName'] ?? 'User',
                                    receiverAvatar: data['ownerAvatar'] ?? '', // ✅ أضفناها
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B3B98),
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            child: const Text('View'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
