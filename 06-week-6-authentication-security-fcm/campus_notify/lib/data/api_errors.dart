import 'dart:io';

import 'package:dio/dio.dart';

String apiErrorMessage(DioException error) {
  // 401 - Unauthorized
  if (error.response?.statusCode == 401) {
    return 'Sesi telah berakhir. Silakan login kembali.';
  }

  // Timeout
  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return 'Koneksi timeout. Silakan coba lagi.';
  }

  // Offline / tidak ada koneksi internet
  if (error.type == DioExceptionType.connectionError ||
      error.error is SocketException) {
    return 'Tidak ada koneksi internet.';
  }

  // Error lainnya
  return 'Terjadi kesalahan. Silakan coba lagi.';
}