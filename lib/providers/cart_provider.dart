import 'package:flutter/material.dart';
import 'package:aplikasi_warung_supabase/models/product_model.dart';

class CartItem {
  final ProductModel product;
  double quantity;

  CartItem({required this.product, required this.quantity});

  double get totalPrice => (product.price) * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  // Total Jenis Produk di Keranjang (untuk Badge Tombol Melayang)
  int get itemCount => _items.length;

  // Total Harga Keseluruhan
  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.totalPrice;
    });
    return total;
  }

  // Cek Jumlah Produk Tertentu
  double getQuantity(String productId) {
    if (_items.containsKey(productId)) {
      return _items[productId]!.quantity;
    }
    return 0.0;
  }

  // Tambah Produk / Tambah Kuantitas (+1)
  void addItem(ProductModel product) {
    if (_items.containsKey(product.id)) {
      _items.update(
        product.id,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        product.id,
        () => CartItem(product: product, quantity: 1.0),
      );
    }
    notifyListeners();
  }

  // Kurangi Kuantitas (-1)
  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existing) => CartItem(
          product: existing.product,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  // Update Kuantitas Manual dari Input Text (Khusus desimal/kg)
  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      _items.remove(productId);
    } else if (_items.containsKey(productId)) {
      _items[productId]!.quantity = quantity;
    }
    notifyListeners();
  }

  // Hapus Item dari Keranjang
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Reset Keranjang Setelah Transaksi Selesai
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
