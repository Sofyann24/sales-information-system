import 'dart:io';

import 'package:aplikasi_warung_supabase/models/product_model.dart';
import 'package:aplikasi_warung_supabase/providers/category_provider.dart';
import 'package:aplikasi_warung_supabase/providers/product_provider.dart';
import 'package:aplikasi_warung_supabase/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _stockController;
  late TextEditingController _stockMinController;
  late TextEditingController _priceModalController;
  late TextEditingController _priceController;

  String? _selectedCategoryId;
  String? _selectedUnit;
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Daftar pilihan satuan (unit)
  final List<String> _unitList = [
    'pcs',
    'kg',
    'gr',
    'liter',
    'pack',
    'botol',
    'dus',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.nameProduct);
    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );
    _stockMinController = TextEditingController(
      text: widget.product.stockMin.toString(),
    );
    _priceModalController = TextEditingController(
      text: widget.product.priceModal != null
          ? widget.product.priceModal.toString()
          : '',
    );
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );

    _selectedCategoryId = widget.product.categoryId;

    // Cek apakah unit produk ada di daftar pilihan unit
    if (widget.product.unit != null &&
        _unitList.contains(widget.product.unit!.toLowerCase())) {
      _selectedUnit = widget.product.unit!.toLowerCase();
    } else {
      _selectedUnit = 'pcs';
    }

    Future.microtask(() {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _stockMinController.dispose();
    _priceModalController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final updatedProduct = ProductModel(
      id: widget.product.id,
      nameProduct: _nameController.text.trim(),
      price: int.parse(_priceController.text.trim()),
      priceModal: _priceModalController.text.isNotEmpty
          ? int.parse(_priceModalController.text.trim())
          : null,
      stock: int.parse(_stockController.text.trim()),
      stockMin: _stockMinController.text.isNotEmpty
          ? int.parse(_stockMinController.text.trim())
          : 5,
      unit: _selectedUnit,
      categoryId: _selectedCategoryId,
      imageUrl: widget.product.imageUrl,
    );

    final success = await context.read<ProductProvider>().updateProduct(
      widget.product.id.toString(),
      updatedProduct,
      newImageFile: _selectedImage,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      showCustomSnackBar(
        context: context,
        message: 'Produk Berhasil di Ubah',
        isError: false,
      );
      Navigator.pop(context);
    } else if (mounted) {
      showCustomSnackBar(
        context: context,
        message: 'Gagal Memperbarui Produk, Cek Kembali',
        isError: true,
      );
    }
  }

  // Helper Ambil Foto dari Kamera / Galeri
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Barang',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- UPLOAD IMAGE CONTAINER ---
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: 130,
                                height: 130,
                              ),
                            )
                          : (widget.product.imageUrl != null &&
                                widget.product.imageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                widget.product.imageUrl!,
                                fit: BoxFit.cover,
                                width: 130,
                                height: 130,
                                // Loading indicator saat gambar sedang didownload
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                                // Handling jika gambar di URL error/hilang
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            )
                          // 3. Jika tidak ada gambar baru maupun gambar lama
                          : const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 60,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // --- ICON KAMERA & GALERI ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 28),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- NAMA PRODUK ---
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildInputDecoration('Nama Produk'),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Nama produk wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    // --- STOK & MIN STOK ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _buildInputDecoration('Stok'),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Stok wajib diisi'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _stockMinController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _buildInputDecoration('Min Stok'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // --- HARGA MODAL & HARGA JUAL ---
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceModalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _buildInputDecoration('Harga Modal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _buildInputDecoration('Harga Jual'),
                            validator: (val) => val == null || val.isEmpty
                                ? 'Harga jual wajib diisi'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // --- DROPDOWN KATEGORI ---
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue:
                          categoryProvider.categories.any(
                            (c) => c.id == _selectedCategoryId,
                          )
                          ? _selectedCategoryId
                          : null,
                      decoration: _buildInputDecoration('Kategori'),
                      items: categoryProvider.categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat.id,
                          child: Text(
                            cat.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategoryId = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    // --- DROPDOWN SATUAN ---
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedUnit,
                      decoration: _buildInputDecoration('Satuan'),
                      items: _unitList.map((unit) {
                        return DropdownMenuItem<String>(
                          value: unit,
                          child: Text(
                            unit,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedUnit = val);
                      },
                    ),
                    const SizedBox(height: 36),

                    // --- TOMBOL SAVE ---
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _submitForm,
                        child: const Text(
                          'SAVE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 15),
      floatingLabelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
      ),
    );
  }
}
