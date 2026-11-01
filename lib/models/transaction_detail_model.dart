import 'package:aplikasi_warung_supabase/models/product_model.dart';

class TransactionDetailModel {
  final int id;
  final int transactionId;
  final String productId;
  final num quantity;
  final num price; // ⭐ num
  final num subtotal; // ⭐ num
  final DateTime createdAt;
  final ProductModel? product; // ⭐ Opsional: buat relasi

  TransactionDetailModel({
    required this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.createdAt,
    this.product,
  });

  factory TransactionDetailModel.fromMap(Map<String, dynamic> map) {
    // ⭐ Helper parse num
    num parseNum(dynamic value) {
      if (value is num) return value;
      if (value is String) return num.tryParse(value) ?? 0;
      return 0;
    }

    // ⭐ Parse product jika ada
    ProductModel? product;
    if (map['products'] != null && map['products'] is Map<String, dynamic>) {
      product = ProductModel.fromJson(map['products'] as Map<String, dynamic>);
    }

    return TransactionDetailModel(
      id: map['id'] as int,
      transactionId: map['transaction_id'] as int,
      productId: map['product_id'] as String,
      quantity: map['quantity'] as double,
      price: parseNum(map['price']),
      subtotal: parseNum(map['sub_total'] ?? map['subtotal']),
      createdAt: DateTime.parse(map['created_at'] as String),
      product: product,
    );
  }
}
