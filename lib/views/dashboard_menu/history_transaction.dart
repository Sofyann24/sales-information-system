import 'package:aplikasi_warung_supabase/models/transaction_model.dart';
import 'package:aplikasi_warung_supabase/providers/transaction_provider.dart';
import 'package:aplikasi_warung_supabase/services/receipt_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class HistoryTransactionScreen extends StatefulWidget {
  const HistoryTransactionScreen({super.key});

  @override
  State<HistoryTransactionScreen> createState() =>
      _HistoryTransactionScreenState();
}

class _HistoryTransactionScreenState extends State<HistoryTransactionScreen> {
  int _selectedTab = 0; // 0: Semua, 1: Cash, 2: Utang
  int _selectedDateFilter = 0; // 0: Hari Ini, 1: 7 Hari, 2: 30 Hari

  @override
  void initState() {
    super.initState();
    // Fetch data transaksi dari Supabase saat halaman dibuka
    Future.microtask(
      () => Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).fetchTransactions(),
    );
  }

  // Filter logika berdasarkan Tab & Periode Tanggal
  List<TransactionModel> _getFilteredTransactions(
    List<TransactionModel> transactions,
  ) {
    final now = DateTime.now();

    return transactions.where((item) {
      // 1. Filter Berdasarkan Metode Pembayaran (Tab)
      bool matchesTab = true;
      final payment = item.paymentMethod.toLowerCase();
      if (_selectedTab == 1) {
        matchesTab = payment == 'cash' || payment == 'tunai';
      } else if (_selectedTab == 2) {
        matchesTab = payment == 'hutang' || payment == 'utang';
      }

      // 2. Filter Berdasarkan Rentang Waktu
      bool matchesDate = true;
      final diffDays = now.difference(item.createdAt).inDays;
      if (_selectedDateFilter == 0) {
        // Hari Ini (Sama Tanggal, Bulan, Tahun)
        matchesDate =
            item.createdAt.year == now.year &&
            item.createdAt.month == now.month &&
            item.createdAt.day == now.day;
      } else if (_selectedDateFilter == 1) {
        matchesDate = diffDays <= 7;
      } else if (_selectedDateFilter == 2) {
        matchesDate = diffDays <= 30;
      }

      return matchesTab && matchesDate;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Top Navigation Tabs
          Container(
            color: const Color(0xFF2196F3),
            child: Row(
              children: [
                _buildTabItem(0, 'Semua'),
                _buildTabItem(1, 'Cash'),
                _buildTabItem(2, 'Utang'),
              ],
            ),
          ),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredList = _getFilteredTransactions(provider.transactions.cast<TransactionModel>());

                // Hitung Total Transaksi Periode Ini
                final totalPeriodAmount = filteredList.fold<int>(
                  0,
                  (sum, item) => sum + item.totalPrice.toInt(),
                );

                return RefreshIndicator(
                  onRefresh: () => provider.fetchTransactions(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Filter Bar
                        Row(
                          children: [
                            _buildDateChip(0, 'Hari Ini'),
                            const SizedBox(width: 8),
                            _buildDateChip(1, '7 Hari'),
                            const SizedBox(width: 8),
                            _buildDateChip(2, '30 Hari'),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.calendar_month,
                                color: Color(0xFF2196F3),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Total Banner Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Transaksi Periode Ini:',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                currencyFormat.format(totalPeriodAmount),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Transaction List
                        if (filteredList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text(
                              'Tidak ada transaksi pada periode ini',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredList.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              final isHutang =
                                  item.paymentMethod.toLowerCase() ==
                                      'hutang' ||
                                  item.paymentMethod.toLowerCase() == 'utang';

                              return InkWell(
                                onTap: () {
                                  // Lempar objek transaksi ke detail struk belanja
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReceiptDetailScreen(
                                        transactionData: {
                                          'id': item.id,
                                          'customer_id': item.customerId,
                                          'invoice_no': item.invoiceNumber,
                                          'date': DateFormat(
                                            'dd MMM yyyy, HH:mm',
                                            'id_ID',
                                          ).format(item.createdAt.toLocal()),
                                          'status': item.paymentMethod,
                                          'total': item.totalPrice,
                                        },
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  item.invoiceNumber,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isHutang
                                                        ? Colors.red.shade50
                                                        : Colors.green.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    item.paymentMethod,
                                                    style: TextStyle(
                                                      color: isHutang
                                                          ? Colors.red
                                                          : Colors.green,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              DateFormat(
                                                'dd MMMM yyyy, HH:mm',
                                                'id_ID',
                                              ).format(item.createdAt),
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(item.totalPrice),
                                        style: TextStyle(
                                          color: isHutang
                                              ? Colors.red
                                              : Colors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
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

  Widget _buildTabItem(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(int index, String label) {
    final isSelected = _selectedDateFilter == index;
    return InkWell(
      onTap: () => setState(() => _selectedDateFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          isSelected ? '✓ $label' : label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
