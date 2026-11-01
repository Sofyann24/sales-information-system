import 'package:aplikasi_warung_supabase/providers/auth_provider.dart';
import 'package:aplikasi_warung_supabase/widgets/show_dialogs.dart';
import 'package:aplikasi_warung_supabase/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().fetchUserProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 👈 Pakai 1 variabel provider saja
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    // Tampilkan loading jika sedang fetch data ATAU jika user belum ter-load
    if (authProvider.isLoading || currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppbar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. User Header Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Color(0xFF2196F3),
                    child: Icon(
                      Icons.store_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.name ?? 'Tanpa Nama',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.role,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Menu Section Group
            Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF2196F3),
                  ),
                  title: const Text(
                    'Pengaturan Akun',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black54,
                  ),
                  onTap: () {},
                ),
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Color(0xFFE2E8F0),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF2196F3),
                  ),
                  title: const Text(
                    'Ubah Password / PIN',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black54,
                  ),
                  onTap: () {},
                ),
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Color(0xFFE2E8F0),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF2196F3),
                  ),
                  title: const Text(
                    'Informasi Aplikasi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  trailing: const Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Logout Button
            ListTile(
              leading: const Icon(
                Icons.logout_rounded,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Keluar dari Akun',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              onTap: () {
                LogoutDialog.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
