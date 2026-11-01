import 'dart:io';
import 'package:aplikasi_warung_supabase/models/product_model.dart';
import 'package:aplikasi_warung_supabase/models/transaction_detail_model.dart';
import 'package:aplikasi_warung_supabase/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductProvider extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Method untuk menghitung profit per item individu
  num calculateItemProfit(ProductModel product, int quantity) {
    num costPrice = product.priceModal ?? 0; // Harga modal
    num sellingPrice = product.price; // Harga jual

    return (sellingPrice - costPrice) * quantity;
  }

  // Method untuk menghitung total profit dari list item transaksi hari ini
  num calculateTodayTotalProfit(List<TransactionDetailModel> todayItems) {
    num totalProfit = 0;

    for (var item in todayItems) {
      final product = _products.firstWhere(
        (p) => p.id == item.productId,
        orElse: () => ProductModel(
          id: '',
          price: item.price.toInt(),
          priceModal: item.price.toInt(),
          nameProduct: '',
          stock: 0,
        ),
      );

      num costPrice =
          product.priceModal ??
          item.price;
      num sellingPrice = item.price;

      num profitPerItem = (sellingPrice - costPrice) * item.quantity;

      // Debug log buat ngintip mana barang yang ngaco
      debugPrint(
        'Item: ${product.nameProduct} | Jual: $sellingPrice | Modal: $costPrice | Qty: ${item.quantity} | Untung: $profitPerItem',
      );

      totalProfit += profitPerItem;
    }

    return totalProfit;
  }

  // 1. Fetch Semua Produk dari Supabase
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('is_deleted', false)
          .order('name_product', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      _products = data.map((json) => ProductModel.fromJson(json)).toList();
    } catch (e) {
      _errorMessage = 'Gagal memuat produk: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Function Fetch Nama Kategori langsung ke Supabase
  // Fetch nama kategori berdasarkan categoryId
  Future<String> getCategoryName(String? categoryId) async {
    if (categoryId == null) return 'Tanpa Kategori';

    try {
      final response = await _supabase
          .from('categories')
          .select('name_category')
          .eq('id', categoryId)
          .maybeSingle();

      if (response != null && response['name_category'] != null) {
        return response['name_category'].toString();
      }
      return 'Tanpa Kategori';
    } catch (e) {
      debugPrint('Error fetch category name: $e');
      return 'Tanpa Kategori';
    }
  }

  // 2. Tambah Produk Baru
  Future<bool> addProduct({
    required String name,
    required int price,
    required int stock,
    required String categoryId,
    File? imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? imageUrl;

      // Upload gambar dulu kalau ada
      if (imageFile != null) {
        imageUrl = await uploadProductImage(imageFile);
      }

      // Insert ke tabel products Supabase
      await _supabase.from('products').insert({
        'name_product': name,
        'price': price,
        'stock': stock,
        'category_id': categoryId,
        'image_url': imageUrl,
        'is_deleted': false,
      });

      // Refresh list produk
      await fetchProducts();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error add product: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Upload Image
  Future<String?> uploadProductImage(File imageFile) async {
    try {
      imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = fileName;

      debugPrint('Mencoba upload gambar ke Supabase path: $path');

      // Upload ke Bucket 'product-images' di Supabase Storage
      await _supabase.storage
          .from(
            'products_photos',
          ) // Pastikan nama bucket di Supabase kamu sesuai
          .upload(
            path,
            imageFile,
            fileOptions: FileOptions(cacheControl: '3600', upsert: true),
          );

      // Dapatkan Public URL gambar yang sudah diupload
      final imageUrl = _supabase.storage
          .from('products_photos')
          .getPublicUrl(path);
      debugPrint('Upload Berhasil! URL Gambar: $imageUrl');

      return imageUrl;
    } catch (e) {
      debugPrint('Error upload image: $e');
      return null;
    }
  }

  // 3. Update Data Produk (Keseluruhan)
  Future<bool> updateProduct(
    String productId,
    ProductModel updatedProduct, {
    File? newImageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? finalImageUrl = updatedProduct.imageUrl;

      // 1. Jika pengguna memilih gambar baru, upload ke Supabase Storage
      if (newImageFile != null) {
        final uploadedUrl = await uploadProductImage(newImageFile);
        if (uploadedUrl != null) {
          finalImageUrl = uploadedUrl; // Gunakan URL gambar baru
        }
      }

      // 2. Update data ke tabel products Supabase
      await _supabase
          .from('products')
          .update({
            'name_product': updatedProduct.nameProduct,
            'price': updatedProduct.price,
            'price_modal': updatedProduct.priceModal,
            'stock': updatedProduct.stock,
            'stock_min': updatedProduct.stockMin,
            'unit': updatedProduct.unit,
            'category_id': updatedProduct.categoryId,
            'image_url': finalImageUrl, // URL gambar baru/lama disimpan ke DB
          })
          .eq('id', productId);

      await fetchProducts();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error update product: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 5. Hapus Produk
  Future<bool> deleteProduct(String id) async {
    try {
      await _supabase
          .from('products')
          .update({'is_deleted': true})
          .eq('id', id);

      await fetchProducts();
      return true;
    } catch (e) {
      debugPrint('Error delete product: $e');
      return false;
    }
  }
}
