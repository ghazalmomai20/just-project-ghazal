// ✅ File: lib/utils/seed_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> seedMixedProducts() async {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'demo-seed-user';

  final products = [
    // Electronics
    {
      'title': 'MacBook Pro 2019 - Used',
      'category': 'electronics',
      'tags': ['macbook', 'laptop', 'used', 'cs'],
      'college': 'General',
    },
    {
      'title': 'iPad 10th Gen + Apple Pencil',
      'category': 'electronics',
      'tags': ['ipad', 'tablet', 'design', 'notes'],
      'college': 'General',
    },
    {
      'title': 'Sony WH-1000XM5 Headphones',
      'category': 'electronics',
      'tags': ['headphones', 'noise cancelling', 'study'],
      'college': 'General',
    },
    {
      'title': 'Samsung Galaxy Watch 4',
      'category': 'electronics',
      'tags': ['watch', 'smart', 'fitness'],
      'college': 'General',
    },

    // Clothes
    {
      'title': 'Medical Scrubs (Blue - Size L)',
      'category': 'clothes',
      'tags': ['scrubs', 'uniform', 'nursing'],
      'college': 'Nursing',
    },
    {
      'title': 'Clinical Lab Coat - M',
      'category': 'clothes',
      'tags': ['lab coat', 'clinical', 'white'],
      'college': 'Medicine',
    },
    {
      'title': 'Graduation Gown & Cap Set',
      'category': 'clothes',
      'tags': ['graduation', 'gown', 'cap'],
      'college': 'General',
    },
    {
      'title': 'JUST Hoodie – Navy Blue',
      'category': 'clothes',
      'tags': ['hoodie', 'just', 'merch', 'winter'],
      'college': 'General',
    },

    // Dental Tools
    {
      'title': 'Dental Explorers Set',
      'category': 'tools',
      'tags': ['dental', 'tools', 'clinic', 'training'],
      'college': 'Dentistry',
    },
    {
      'title': 'Typodont Training Model',
      'category': 'tools',
      'tags': ['dental', 'typodont', 'simulation'],
      'college': 'Dentistry',
    },

    // Architecture Tools
    {
      'title': 'Architecture Model Kit',
      'category': 'tools',
      'tags': ['architecture', 'models', 'kit'],
      'college': 'Architecture',
    },
    {
      'title': 'Sketching Ruler Set',
      'category': 'stationery',
      'tags': ['architecture', 'ruler', 'drafting'],
      'college': 'Architecture',
    },
  ];

  for (var product in products) {
    await FirebaseFirestore.instance.collection('products').add({
      ...product,
      'createdBy': uid,
      'timestamp': Timestamp.now(),
    });
  }
}