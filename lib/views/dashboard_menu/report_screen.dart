import 'package:aplikasi_warung_supabase/providers/sales_report_provider.dart';
import 'package:aplikasi_warung_supabase/widgets/custom_item_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesReportProvider>().setFilter(0);
    });
  }

  String _formatRupiah(int number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  String _getSectionTitle(int filterIndex) {
    switch (filterIndex) {
      case 0:
        return 'Ringkasan Hari Ini';
      case 1:
        return 'Ringkasan 7 Hari Terakhir';
      case 2:
        return 'Ringkasan 30 Hari Terakhir';
      default:
        return 'Ringkasan Periode Dipilih';
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = context.watch<SalesReportProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Laporan Penjualan'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. FILTER TANGGAL (CHIPS)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(context, 0, 'Hari Ini', report),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 1, '7 Hari', report),
                  const SizedBox(width: 8),
                  _buildFilterChip(context, 2, '30 Hari', report),
                  const SizedBox(width: 8),
                  // Date Picker Button
                  InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: report.selectedDateRange,
                      );
                      if (picked != null && mounted) {
                        report.setFilter(3, customRange: picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: report.selectedFilterIndex == 3
                            ? const Color(0xFF2196F3)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        Icons.calendar_month_outlined,
                        size: 20,
                        color: report.selectedFilterIndex == 3
                            ? Colors.white
                            : const Color(0xFF2196F3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. RINGKASAN HEADING
            Text(
              _getSectionTitle(report.selectedFilterIndex),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            if (report.isLoading)
              Center(
                child: CircularProgressIndicator(),
              )
            else ...[
              // Card Total Omset
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Omset Pendapatan',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(report.totalOmset),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Grid Total Nota & Item Unik
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryMiniCard(
                      icon: Icons.receipt_long,
                      iconColor: Colors.blue,
                      iconBg: const Color(0xFFE3F2FD),
                      title: 'Total Transaksi',
                      value: '${report.totalNota} Nota',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryMiniCard(
                      icon: Icons.inventory_2_outlined,
                      iconColor: Colors.orange,
                      iconBg: const Color(0xFFFFF3E0),
                      title: 'Item Unik Terjual',
                      value: '${report.totalItemUnik} Jenis',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. PRODUK TERLARIS
              const Text(
                'Produk Terlaris',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              if (report.topProducts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada data penjualan pada periode ini',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: report.topProducts.length,
                  itemBuilder: (context, index) {
                    final p = report.topProducts[index];
                    return CustomItemCard(
                      title: p['name_product'],
                      subtitle: 'Terjual: ${p['qty']} pcs',
                      rightValue: _formatRupiah(p['total_sales']),
                      rightValueColor: Colors.black87,
                      icon: Icons.workspace_premium,
                      iconColor: index == 0
                          ? Colors.amber
                          : (index == 1
                                ? Colors.grey
                                : (index == 2 ? Colors.brown : Colors.blue)),
                      iconBackgroundColor: index == 0
                          ? Colors.amber.shade50
                          : Colors.blue.shade50,
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    int index,
    String label,
    SalesReportProvider report,
  ) {
    final isSelected = report.selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF2196F3),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade300,
        ),
      ),
      onSelected: (_) => report.setFilter(index),
    );
  }

  Widget _buildSummaryMiniCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
