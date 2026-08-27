//TODO: Family members populate here
//TODO: Create visual family tree with family members and children in future

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                context.go('/family/dashboard');
              },
              child: const Text('Go to Family Dashboard'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.go('/family/create');
              },
              child: const Text('Create a Family'),
            ),
          ],
        ),
      ),
    );
  }
}