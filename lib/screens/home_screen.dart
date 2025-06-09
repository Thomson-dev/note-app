import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/confirm_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _showSignOutDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder:
          (context) => ConfirmDialog(
            title: 'Sign Out',
            content: 'Are you sure you want to sign out?',
            confirmText: 'Sign Out',
            onConfirm: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showSignOutDialog(context),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: const Center(child: Text('Welcome to My Note App!')),
    );
  }
}
