import 'package:aplikasi_warung_supabase/models/categories_model.dart';
import 'package:aplikasi_warung_supabase/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryProvider extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;
  List<CategoryModel> _categories = [];
  bool _isLoading = false;

  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;

  // Fetch Kategori
  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('categories')
          .select('*')
          .order('name_category', ascending: true);

      final List<dynamic> data = response;
      _categories = data.map((item) => CategoryModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error fetch categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Tambah Kategori
  Future<bool> addCategory(String categoryName) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabase.from('categories').insert({
        'name_category': categoryName,
      });

      await fetchCategories();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error add category: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Edit Kategori
  Future<bool> updateCategory(String id, String newName) async {
    try {
      await _supabase
          .from('categories')
          .update({'name_category': newName})
          .eq('id', id);

      await fetchCategories();
      return true;
    } catch (e) {
      debugPrint('Error update category: $e');
      return false;
    }
  }

  // Hapus Kategori
  Future<bool> deleteCategory(String id) async {
    try {
      await _supabase.from('categories').delete().eq('id', id);

      await fetchCategories();
      return true;
    } catch (e) {
      debugPrint('Error delete category: $e');
      return false;
    }
  }
}
