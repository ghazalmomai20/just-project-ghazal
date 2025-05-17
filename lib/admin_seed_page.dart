import 'package:flutter/material.dart';
import 'seed_data.dart';

class AdminSeedPage extends StatelessWidget {
  const AdminSeedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Tools')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await seedMixedProducts();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Data seeded successfully!')),
            );
          },
          child: const Text('Seed Mixed Products'),
        ),
      ),
    );
  }
}
