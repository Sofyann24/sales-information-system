// ignore_for_file: use_build_context_synchronously
import 'package:aplikasi_warung_supabase/providers/product_provider.dart';
import 'package:aplikasi_warung_supabase/services/pdf_stock_service.dart';
import 'package:aplikasi_warung_supabase/views/stock/product_detail_screen.dart';
import 'package:aplikasi_warung_supabase/widgets/custom_appbar.dart';
import 'package:aplikasi_warung_supabase/widgets/custom_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StokPage extends StatefulWidget {
  const StokPage({super.key});

  @override
  State<StokPage> createState() => _StokPageState();
}

class _StokPageState extends State<StokPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    return Scaffold(
      appBar: CustomAppbar(),
      body: productProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              padding: EdgeInsets.all(5),
              child: Column(
                children: [
                  CustomSearchBar(
                    hintText: 'Cari Barang...',
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  // 2. Filter & Print Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Urutkan Berdasarkan: ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          DropdownButton<String>(isDense: true,
                            alignment: Alignment.topLeft,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.black54,
                            ),
                            value: 'A-Z', // Sesuaikan state nilai terpilih
                            underline: const SizedBox(), // Menghilangkan garis bawah default
                            items:
                                <String>[ 
                                  'A-Z',
                                  'Z-A',
                                  'Stok Terbanyak',
                                  'Stok Tersedikit',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: .0),
                                      child: Text(
                                        value,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (newValue) {
                              // Jalankan logika sorting berdasarkan value
                            },
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.print_rounded),
                        onPressed: () {
                          final allProducts = context
                              .read<ProductProvider>()
                              .products;

                          // 💡 FILTER: Cuma ambil barang yang stoknya <= 5 (sesuaikan batas stok merah lu)
                          final lowStockItems = allProducts
                              .where((item) => (item.stock) <= item.stockMin)
                              .toList();

                          // Validasi kalau kagak ada barang yang habis/merah
                          if (lowStockItems.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Aman bray, kagak ada barang yang stoknya habis/merah!',
                                ),
                              ),
                            );
                            return;
                          }

                          // Kirim list yang udah difilter ke PDF
                          PdfStockService.generateAndPrintPdf(lowStockItems);
                        },
                      ),
                    ],
                  ),

                  // 3. Item List dengan Divider
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 0,
                      ),
                      itemCount: productProvider.products.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 0.8,
                        color: Color(0xFFE0E0E0),
                      ),
                      itemBuilder: (context, index) {
                        final item = productProvider.products[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          title: Text(
                            item.nameProduct,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Stok: ',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: item.isLowStock
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: '${item.stock} ${item.unit}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: item.isLowStock
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailScreen(product: item),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 4. Floating Action Button (Tombol Tambah)
                  FloatingActionButton(
                    backgroundColor: const Color(0xFF2196F3),
                    elevation: 7,
                    onPressed: () {
                      Navigator.pushNamed(context, '/addStock');
                    },
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ),
    );
  }
}
