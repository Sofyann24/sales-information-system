import 'package:aplikasi_warung_supabase/models/customer_model.dart';
import 'package:aplikasi_warung_supabase/models/debt_model.dart';
import 'package:aplikasi_warung_supabase/models/transaction_model.dart';
import 'package:aplikasi_warung_supabase/providers/debt_provider.dart';
import 'package:aplikasi_warung_supabase/providers/transaction_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DetailCustomerScreen extends StatefulWidget {
  final CustomerModel customer;

  const DetailCustomerScreen({super.key, required this.customer});

  @override
  State<DetailCustomerScreen> createState() => _DetailCustomerScreenState();
}

class _DetailCustomerScreenState extends State<DetailCustomerScreen> {
  // Di bagian bawah class _DetailCustomerScreenState

  bool _isStillDebt(TransactionModel tx) {
    // Cek apakah transaksi pake metode hutang
    final isHutang =
        tx.paymentMethod.toLowerCase().contains('hutang') ||
        tx.paymentMethod.toLowerCase().contains('utang');

    if (!isHutang) return false;

    // Cek status utang dari DebtProvider
    final debtProv = context.read<DebtProvider>();
    final debt = debtProv.debts.firstWhere(
      (d) => d.transactionId == tx.id,
      orElse: () => DebtModel(
        id: 0,
        totalDebt: 0,
        remainingAmount: 0,
        status: 'Lunas',
        customerId: null,
        transactionId: tx.id,
        createdAt: null,
      ),
    );

    // Cuma tampilkan kalo statusnya BELUM lunas DAN sisa utang > 0
    return debt.status != 'Lunas' && debt.remainingAmount > 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  // Helper untuk fetch ulang data transaksi & total hutang dari DebtProvider
  void _loadData() {
    final String customerId = widget.customer.id.toString();

    context.read<TransactionDetailsProvider>().clearAllCustomerTransactions();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        context.read<TransactionDetailsProvider>().refreshTotalTransactions(
          customerId,
        );
        context.read<DebtProvider>().fetchDebts();
        context.read<TransactionDetailsProvider>().clearDateFilter(customerId);
      }
    });
    
  }

  // Helper untuk format rupiah
  String formatRupiah(num number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  // Helper untuk format tanggal
  String formatDate(String dateString) {
    final dateTime = DateTime.parse(dateString).toLocal();
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.customer.nameCustomer;
    final phone = widget.customer.phoneNumber;
    final address = widget.customer.address ?? 'Tidak ada alamat';

    // Watch DebtProvider & TransactionDetailsProvider
    context.watch<DebtProvider>();
    final transacDetailProv = context.watch<TransactionDetailsProvider>();
    final customerTransactions = transacDetailProv.customerTransactions;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE53935),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Profile
          Container(
            width: double.infinity,
            color: const Color(0xFFE53935),
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // // 2. Summary Cards (Total Transaksi & Total Hutang dari DebtProvider)
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: _buildSummaryCard(
          //           icon: Icons.receipt_long_rounded,
          //           iconColor: const Color(0xFF1E88E5),
          //           value: customerTransactions.isEmpty
          //               ? '0'
          //               : customerTransactions.length.toString(),
          //           label: 'Total Transaksi',
          //           valueColor: const Color(0xFF1E88E5),
          //         ),
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: _buildSummaryCard(
          //           icon: Icons.attach_money_rounded,
          //           iconColor: const Color(0xFF4CAF50),
          //           // Mengambil total hutang dari DebtProvider
          //           value: formatRupiah(debtProv.totalPiutang),
          //           label: 'Total Hutang',
          //           valueColor: const Color(0xFF4CAF50),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          const SizedBox(height: 8),

          // 3. Header Title + Option Filter Tanggal
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history, color: Colors.black87, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Riwayat Transaksi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),

                    if (transacDetailProv.selectedSingleDate != null ||
                        transacDetailProv.selectedDateRange != null)
                      InkWell(
                        onTap: () {
                          context
                              .read<TransactionDetailsProvider>()
                              .clearDateFilter(widget.customer.id.toString());
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.refresh, size: 14, color: Colors.red),
                              SizedBox(width: 4),
                              Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    // Single Date Filter
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                transacDetailProv.selectedSingleDate ??
                                DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );

                          if (picked != null && context.mounted) {
                            context
                                .read<TransactionDetailsProvider>()
                                .setSingleDate(
                                  picked,
                                  widget.customer.id.toString(),
                                );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: transacDetailProv.selectedSingleDate != null
                                ? const Color(0xFFFFEBEE)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  transacDetailProv.selectedSingleDate != null
                                  ? const Color(0xFFE53935)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event,
                                size: 16,
                                color:
                                    transacDetailProv.selectedSingleDate != null
                                    ? const Color(0xFFE53935)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                transacDetailProv.selectedSingleDate == null
                                    ? 'Pilih Tanggal'
                                    : DateFormat('dd MMM yyyy').format(
                                        transacDetailProv.selectedSingleDate!,
                                      ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      transacDetailProv.selectedSingleDate !=
                                          null
                                      ? const Color(0xFFE53935)
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Date Range Filter
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange:
                                transacDetailProv.selectedDateRange,
                          );

                          if (picked != null && context.mounted) {
                            context
                                .read<TransactionDetailsProvider>()
                                .setDateRange(
                                  picked,
                                  widget.customer.id.toString(),
                                );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          decoration: BoxDecoration(
                            color: transacDetailProv.selectedDateRange != null
                                ? const Color(0xFFFFEBEE)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: transacDetailProv.selectedDateRange != null
                                  ? const Color(0xFFE53935)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.date_range,
                                size: 16,
                                color:
                                    transacDetailProv.selectedDateRange != null
                                    ? const Color(0xFFE53935)
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                transacDetailProv.selectedDateRange == null
                                    ? 'Pilih Periode'
                                    : '${DateFormat('dd/MM').format(transacDetailProv.selectedDateRange!.start)} - ${DateFormat('dd/MM').format(transacDetailProv.selectedDateRange!.end)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      transacDetailProv.selectedDateRange !=
                                          null
                                      ? const Color(0xFFE53935)
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Di bagian 4. List Riwayat Transaksi
          // 4. List Riwayat Transaksi (HANYA YANG BELUM LUNAS!)
          Expanded(
            child: transacDetailProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customerTransactions.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(5),
                    child: Center(
                      child: Text(
                        'Belum ada riwayat transaksi',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    // ⭐ FILTER: Hanya transaksi hutang yang BELUM LUNAS
                    itemCount: customerTransactions
                        .where((tx) => _isStillDebt(tx))
                        .length,
                    separatorBuilder: (context, index) => const Divider(
                      indent: 72,
                      height: 1,
                      color: Color(0xFFE2E8F0),
                    ),
                    itemBuilder: (context, index) {
                      // ⭐ Ambil data hasil filter
                      final tx = customerTransactions
                          .where((tx) => _isStillDebt(tx))
                          .toList()[index];

                      final amount = tx.totalPrice;
                      final paymentMethod = tx.paymentMethod;
                      final dateStr = formatDate(
                        tx.createdAt.toIso8601String(),
                      );

                      final isHutang =
                          paymentMethod.toLowerCase().contains('hutang') ||
                          paymentMethod.toLowerCase().contains('utang');

                      return ListTile(
                        onTap: () async {
                          if (isHutang) {
                            // 1. Tampilkan Loading Dialog
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            // 2. Fetch Debt dari DebtProvider
                            final debt = await context
                                .read<DebtProvider>()
                                .getDebtByTransactionId(tx.id);

                            // 3. Tutup Loading Dialog
                            if (context.mounted) {
                              Navigator.pop(context);

                              if (debt != null) {
                                // Buka halaman bayar utang dan tunggu hasilnya
                                final result = await Navigator.pushNamed(
                                  context,
                                  '/payDebt',
                                  arguments: debt,
                                );

                                // Refresh data otomatis jika ada perubahan status/pelunasan
                                if (result == true && context.mounted) {
                                  _loadData();
                                }
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
                          } else {
                            // Detail transaksi cash/lunas
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 1,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isHutang
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.receipt_long,
                            color: isHutang
                                ? const Color(0xFFE53935)
                                : const Color(0xFF2E7D32),
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              formatRupiah(amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isHutang
                                    ? const Color(0xFFFFEBEE)
                                    : const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isHutang ? 'Hutang' : 'Cash',
                                style: TextStyle(
                                  color: isHutang
                                      ? const Color(0xFFE53935)
                                      : const Color(0xFF2E7D32),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            dateStr,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget Helper Card Summary
  Widget _buildSummaryCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
