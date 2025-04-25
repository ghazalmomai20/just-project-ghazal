import 'package:flutter/material.dart';
import 'electronics_details_page.dart';

class ElectronicsPage extends StatefulWidget {
  const ElectronicsPage({super.key});

  @override
  State<ElectronicsPage> createState() => _ElectronicsPageState();
}

class _ElectronicsPageState extends State<ElectronicsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> allProducts = [];
  List<Map<String, String>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _loadElectronics();
  }

  void _loadElectronics() {
    allProducts = [
      {
        'image': 'assets/laptop.png',
        'title': 'Lenovo Laptop',
        'description': 'Core i5, 8GB RAM, 256GB SSD',
        'price': '320',
        'phone': '+962799998888',
      },
      {
        'image': 'assets/laptop.png',
        'title': 'HP Notebook',
        'description': 'Core i7, 16GB RAM, 512GB SSD',
        'price': '480',
        'phone': '+962788887777',
      },
    ];
    filteredProducts = List.from(allProducts);
  }

  void _filter(String query) {
    setState(() {
      filteredProducts = allProducts
          .where((item) => item['title']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        title: const Text('Electronics', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white), 
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filter,
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
              child: filteredProducts.isEmpty
                  ? const Center(child: Text('No electronics found.'))
                  : ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final item = filteredProducts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(item['image']!, width: 50, height: 50, fit: BoxFit.cover),
                            ),
                            title: Text(item['title']!),
                            subtitle: Text(item['description']!),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ElectronicsDetailsPage(
                                      image: item['image']!,
                                      title: item['title']!,
                                      description: item['description']!,
                                      price: item['price']!,
                                      phoneNumber: item['phone']!,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B3B98)),
                              child: const Text("View"),
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
