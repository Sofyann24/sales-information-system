import 'dart:io';

import 'package:aplikasi_warung_supabase/widgets/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_warung_supabase/providers/product_provider.dart';
import 'package:aplikasi_warung_supabase/providers/category_provider.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();

  // State Variables
  String? _selectedCategoryId;
  String _selectedUnit = 'pcs';
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  // List pilihan Satuan
  final List<String> _unitList = [
    'pcs',
    'kg',
    'liter',
    'bungkus',
    'box',
    'ikat',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<ProductProvider>().addProduct(
        name: _nameController.text.trim(),
        price: int.parse(_sellingPriceController.text.trim()),
        stock: int.tryParse(_stockController.text.trim()) ?? 0,
        categoryId: _selectedCategoryId ?? '',
        imageFile: _selectedImage,
      );

      if (context.mounted) {
        if (success) {
          Navigator.pop(context);
          showCustomSnackBar(
            context: context,
            message: 'Produk Berhasil Ditambahkan',
            isError: false,
          );
        } else {
          showCustomSnackBar(
            context: context,
            message: 'Produk Gagal Ditambahkan, Coba Kembali',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final productProvider = context.watch<ProductProvider>();

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
          'Tambah Barang',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Box Preview Gambar
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
                    : const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 60,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // 2. Tombol Kamera & Galeri
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      size: 28,
                      color: Colors.black87,
                    ),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      size: 28,
                      color: Colors.black87,
                    ),
                    onPressed: () => _pickImage(ImageSource.gallery),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 3. Input Nama Produk
              TextFormField(
                controller: _nameController,
                decoration: _buildInputDecoration('Nama Produk'),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Nama produk wajib diisi'
                    : null,
              ),

              const SizedBox(height: 16),

              // 4. Row: Stok & Min Stok
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration('Stok'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minStockController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration('Min Stok'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Row: Harga Modal & Harga Jual
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration('Harga Modal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration('Harga Jual'),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? 'Harga jual wajib diisi'
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 6. Dropdown Kategori
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: _buildInputDecoration('Kategori'),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                items: categoryProvider.categories.map((cat) {
                  return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCategoryId = val);
                },
              ),

              const SizedBox(height: 16),

              // 7. Dropdown Satuan
              DropdownButtonFormField<String>(
                initialValue: _selectedUnit,
                decoration: _buildInputDecoration('Satuan'),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                items: _unitList.map((unit) {
                  return DropdownMenuItem(value: unit, child: Text(unit));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedUnit = val);
                },
              ),

              const SizedBox(height: 32),

              // 8. Tombol SAVE
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: productProvider.isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: productProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SAVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
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

  // Style Dekorasi Input Outline Sesuai UI Screenshot
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      floatingLabelStyle: const TextStyle(color: Color(0xFF2196F3)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2196F3), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
