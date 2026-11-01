import 'package:aplikasi_warung_supabase/models/users_model.dart';
import 'package:aplikasi_warung_supabase/helpers/auth_error_helper.dart';
import 'package:aplikasi_warung_supabase/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _userRole = 'kasir'; // Default role

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get obscurePassword => _obscurePassword;
  bool get rememberMe => _rememberMe;
  String get userRole => _userRole;
  bool get isOwner => _userRole.toLowerCase() == 'owner';
  // bool get isKasir => _userRole.toLowerCase() == 'kasir';

  // Toggle visibilitas password
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // Toggle checkbox remember me
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  // 1. Fungsi Login

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password, 
      );

      _isLoading = false;
      notifyListeners(); 

      if (response.session != null) {
        return {'success': true, 'message': null};
      } else {
        return {'success': false, 'message': 'Gagal melakukan otentikasi.'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      // Gunakan helper parseAuthError di sini
      final friendlyError = parseAuthError(e);
      return {'success': false, 'message': friendlyError};
    }
  }

  // 2. Fetch Profil & Role User dari Database
  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final response = await _supabase
            .from('users')
            .select('*')
            .eq('id', userId)
            .single();
            
        _currentUser = UserModel.fromJson(response);
        _userRole = response['role'] ?? 'kasir';
      }
    } catch (e) {
      debugPrint('Error fetch user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // 👈 Wajib dipanggil di finally agar loading berhenti
    }
  }

  // 3. Fungsi Logout
  Future<void> logout(BuildContext context) async {
    try {
      // 1. Sign out dari Supabase
      await _supabase.auth.signOut();

      // 2. Reset state user ke null
      _currentUser = null;
      notifyListeners();

      if (context.mounted) {
        // 3. Arahkan balik ke halaman Login dan hapus semua history stack halaman sebelumnya
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal logout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
