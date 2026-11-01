import 'package:flutter/material.dart';

void showCustomSnackBar({
  required BuildContext context,
  required String message,
  bool isError = true,
}) {
  ScaffoldMessenger.of(context)
      .clearSnackBars(); 

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isError
          ? const Color.fromARGB(255, 255, 85, 85)
          : const Color.fromARGB(255, 8, 193, 63), // Merah kalau error, Hijau kalau sukses
      behavior: SnackBarBehavior.floating, // Biar melayang halus di bawah
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3), // Hilang otomatis setelah 3 detik
    ),
  );
}
