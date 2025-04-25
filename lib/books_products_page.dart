import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart'; // تأكد من المسار
import 'book_details_page.dart';

class BooksProductsPage extends StatelessWidget {
  const BooksProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final products = Provider.of<ProductProvider>(context).getProductsByCategory('Books & Slides');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        title: const Text('Books & Slides', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: products.isEmpty
          ? const Center(child: Text("No books available"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(product.images.first, width: 50, height: 50, fit: BoxFit.cover),
                    ),
                    title: Text(product.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text("${product.price} JD"),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B3B98)),
                      child: const Text("View"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookDetailsPage(
                              image: product.images.first.path,
                              title: "Book Product",
                              description: product.description,
                              price: product.price,
                              phoneNumber: product.phone,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
