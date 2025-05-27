import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import 'book_details_page.dart';

class BooksProductsPage extends StatelessWidget {
  const BooksProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final products = Provider.of<ProductProvider>(context).getProductsByCategory('Books');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3B3B98),
        title: const Text('Books', style: TextStyle(color: Colors.white)),
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
                child: Image.network(
                  product.imageUrl, // ✅ مصحح
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              ),
              title: Text(
                product.name, // ✅ استخدم name بدلاً من description
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text("${product.price} JD"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B3B98),
                  foregroundColor: Colors.white,
                ),
                child: const Text("View"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookDetailsPage(
                        productId: product.id!, // ✅ فقط productId مطلوب
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