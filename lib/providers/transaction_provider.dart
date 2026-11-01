import 'package:aplikasi_warung_supabase/models/transaction_model.dart';
import 'package:aplikasi_warung_supabase/providers/cart_provider.dart';
import 'package:aplikasi_warung_supabase/services/transaction_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  num _todayProfit = 0;
  num get todayProfit => _todayProfit;

  final TransactionService _transactionService = TransactionService();

  bool get isEmpty => _transactions.isEmpty;
  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<void> fetchTransactions() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('transaction')
          .select('*')
          .order('created_at', ascending: false);

      _transactions = (response as List)
          .map((data) => TransactionModel.fromMap(data))
          .toList();
    } catch (e) {
      debugPrint('Error fetch transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 💡 METHOD BARU: Membuat transaksi & otomatis mencatat ke tabel debt jika Utang
  // File: lib/providers/transaction_provider.dart

  Future<bool> createTransaction({
    required int totalPrice,
    required String paymentMethod,
    required Map<String, CartItem>
    cartItems, // 👈 Tambahkan parameter cartItems
    String? customerId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Format Payment Method untuk Konsistensi DB ('Cash' / 'Hutang')
      String dbPaymentMethod = 'Cash';
      if (paymentMethod.toLowerCase().contains('utang') ||
          paymentMethod.toLowerCase().contains('hutang')) {
        dbPaymentMethod = 'Hutang';
      }

      final String invoiceNumber =
          'INV-${DateTime.now().millisecondsSinceEpoch}';

      // 2. Simpan Header Transaksi Baru
      final txResponse = await _supabase
          .from('transaction')
          .insert({
            'invoice_number': invoiceNumber,
            'total_price': totalPrice,
            'payment_method': dbPaymentMethod,
            'customer_id': customerId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final int transactionId = (txResponse['id'] is int)
          ? txResponse['id']
          : int.parse(txResponse['id'].toString());

      // 3. Simpan Detail Item (Rincian Barang & Harga Modal) ke 'transaction_details'
      final List<Map<String, dynamic>> detailsList = [];
      for (var entry in cartItems.entries) {
        final item = entry.value;
        detailsList.add({
          'transaction_id': transactionId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price.toInt(),
          'sub_total': item.totalPrice.toInt(),
        });
      }

      if (detailsList.isNotEmpty) {
        await _supabase.from('transaction_details').insert(detailsList);
      }

      // 4. Update Stok Produk di 'products'
      for (var entry in cartItems.entries) {
        final item = entry.value;
        final double currentStock = (item.product.stock).toDouble();
        final double newStock = currentStock - item.quantity;

        await _supabase
            .from('products')
            .update({'stock': newStock})
            .eq('id', item.product.id);
      }

      // 5. Jika Utang -> Insert ke tabel 'debt'
      if (dbPaymentMethod == 'Hutang') {
        await _supabase.from('debt').insert({
          'transaction_id': transactionId,
          'customer_id': customerId,
          'total_debt': totalPrice,
          'remaining_amount': totalPrice,
          'status': 'Belum Lunas',
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 6. Refresh list transaksi lokal
      await fetchTransactions();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error create transaction: $e');
      debugPrint('📍 StackTrace: $stackTrace');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 💡 Getter untuk menghitung Total Omset / Pendapatan Hari Ini
  int get todayTotalSales {
    final now = DateTime.now();

    final todayTransactions = _transactions.where((item) {
      return item.createdAt.year == now.year &&
          item.createdAt.month == now.month &&
          item.createdAt.day == now.day;
    });

    int totalSales = 0;
    for (var tx in todayTransactions) {
      totalSales += tx.totalPrice.toInt();
    }

    return totalSales;
  }

  Future<void> fetchTodayProfit() async {
    try {
      _todayProfit = await _transactionService.getTodayProfit();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetch today profit: $e');
    }
  }
}
