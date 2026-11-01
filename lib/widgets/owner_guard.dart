import 'package:aplikasi_warung_supabase/services/auth_service.dart';
import 'package:flutter/material.dart';

class OwnerGuard extends StatelessWidget {
  final Widget child;

  const OwnerGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserRole>(
      future: AuthService().getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data == UserRole.owner) {
          return child;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Akses Ditolak')),
          body: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Akses Khusus Owner!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Halaman ini tidak dapat diakses oleh Kasir.'),
              ],
            ),
          ),
        );
      },
    );
  }
}
