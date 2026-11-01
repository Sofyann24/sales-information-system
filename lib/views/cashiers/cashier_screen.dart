import 'package:aplikasi_warung_supabase/providers/cart_provider.dart';
import 'package:aplikasi_warung_supabase/widgets/cart_bottom_sheet.dart';
import 'package:aplikasi_warung_supabase/widgets/custom_appbar.dart';
import 'package:aplikasi_warung_supabase/widgets/custom_search_bar.dart';
import 'package:aplikasi_warung_supabase/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_warung_supabase/providers/product_provider.dart';
import 'package:aplikasi_warung_supabase/providers/category_provider.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryProvider>().fetchCategories();
      context.read<ProductProvider>().fetchProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    // Filter produk berdasarkan search & kategori
    final filteredProducts = productProvider.products.where((product) {
      final matchesSearch = product.nameProduct.toLowerCase().startsWith(
        _searchQuery.toLowerCase().trim(),
      );
      final matchesCategory =
          _selectedCategoryId == null ||
          product.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FD),
      appBar: CustomAppbar(),
      body: SafeArea(
        child: Column(
          children: [
            // 2. Search Bar
            CustomSearchBar(
              hintText: 'Cari Barang...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              categoryFilter: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Chip "Semua"
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Row(children: [const Text('Semua')]),
                        selected: _selectedCategoryId == null,
                        selectedColor: const Color(0xFFECE4FD),
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          color: _selectedCategoryId == null
                              ? const Color(0xFF4A3E7D)
                              : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          setState(() => _selectedCategoryId = null);
                        },
                      ),
                    ),
                    ...categoryProvider.categories.map((cat) {
                      final isSelected = _selectedCategoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Row(
                            children: [if (isSelected) ...[], Text(cat.name)],
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFECE4FD),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF4A3E7D)
                                : Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = selected ? cat.id : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // 3. Category Horizontal Filter
            const SizedBox(height: 8),

            // 4. Product Grid
            Expanded(
              child: productProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'Produk tidak ditemukan',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return ProductCard(product: product);
                      },
                    ),
            ),
          ],
        ),
      ),

      // Floating Action Button (Cart)
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.itemCount == 0) return const SizedBox.shrink();

          return Badge(
            label: Text('${cart.itemCount}'),
            backgroundColor: Colors.red,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF2196F3),
              onPressed: () => showCartBottomSheet(context),
              child: const Icon(Icons.shopping_cart, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
