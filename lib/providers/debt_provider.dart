import 'package:aplikasi_warung_supabase/models/debt_payment_model.dart';
import 'package:aplikasi_warung_supabase/models/debt_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DebtProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<DebtModel> _debts = [];
  List<DebtModel> _groupedDebts = [];
  bool _isLoading = false;
  List<DebtPaymentModel> _paymentHistory = [];

  List<DebtModel> get debts => _debts;
  List<DebtModel> get groupedDebts => _groupedDebts;
  bool get isLoading => _isLoading;
  List<DebtPaymentModel> get paymentHistory => _paymentHistory;

  int get totalPiutang {
    return _groupedDebts.fold(0, (sum, item) => sum + item.remainingAmount);
  }

  // 1. Fetch seluruh daftar utang yang belum lunas
  Future<void> fetchDebts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('debt')
          .select('*, customers(*)')
          .neq('status', 'Lunas')
          .order('created_at', ascending: false);

      final List rawData = response as List;

      final List<DebtModel> allDebts = [];
      for (var i = 0; i < rawData.length; i++) {
        try {
          final model = DebtModel.fromJson(rawData[i]);
          allDebts.add(model);
        } catch (e) {
          debugPrint('Error parsing debt item: $e');
        }
      }

      _debts = allDebts;

      final Map<String, List<DebtModel>> mapGroup = {};

      for (var debt in allDebts) {
        final String name = debt.customer?.nameCustomer ?? 'Pelanggan';
        final String nameKey = name.trim().toLowerCase();

        final key = nameKey.isNotEmpty ? nameKey : 'unknown_${debt.id}';

        if (!mapGroup.containsKey(key)) {
          mapGroup[key] = [];
        }
        mapGroup[key]!.add(debt);
      }

      _groupedDebts = mapGroup.entries.map<DebtModel>((entry) {
        final list = entry.value;
        final first = list.first;

        int totalDebtSum = 0;
        int remainingAmountSum = 0;

        for (var item in list) {
          totalDebtSum += item.totalDebt;
          remainingAmountSum += item.remainingAmount;
        }

        return DebtModel(
          id: first.id,
          createdAt: first.createdAt,
          customerId: first.customerId,
          customer: first.customer,
          transactionId: first.transactionId,
          totalDebt: totalDebtSum,
          remainingAmount: remainingAmountSum,
          status: first.status,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetch debts: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. Fetch Riwayat Pembayaran
  Future<void> fetchPaymentHistory(int debtId) async {
    try {
      final response = await _supabase
          .from('debt_payment')
          .select()
          .eq('debt_id', debtId)
          .order('created_at', ascending: false);

      final List data = response as List;
      _paymentHistory = data.map((e) => DebtPaymentModel.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetch payment history: $e');
    }
  }

  // 3. Submit Pembayaran (Cicil / Lunas) - SUDAH DI-FIX!
  Future<bool> payDebt({
    required DebtModel debt,
    required int amountPaid,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      // A. Catat ke tabel debt_payment
      await _supabase.from('debt_payment').insert({
        'debt_id': debt.id,
        'amount_paid': amountPaid,
        'payment_method': paymentMethod,
        'notes': notes,
      });

      // B. Hitung sisa utang baru
      final newRemaining = debt.remainingAmount - amountPaid;
      final newStatus = newRemaining <= 0 ? 'Lunas' : 'Belum Lunas';

      // C. Update tabel debt
      await _supabase
          .from('debt')
          .update({
            'remaining_amount': newRemaining < 0 ? 0 : newRemaining,
            'status': newStatus,
            // ⭐ FIX: Hapus 'updated_at' kalo kolomnya gak ada di database!
            // 'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', debt.id);

      // D. UPDATE TABEL TRANSACTIONS JIKA UTANG SUDAH LUNAS
      if (newRemaining <= 0 && debt.transactionId != null) {
        await _supabase
            .from('transaction')
            .update({'payment_method': 'Tunai'})
            .eq('id', debt.transactionId!);
      }

      // Refresh data di Provider
      await fetchDebts();
      await fetchPaymentHistory(debt.id);
      return true;
    } catch (e) {
      debugPrint('Error paying debt: $e');
      return false;
    }
  }

  // Fungsi Fetch Utang Spesifik
  Future<DebtModel?> getDebtByTransactionId(int transactionId) async {
    try {
      final response = await _supabase
          .from('debt')
          .select('*, customers(*)')
          .eq('transaction_id', transactionId)
          .maybeSingle();

      if (response != null) {
        return DebtModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('Error get debt by transaction id: $e');
    }
    return null;
  }
}
