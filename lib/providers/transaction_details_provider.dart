import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aplikasi_warung_supabase/providers/cart_provider.dart';
import 'package:aplikasi_warung_supabase/models/transaction_model.dart';

class TransactionDetailsProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  DateTimeRange? _selectedDateRange;
  DateTime? _selectedSingleDate;
  List<TransactionModel> _customerTransactions = [];

  // Getter
  bool get isLoading => _isLoading;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  DateTime? get selectedSingleDate => _selectedSingleDate;
  List<TransactionModel> get customerTransactions => _customerTransactions;

  // File: lib/providers/transaction_details_provider.dart

  Future<bool> detailTransaction({
    required Map<String, CartItem> cartItems,
    required double totalAmount,
    required String paymentMethod,
    String? customerId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final String invoiceNumber =
          'INV-${DateTime.now().millisecondsSinceEpoch}';

      String dbPaymentMethod = 'Cash';
      if (paymentMethod.toLowerCase() == 'utang' ||
          paymentMethod.toLowerCase() == 'hutang') {
        dbPaymentMethod = 'Hutang';
      }

      final String? finalCustomerId =
          (customerId != null && customerId.isNotEmpty) ? customerId : null;

      print("🔍 STEP 1: Mencoba insert header transaction...");

      final transactionResponse = await _supabase
          .from('transaction')
          .insert({
            'invoice_number': invoiceNumber,
            'customer_id': finalCustomerId,
            'total_price': totalAmount.toInt(),
            'payment_method': dbPaymentMethod,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      print("✅ STEP 1 BERHASIL: Transaction ID = ${transactionResponse['id']}");

      final int transactionId = (transactionResponse['id'] is int)
          ? transactionResponse['id']
          : int.parse(transactionResponse['id'].toString());

      // Menyiapkan data detail
      final List<Map<String, dynamic>> detailsList = [];

      for (var entry in cartItems.entries) {
        final item = entry.value;

        final int unitPrice = item.product.price.toInt();
        final int subTotal = (item.totalPrice).toInt();

        detailsList.add({
          'transaction_id': transactionId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price': unitPrice,
          'sub_total': subTotal,
        });
      }

      print(
        "🔍 STEP 2: Mencoba insert batch ke transaction_details -> Data: $detailsList",
      );

      if (detailsList.isNotEmpty) {
        await _supabase.from('transaction_details').insert(detailsList);
        print("✅ STEP 2 BERHASIL: Insert transaction_details sukses!");
      }

      print("🔍 STEP 3: Updating stock products...");
      for (var entry in cartItems.entries) {
        final item = entry.value;
        final double currentStock = (item.product.stock).toDouble();
        final double newStock = currentStock - item.quantity;

        await _supabase
            .from('products')
            .update({'stock': newStock})
            .eq('id', item.product.id);
      }
      print("✅ STEP 3 BERHASIL: Update stok selesai!");

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print("❌ ERROR DETAIL SAMPAI SINI:");
      print("❌ Exception: $e");
      print("📍 StackTrace: $stackTrace");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 1. Filter Single Date (1 Tanggal Spesifik)
  void setSingleDate(DateTime? date, String customerId) {
    _selectedSingleDate = date;
    _selectedDateRange = null; // Reset date range jika pilih single date
    fetchTransactionsByCustomer(customerId);
  }

  // 2. Filter Date Range (Rentang Tanggal)
  void setDateRange(DateTimeRange? range, String customerId) {
    _selectedDateRange = range;
    _selectedSingleDate = null; // Reset single date jika pilih range
    fetchTransactionsByCustomer(customerId);
  }

  // 3. Reset Semua Filter Tanggal
  void clearDateFilter(String customerId) {
    _selectedDateRange = null;
    _selectedSingleDate = null;
    fetchTransactionsByCustomer(customerId);
  }

  Future<void> fetchTransactionsByCustomer(String customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('🟢 START fetchTransactionsByCustomer');
      debugPrint(
        '📌 customerId: $customerId (type: ${customerId.runtimeType})',
      );

      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(customerId);

      debugPrint('📌 isUuid: $isUuid');

      var query = _supabase
          .from('transaction')
          .select(
            '*, transaction_details(*, products(name_product, price_modal))',
          );

      if (isUuid) {
        debugPrint('🔍 Filter by customer_id (UUID): $customerId');
        query = query.eq('customer_id', customerId);
      } else {
        final int parsedId = int.tryParse(customerId) ?? 0;
        debugPrint('🔍 Filter by id (INT): $parsedId');
        query = query.eq('id', parsedId);
      }

      // Filter Single Date
      if (_selectedSingleDate != null) {
        final startIso = DateTime(
          _selectedSingleDate!.year,
          _selectedSingleDate!.month,
          _selectedSingleDate!.day,
        ).toIso8601String();

        final endIso = DateTime(
          _selectedSingleDate!.year,
          _selectedSingleDate!.month,
          _selectedSingleDate!.day,
          23,
          59,
          59,
        ).toIso8601String();

        debugPrint('📅 Filter Single Date: $startIso - $endIso');
        query = query.gte('created_at', startIso).lte('created_at', endIso);
      }
      // Filter Date Range
      else if (_selectedDateRange != null) {
        final startIso = _selectedDateRange!.start.toIso8601String();
        final endIso = _selectedDateRange!.end
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1))
            .toIso8601String();

        debugPrint('📅 Filter Date Range: $startIso - $endIso');
        query = query.gte('created_at', startIso).lte('created_at', endIso);
      }

      debugPrint('🔄 Executing query...');
      final response = await query.order('created_at', ascending: false);

      debugPrint('✅ Query successful!');
      debugPrint('📊 Total data from DB: ${response.length}');

      if (response.isEmpty) {
        debugPrint('⚠️ No data found!');
        _customerTransactions = [];
        return;
      }

      // 🔍 DEBUG: Cek struktur data pertama
      final firstData = response[0] as Map<String, dynamic>;
      debugPrint('🔍 First data structure:');
      debugPrint('  - Keys: ${firstData.keys}');
      debugPrint('  - id: ${firstData['id']} (${firstData['id'].runtimeType})');
      debugPrint(
        '  - invoice_number: ${firstData['invoice_number']} (${firstData['invoice_number'].runtimeType})',
      );
      debugPrint(
        '  - customer_id: ${firstData['customer_id']} (${firstData['customer_id'].runtimeType})',
      );
      debugPrint(
        '  - total_price: ${firstData['total_price']} (${firstData['total_price'].runtimeType})',
      );
      debugPrint(
        '  - payment_method: ${firstData['payment_method']} (${firstData['payment_method'].runtimeType})',
      );
      debugPrint(
        '  - created_at: ${firstData['created_at']} (${firstData['created_at'].runtimeType})',
      );

      // 🔍 DEBUG: Cek transaction_details
      if (firstData.containsKey('transaction_details')) {
        final details = firstData['transaction_details'] as List?;
        debugPrint('  - transaction_details: ${details?.length ?? 0} items');
        if (details != null && details.isNotEmpty) {
          final firstDetail = details[0] as Map<String, dynamic>;
          debugPrint('    - First detail keys: ${firstDetail.keys}');
          debugPrint(
            '    - product_id: ${firstDetail['product_id']} (${firstDetail['product_id'].runtimeType})',
          );
          debugPrint(
            '    - quantity: ${firstDetail['quantity']} (${firstDetail['quantity'].runtimeType})',
          );
          debugPrint(
            '    - price: ${firstDetail['price']} (${firstDetail['price'].runtimeType})',
          );
          debugPrint(
            '    - sub_total: ${firstDetail['sub_total']} (${firstDetail['sub_total'].runtimeType})',
          );

          // 🔍 DEBUG: Cek products
          if (firstDetail.containsKey('products')) {
            final product = firstDetail['products'] as Map<String, dynamic>?;
            if (product != null) {
              debugPrint(
                '    - product name: ${product['name_product']} (${product['name_product'].runtimeType})',
              );
              debugPrint(
                '    - price_modal: ${product['price_modal']} (${product['price_modal'].runtimeType})',
              );
            }
          }
        }
      }

      // 🔍 DEBUG: Proses mapping satu per satu
      debugPrint('🔄 Mapping data to TransactionModel...');
      _customerTransactions = [];

      for (var i = 0; i < response.length; i++) {
        try {
          final data = response[i] as Map<String, dynamic>;
          debugPrint('  🔄 Mapping item $i:');
          debugPrint(
            '    - total_price type: ${data['total_price'].runtimeType}',
          );
          debugPrint('    - total_price value: ${data['total_price']}');

          final model = TransactionModel.fromMap(data);
          _customerTransactions.add(model);
          debugPrint('    ✅ Item $i mapped successfully');
        } catch (e, stackTrace) {
          debugPrint('  ❌ Error mapping item $i: $e');
          debugPrint('  📚 Stack trace: $stackTrace');
          // Re-throw untuk di-catch di outer catch
          rethrow;
        }
      }

      debugPrint(
        '✅ Total mapped: ${_customerTransactions.length} transactions',
      );
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ ERROR fetch customer transactions: $e');
      debugPrint('📚 Stack trace: $stackTrace');

      // 🔍 DEBUG: Cek tipe data yang bermasalah
      if (e.toString().contains('double') && e.toString().contains('int')) {
        debugPrint('💡 HINT: Masalah konversi double ke int!');
        debugPrint('💡 Solusi: Pastikan model pake num, bukan int');
      } else if (e.toString().contains('String') &&
          e.toString().contains('int')) {
        debugPrint('💡 HINT: Masalah konversi String ke int!');
        debugPrint('💡 Solusi: Parse String ke int dengan int.tryParse()');
      } else if (e.toString().contains('null')) {
        debugPrint('💡 HINT: Ada data null!');
        debugPrint('💡 Solusi: Cek kolom yang boleh null di database');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('🏁 FINISHED fetchTransactionsByCustomer');
    }
  }

  void refreshTotalTransactions(String customerId) {
    // Reset list transaksi customer
    _customerTransactions = [];
    notifyListeners();

    // Fetch ulang
    fetchTransactionsByCustomer(customerId);
  }

  void clearAllCustomerTransactions() {
    _customerTransactions = [];
    _isLoading = false;
    _selectedSingleDate = null;
    _selectedDateRange = null;
    notifyListeners();
  }
}
