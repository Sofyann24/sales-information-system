import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../models/debt_model.dart';
import '../../../../providers/debt_provider.dart';
import '../../../../widgets/custom_item_card.dart';

class CustomerTransactionHistorySection extends StatelessWidget {
  final List<dynamic>
  transactions; // Oper data riwayat transaksi customer dari parent

  const CustomerTransactionHistorySection({
    super.key,
    required this.transactions,
  });

  void _handleTransactionTap(BuildContext context, dynamic transaction) async {
    final bool isHutang = transaction.statusPayment == 'Hutang';

    if (isHutang) {
      // Show Bottom Sheet Aksi Opsi Bayar
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (bottomSheetContext) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaksi #${transaction.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: Rp ${transaction.totalAmount} • Status: Hutang',
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // Tombol Direct Bayar Utang
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.payments_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Bayar Utang Transaksi Ini',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(bottomSheetContext); // Tutup BottomSheet

                      // Loading Dialog
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) =>
                            const Center(child: CircularProgressIndicator()),
                      );

                      // Fetch data debt spesifik
                      final DebtModel? debt = await context
                          .read<DebtProvider>()
                          .getDebtByTransactionId(transaction.id);

                      if (context.mounted) {
                        Navigator.pop(context); // Tutup Loading

                        if (debt != null) {
                          // Buka Screen Pembayaran Utang
                          Navigator.pushNamed(
                            context,
                            '/payDebt',
                            arguments: debt,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Data utang tidak ditemukan/sudah lunas',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Tombol Lihat Detail Struk
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Lihat Detail Struk'),
                    onPressed: () {
                      Navigator.pop(bottomSheetContext);
                      // TODO: Buka Detail Struk Nota
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Jika status Lunas, buka detail struk biasa
      // TODO: Buka Detail Struk Nota
    }
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Belum ada riwayat transaksi.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Biar ngikut scroll parent screen
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final bool isHutang = tx.statusPayment == 'Hutang';

        return CustomItemCard(
          title: 'Rp ${tx.totalAmount}',
          subtitle: tx.formattedDate,
          rightValue: tx.statusPayment,
          rightValueColor: isHutang ? Colors.red : Colors.green,
          icon: Icons.receipt,
          iconColor: isHutang ? Colors.red : Colors.blue,
          iconBackgroundColor: isHutang
              ? Colors.red.shade50
              : Colors.blue.shade50,
          onTap: () => _handleTransactionTap(context, tx),
        );
      },
    );
  }
}
