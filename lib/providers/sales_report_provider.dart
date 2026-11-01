import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesReportProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  int _selectedFilterIndex = 0;
  int _uangMasuk = 0;
  int _totalUtang = 0;

  bool get isLoading => _isLoading;
  int get selectedFilterIndex => _selectedFilterIndex;
  int get uangMasuk => _uangMasuk;
  int get totalUtang => _totalUtang;

  DateTimeRange _selectedDateRange = DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now(),
  );
  DateTimeRange get selectedDateRange => _selectedDateRange;

  int _totalOmset = 0;
  int get totalOmset => _totalOmset;

  int _totalNota = 0;
  int get totalNota => _totalNota;

  int _totalItemUnik = 0;
  int get totalItemUnik => _totalItemUnik;

  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> get topProducts => _topProducts;

  // Set filter default
  void setFilter(int index, {DateTimeRange? customRange}) {
    _selectedFilterIndex = index;
    final now = DateTime.now();

    if (index == 0) {
      _selectedDateRange = DateTimeRange(start: now, end: now);
    } else if (index == 1) {
      _selectedDateRange = DateTimeRange(
        start: now.subtract(const Duration(days: 6)),
        end: now,
      );
    } else if (index == 2) {
      _selectedDateRange = DateTimeRange(
        start: now.subtract(const Duration(days: 29)),
        end: now,
      );
    } else if (index == 3 && customRange != null) {
      _selectedDateRange = customRange;
    }

    fetchSalesReport();
  }

  Future<void> fetchSalesReport() async {
    _isLoading = true;
    notifyListeners();

    try {
      final startDate = DateTime(
        _selectedDateRange.start.year,
        _selectedDateRange.start.month,
        _selectedDateRange.start.day,
        0,
        0,
        0,
      ).toIso8601String();

      final endDate = DateTime(
        _selectedDateRange.end.year,
        _selectedDateRange.end.month,
        _selectedDateRange.end.day,
        23,
        59,
        59,
      ).toIso8601String();

      // 1. Fetch data dari tabel 'transaction'
      final txResponse = await _supabase
          .from('transaction')
          .select('id, total_price')
          .gte('created_at', startDate)
          .lte('created_at', endDate);

      final List txList = txResponse as List;
      _totalNota = txList.length;

      _totalOmset = txList.fold<int>(
        0,
        (sum, item) => sum + ((item['total_price'] as num?)?.toInt() ?? 0),
      );
      _uangMasuk = txList.fold<int>(
        0,
        (sum, item) => sum + ((item['total_price'] as num?)?.toInt() ?? 0),
      );

      // Jika ada field status/payment_method di tabel transaction untuk membedakan utang
      _totalUtang = txList
          .where((item) {
            final method =
                (item['payment_method'] as String?)?.toLowerCase() ?? '';

            // 💡 Cek string 'hutang' (sesuai gambar DB)
            return method == 'hutang' || method == 'utang';
          })
          .fold<int>(
            0,
            (sum, item) => sum + ((item['total_price'] as num?)?.toInt() ?? 0),
          );

      final List<dynamic> txIds = txList.map((e) => e['id']).toList();

      if (txIds.isEmpty) {
        _totalItemUnik = 0;
        _topProducts = [];
      } else {
        // 2. Fetch data dari tabel 'transaction_details' + Join ke tabel 'products'
        final itemsResponse = await _supabase
            .from('transaction_details')
            .select(
              'product_id, quantity, price, sub_total, products(name_product)',
            )
            .inFilter('transaction_id', txIds);

        final List itemsList = itemsResponse as List;

        // Hitung Item Unik & Agregasi Produk Terlaris
        final Map<String, Map<String, dynamic>> productMap = {};

        for (var item in itemsList) {
          // Ambil nama produk dari join relasi tabel products
          final productData = item['products'] as Map<String, dynamic>?;
          final pName = productData?['name_product'] ?? 'Produk Tanpa Nama';

          final qty = (item['quantity'] as num?)?.toInt() ?? 0;
          final subTotal =
              (item['sub_total'] as num?)?.toInt() ??
              (qty * ((item['price'] as num?)?.toInt() ?? 0));

          if (!productMap.containsKey(pName)) {
            productMap[pName] = {
              'name_product': pName,
              'qty': 0,
              'total_sales': 0,
            };
          }

          productMap[pName]!['qty'] = (productMap[pName]!['qty'] as int) + qty;
          productMap[pName]!['total_sales'] =
              (productMap[pName]!['total_sales'] as int) + subTotal;
        }

        _totalItemUnik = productMap.keys.length;

        // Sort Top Products berdasarkan jumlah produk terbanyak yang terjual
        final sortedList = productMap.values.toList();
        sortedList.sort((a, b) => (b['qty'] as int).compareTo(a['qty'] as int));
        _topProducts = sortedList;
      }
    } catch (e) {
      debugPrint('Error fetch sales report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
