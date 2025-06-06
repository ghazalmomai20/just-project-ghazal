import 'package:flutter/material.dart';
import 'seed_data.dart';

class AdminSeedPage extends StatelessWidget {
  // ignore: use_super_parameters
  const AdminSeedPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Tools')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await seedMixedProducts();
            // ignore: use_build_context_synchronously
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
