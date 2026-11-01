import 'package:aplikasi_warung_supabase/models/debt_model.dart';
import 'package:aplikasi_warung_supabase/providers/debt_provider.dart';
import 'package:aplikasi_warung_supabase/widgets/custom_item_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PayDebtScreen extends StatefulWidget {
  final DebtModel debt;
  const PayDebtScreen({super.key, required this.debt});

  @override
  State<PayDebtScreen> createState() => _PayDebtScreenState();
}

class _PayDebtScreenState extends State<PayDebtScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedMethod = 'Tunai';
  bool _isSubmitting = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DebtProvider>().fetchPaymentHistory(widget.debt.id);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submitPayment() async {
    if (_isSubmitting) return;

    final amount = int.tryParse(_amountController.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal pembayaran yang valid')),
      );
      return;
    }

    if (amount > widget.debt.remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal melebihi sisa utang!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await context.read<DebtProvider>().payDebt(
        debt: widget.debt,
        amountPaid: amount,
        paymentMethod: _selectedMethod,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (success && mounted) {
        _amountController.clear();
        _notesController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pembayaran berhasil dicatat!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        await context.read<DebtProvider>().fetchPaymentHistory(widget.debt.id);

        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Gagal memproses pembayaran. Coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DebtProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Utang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. INFO CARD UTANG
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.debt.customer?.nameCustomer ?? 'Tanpa Nama',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Total Awal: Rp ${widget.debt.totalDebt}'),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Sisa Utang:',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          'Rp ${widget.debt.remainingAmount}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. FORM PEMBAYARAN / CICILAN
            const Text(
              'Form Pembayaran / Cicilan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // Shortcut Chips (Tombol Bayar Lunas)
            Row(
              children: [
                ActionChip(
                  avatar: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 18,
                  ),
                  label: const Text('Bayar Lunas'),
                  backgroundColor: Colors.green.shade50,
                  onPressed: () {
                    setState(() {
                      _amountController.text = widget.debt.remainingAmount
                          .toString();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Field Nominal
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: 'Rp ',
                labelText: 'Nominal Pembayaran',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Field Catatan
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Catatan (Opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Memproses...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : const Text(
                        'Simpan Transaksi Pembayaran',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 28),

            // 3. RIWAYAT PEMBAYARAN
            const Text(
              'Riwayat Pembayaran Transaksi Ini',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            if (provider.paymentHistory.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Belum ada riwayat cicilan.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: provider.paymentHistory.length,
                itemBuilder: (context, index) {
                  final item = provider.paymentHistory[index];
                  return CustomItemCard(
                    title: 'Pembayaran Utang (${item.paymentMethod})',
                    subtitle: item.notes ?? 'Tanpa catatan',
                    rightValue: 'Rp ${item.amountPaid}',
                    rightValueColor: Colors.green.shade700,
                    icon: Icons.payments_outlined,
                    iconColor: Colors.green,
                    iconBackgroundColor: Colors.green.shade50,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
