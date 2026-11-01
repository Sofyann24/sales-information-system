import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionService {
  final _supabase = Supabase.instance.client;

  // File: lib/services/transaction_service.dart

  Future<num> getTodayProfit() async {
    try {
      final now = DateTime.now();
      // Gunakan DateTime UTC / ISO String lokal
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ).toUtc().toIso8601String();
      final endOfDay = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).toUtc().toIso8601String();

      print("DEBUG: Range Tanggal = $startOfDay s/d $endOfDay");

      // 🔴 Perbaikan: Mengubah 'transactions' menjadi 'transaction'
      // Catatan: Jika nama tabel detail transaksi juga tanpa 's', ubah 'transaction_details' jadi 'transaction_detail'
      final response = await _supabase
          .from('transaction')
          .select(
            'id, transaction_details(quantity, price, products(price_modal))',
          )
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);

      print("DEBUG: Response Supabase = $response");

      num totalProfit = 0;

      for (var transaction in response as List) {
        final details = transaction['transaction_details'] as List;
        for (var item in details) {
          final qty = item['quantity'] as num? ?? 0;
          final sellPrice = item['price'] as num? ?? 0;

          // Ambil buy_price dari relasi products
          final productData = item['products'];
          final buyPrice =
              (productData != null && productData['price_modal'] != null)
              ? productData['price_modal'] as num
              : 0;

          final profitPerItem = (sellPrice - buyPrice) * qty;
          print(
            "DEBUG: Qty: $qty, Sell: $sellPrice, Buy: $buyPrice => Profit: $profitPerItem",
          );

          totalProfit += profitPerItem;
        }
      }

      print("DEBUG: Total Profit Akhir = $totalProfit");
      return totalProfit;
    } catch (e) {
      print("DEBUG ERROR: $e");
      return 0;
    }
  }
}
