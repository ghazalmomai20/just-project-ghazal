import 'dart:io';

class Product {
  final List<File> images;
  final String description;
  final String price;
  final String phone;
  final String category;

  Product({
    required this.images,
    required this.description,
    required this.price,
    required this.phone,
    required this.category,
  });
}
