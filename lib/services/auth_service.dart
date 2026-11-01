import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { owner, kasir, unknown }

class AuthService {
  final _supabase = Supabase.instance.client;

  // 🟢 Ambil Role User dari Tabel Profiles Supabase
  Future<UserRole> getUserRole() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return UserRole.unknown;

      final response = await _supabase
          .from('profiles') // Nama tabel profil/user lu
          .select('role')
          .eq('id', userId)
          .single();

      final roleString = response['role'] as String?;

      if (roleString == 'owner') return UserRole.owner;
      if (roleString == 'kasir') return UserRole.kasir;
      return UserRole.unknown;
    } catch (e) {
      return UserRole.unknown;
    }
  }
}