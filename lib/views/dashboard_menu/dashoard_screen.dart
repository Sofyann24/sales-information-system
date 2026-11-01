import 'package:aplikasi_warung_supabase/models/transaction_model.dart';
import 'package:aplikasi_warung_supabase/models/transaction_detail_model.dart';
import 'package:aplikasi_warung_supabase/providers/auth_provider.dart';
import 'package:aplikasi_warung_supabase/providers/product_provider.dart';
import 'package:aplikasi_warung_supabase/providers/sales_report_provider.dart';
import 'package:aplikasi_warung_supabase/providers/transaction_details_provider.dart';
import 'package:aplikasi_warung_supabase/providers/transaction_provider.dart';
import 'package:aplikasi_warung_supabase/widgets/custom_appbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesReportProvider>().setFilter(0); // Default 'Hari Ini'
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTodayProfit();
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SalesReportProvider>();
    final userRole = context.watch<AuthProvider>().userRole;
    final productProv = context.watch<ProductProvider>();
    final transactionProv = context.watch<TransactionProvider>();
    final int todaySales = transactionProv.todayTotalSales;

    // Ambil transaksi hari ini dari TransactionProvider
    final List<TransactionModel> todayTransactions =
        transactionProv.transactions;
    debugPrint(
      '🔍 Total transaksi hari ini dari Provider: ${todayTransactions.length}',
    );
    // // Kumpulkan seluruh item terjual hari ini
    // final List<TransactionDetailsProvider> todayItems = todayTransactions
    //     .expand((tx) => tx.details ?? [])
    //     .toList();
    // debugPrint('📦 Total item terjual hari ini: ${todayItems.length}');

    // // Hitung total profit via ProductProvider
    // final num todayProfit = productProv.calculateTodayTotalProfit(todayItems);

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: CustomAppbar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Untung Hari Ini Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Untung Hari Ini',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Consumer<TransactionProvider>(
                        builder: (context, transProv, child) {
                          return Text(
                            currencyFormatter.format(
                              transProv.todayProfit,
                            ),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Info Cards (Uang Masuk & Utang)
            buildSummaryCards(context),
            const SizedBox(height: 24),

            // 3. Menu Utama Header
            const Text(
              'Menu Utama',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 4. Menu Grid (Filtered by Role)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
              children: [
                // 🔴 MENU KHUSUS OWNER
                if (userRole == 'owner')
                  _buildMenuItem(
                    icon: Icons.receipt_long_rounded,
                    iconColor: Colors.blue,
                    bgColor: const Color(0xFFE3F2FD),
                    title: 'Laporan',
                    onTap: () {
                      Navigator.pushNamed(context, '/reportScreen');
                    },
                  ),

                // 🟢 MENU UMUM (BISA DIAKSES KASIR & OWNER)
                _buildMenuItem(
                  icon: Icons.history_rounded,
                  iconColor: Colors.blue,
                  bgColor: const Color(0xFFE3F2FD),
                  title: 'History Transaksi',
                  onTap: () {
                    Navigator.pushNamed(context, '/historyTransaction');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.book_rounded,
                  iconColor: Colors.orange,
                  bgColor: const Color(0xFFFFF3E0),
                  title: 'Daftar Utang',
                  onTap: () {
                    Navigator.pushNamed(context, '/debtList');
                  },
                ),
                if (userRole == 'owner')
                  _buildMenuItem(
                    icon: Icons.grid_view_rounded,
                    iconColor: Colors.purple,
                    bgColor: const Color(0xFFF3E5F5),
                    title: 'Kategori',
                    onTap: () {
                      Navigator.pushNamed(context, '/category');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummaryCards(BuildContext context) {
    // 1. Ambil role user dari AuthProvider
    final userRole = context.watch<AuthProvider>().userRole;

    // 2. Jika bukan owner, jangan tampilkan apa-apa
    if (userRole != 'owner') {
      return const SizedBox.shrink();
    }

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Consumer<SalesReportProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            // 🟩 CARD UANG MASUK (HIJAU)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8ED),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFC7F0D2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Uang Masuk',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatter.format(provider.uangMasuk),
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // 🟥 CARD UTANG (MERAH)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8C8CD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: Color(0xFFD32F2F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Utang',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatter.format(provider.totalUtang),
                            style: const TextStyle(
                              color: Color(0xFFD32F2F),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
