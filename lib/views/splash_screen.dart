// ignore_for_file: use_build_context_synchronously

import 'package:aplikasi_warung_supabase/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SupabaseClient _supabase = SupabaseService.client;
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    // Ambil status remember_me (default true agar tidak gampang mental saat dev)
    final bool rememberMe = prefs.getBool('remember_me') ?? false;

    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;

    // JIKA SESI AKTIF (User sudah login di Supabase)
    if (session != null && user != null) {
      if (rememberMe) {
        // User centang 'Tetap Masuk' -> Bablas ke Home
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // User NGGAK centang 'Tetap Masuk' -> Hapus sesi & lempar ke Login
        await _supabase.auth.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      // Memang belum login sama sekali -> Ke Login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Toko
            Container(
              width: 150,
              height: 150,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Image.asset('assets/logo_warung.png'),
            ),
            const SizedBox(height: 32),
            // Indikator Loading
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
