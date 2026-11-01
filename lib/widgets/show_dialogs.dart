import 'package:aplikasi_warung_supabase/models/product_model.dart';
import 'package:aplikasi_warung_supabase/providers/auth_provider.dart';
import 'package:aplikasi_warung_supabase/providers/category_provider.dart';
import 'package:aplikasi_warung_supabase/providers/product_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


// Show Dialog Logout
class LogoutDialog {
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Konfirmasi Logout',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Apakah kamu yakin ingin keluar dari aplikasi?'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).logout(context);
              },
              child: const Text(
                'Ya, Keluar',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Show Dialog Add Category
class ShowAddCategoryDialog {
  // 1. Dialog Tambah Kategori
  static Future<void> showAddCategoryDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tambah Kategori Baru',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Nama Kategori',
                hintText: 'Contoh: Sembako, Minuman',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama kategori tidak boleh kosong';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final categoryName = controller.text.trim();

                  // Panggil provider untuk simpan data
                  final success = await context
                      .read<CategoryProvider>()
                      .addCategory(categoryName);

                  if (context.mounted) {
                    Navigator.pop(context); // Tutup dialog

                    // Tampilkan SnackBar notifikasi
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Kategori "$categoryName" berhasil ditambahkan!'
                              : 'Gagal menambah kategori.',
                        ),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}


// widgets/delete_dialog.dart
class DeleteDialog {
  static Future<void> show({
    required BuildContext context,
    required ProductModel product,
    VoidCallback? onSuccess,
  }) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Hapus Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${product.nameProduct}"?',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          // Tombol Batal
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          // Tombol Hapus
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              // Tutup dialog
              Navigator.pop(ctx);

              // Panggil fungsi delete
              final success = await context
                  .read<ProductProvider>()
                  .deleteProduct(product.id);

              if (success && context.mounted) {
                // Tampilkan snackbar sukses
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produk berhasil dihapus!'),
                    backgroundColor: Colors.green,
                  ),
                );
                onSuccess?.call();
              } else if (context.mounted) {
                // Tampilkan snackbar error
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gagal menghapus produk. Coba lagi.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
