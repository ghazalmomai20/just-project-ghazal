import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'electronics_details_page.dart';

class ElectronicsPage extends StatefulWidget {
  const ElectronicsPage({super.key});

  @override
  State<ElectronicsPage> createState() => _ElectronicsPageState();
}

class _ElectronicsPageState extends State<ElectronicsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        title: const Text('Electronics', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (val) => setState(() => _search = val),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search electronics...',
                filled: true,
                fillColor: isDark ? Colors.grey[850] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .where('category', isEqualTo: 'Electronics')
                    .orderBy('title')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No electronics found.'));
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
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              data['imageUrl'] ?? '',
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                            ),
                          ),
                          title: Text(data['title'] ?? ''),
                          subtitle: Text(data['description'] ?? ''),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ElectronicsDetailsPage(
                                    image: data['imageUrl'] ?? '',
                                    title: data['title'] ?? '',
                                    description: data['description'] ?? '',
                                    price: data['price'] ?? '',
                                    phoneNumber: data['phone'] ?? '',
                                    receiverId: data['ownerId'] ?? '',
                                    receiverName: data['ownerName'] ?? 'Seller',
                                    receiverAvatar: data['ownerAvatar'] ?? '',
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B3B98),
                            ),
                            child: const Text("View"),
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
