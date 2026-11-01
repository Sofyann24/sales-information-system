// lib/helpers/auth_error_helper.dart

String parseAuthError(dynamic error) {
  final errorMessage = error.toString().toLowerCase();

  if (errorMessage.contains('invalid login credentials') ||
      errorMessage.contains('invalid_grant')) {
    return 'Email atau password yang kamu masukkan salah. Coba periksa kembali, ya!';
  } else if (errorMessage.contains('user not found')) {
    return 'Akun dengan email ini belum terdaftar.';
  } else if (errorMessage.contains('email not confirmed')) {
    return 'Email kamu belum diverifikasi. Silakan cek kotak masuk email kamu.';
  } else if (errorMessage.contains('network') ||
      errorMessage.contains('socketexception') ||
      errorMessage.contains('failed host lookup')) {
    return 'Gagal terhubung ke server. Periksa koneksi internet HP kamu, ya!';
  } else if (errorMessage.contains('too many requests')) {
    return 'Terlalu banyak percobaan login. Tunggu beberapa saat lagi.';
  }

  // Fallback untuk error tidak terduga lainnya
  return 'Terjadi kesalahan tidak terduga. Silakan coba beberapa saat lagi.';
}
