import 'package:aplikasi_warung_supabase/models/product_model.dart';
import 'package:aplikasi_warung_supabase/models/transaction_model.dart';
import 'package:aplikasi_warung_supabase/providers/product_provider.dart';
import 'package:aplikasi_warung_supabase/providers/transaction_details_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class ReceiptDetailScreen extends StatefulWidget {
  final Map<String, dynamic> transactionData;

  const ReceiptDetailScreen({super.key, required this.transactionData});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transactionId =
          widget.transactionData['id']?.toString() ??
          widget.transactionData['transaction_id']?.toString() ??
          '';

      if (transactionId.isNotEmpty) {
        context.read<TransactionDetailsProvider>().fetchTransactionsByCustomer(
          transactionId,
        );
      }
    });
  }

  // 🖨️ Fungsi Cetak / Simpan PDF
  Future<void> _printReceipt(
    List<dynamic> details,
    NumberFormat currencyFormat,
    ProductProvider productProv,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'WARUNG KITA',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Jl. Merdeka No. 123',
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('No. Nota', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    widget.transactionData['invoice_no'] ??
                        widget.transactionData['invoice_number'] ??
                        '-',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tanggal', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    widget.transactionData['date'] ??
                        widget.transactionData['created_at'] ??
                        '-',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.Divider(),
              ...details.map((item) {
                dynamic rawItem = item;
                num qty = 0;
                num sub = 0;
                String pName = 'Barang';

                try {
                  qty = rawItem.quantity ?? 0;
                  sub = rawItem.subTotal ?? 0;
                  pName = rawItem.productName ?? 'Barang';
                } catch (_) {
                  if (rawItem is Map) {
                    qty = rawItem['quantity'] ?? 0;
                    sub = rawItem['sub_total'] ?? 0;
                    pName = rawItem['product_name'] ?? 'Barang';
                  }
                }

                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '$pName x$qty',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.Text(
                      currencyFormat.format(sub),
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ],
                );
              }),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    currencyFormat.format(
                      widget.transactionData['total'] ??
                          widget.transactionData['total_price'] ??
                          0,
                    ),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProv = context.watch<ProductProvider>();
    final detailsProv = context.watch<TransactionDetailsProvider>();
    final List<dynamic> transactionDetails = detailsProv.customerTransactions;

    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final String statusPembayaran =
        widget.transactionData['status'] ??
        widget.transactionData['payment_method'] ??
        'Lunas';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Detail Struk Belanja'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🧾 KARTU STRUK
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 48,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'WARUNG KITA',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Jl. Merdeka No. 123',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Divider(height: 30, thickness: 1),

                  // INFO TRANSAKSI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'No. Nota',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        widget.transactionData['invoice_no'] ??
                            widget.transactionData['invoice_number'] ??
                            '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tanggal',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Text(
                        widget.transactionData['date'] ??
                            widget.transactionData['created_at'] ??
                            '-',
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tipe Pembayaran',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (statusPembayaran.toLowerCase().contains(
                                    'utang',
                                  ) ||
                                  statusPembayaran.toLowerCase().contains(
                                    'hutang',
                                  ))
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          statusPembayaran,
                          style: TextStyle(
                            color:
                                (statusPembayaran.toLowerCase().contains(
                                      'utang',
                                    ) ||
                                    statusPembayaran.toLowerCase().contains(
                                      'hutang',
                                    ))
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30, thickness: 1),

                  // LIST BARANG DARI PROVIDER
                  detailsProv.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        )
                      : transactionDetails.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Tidak ada rincian item.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : // 1. Pada bagian ListView.builder di build()
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactionDetails.length,
                          itemBuilder: (context, index) {
                            // Ambil objek TransactionModel dari provider
                            final transaction =
                                transactionDetails[index] as TransactionModel;

                            // Jika list detail kosong
                            if (transaction.transactionDetails.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Tidak ada rincian item.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }

                            // Render setiap item detail yang bersarang di dalam transaksi
                            return Column(
                              children: transaction.transactionDetails.map((
                                detail,
                              ) {
                                final productName =
                                    detail.product?.nameProduct ?? 'Produk';
                                final quantity = detail.quantity;
                                final subtotal = detail.subtotal;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text('$productName x $quantity'),
                                      ),
                                      Text(currencyFormat.format(subtotal)),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),

                  const Divider(height: 30, thickness: 1),

                  // TOTAL PEMBAYARAN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        currencyFormat.format(
                          widget.transactionData['total'] ??
                              widget.transactionData['total_price'] ??
                              0,
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // TOMBOL AKSI
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.print),
              label: const Text('Cetak / Simpan PDF Struk'),
              onPressed: () {
                _printReceipt(transactionDetails, currencyFormat, productProv);
              },
            ),
          ],
        ),
      ),
    );
  }
}
