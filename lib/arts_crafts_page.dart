import 'package:flutter/material.dart';
import 'arts_crafts_details_page.dart';

class ArtsCraftsPage extends StatefulWidget {
  const ArtsCraftsPage({super.key});

  @override
  State<ArtsCraftsPage> createState() => _ArtsCraftsPageState();
}

class _ArtsCraftsPageState extends State<ArtsCraftsPage> {
  final List<Map<String, String>> products = [
    {
      "title": "Acrylic Paint Kit",
      "description": "Full kit with acrylic paints & brushes.",
      "price": "10 JD",
      "image": "assets/arts&crafts.png",
      "phoneNumber": "+962788888888"
    },
    {
      "title": "Sketching Set",
      "description": "Professional pencils and paper bundle.",
      "price": "7 JD",
      "image": "assets/arts&crafts.png",
      "phoneNumber": "+962799999999"
    },
  ];

  String _search = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = products.where((item) {
      return item['title']!.toLowerCase().contains(_search.toLowerCase());
    }).toList();

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
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: Image.asset(item['image']!, width: 60),
                      title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item['description']!),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArtsCraftsDetailsPage(
                                image: item['image']!,
                                title: item['title']!,
                                description: item['description']!,
                                price: item['price']!,
                                phoneNumber: item['phoneNumber']!,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
