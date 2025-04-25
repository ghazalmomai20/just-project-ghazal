// ignore: unused_import
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/product_model.dart'; // تأكد من صحة المسار

class ProductProvider with ChangeNotifier {
  final List<Product> _products = [];

  List<Product> get allProducts => _products;

  List<Product> getProductsByCategory(String category) {
    return _products.where((item) => item.category == category).toList();
  }

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }
}
