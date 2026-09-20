import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models/comment.dart';
import 'repositories/comment_repository.dart';

/// Alias agar pemakai lama tetap menggunakan client bersama.
final commentDioProvider = dioProvider;

/// Menyediakan repository komentar dengan client Dio dari provider di atas.
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(commentDioProvider)),
);

/// Memuat komentar berdasarkan postId; exception build otomatis menjadi
/// AsyncError yang dapat ditampilkan oleh UI melalui state.hasError.
class CommentsNotifier extends AsyncNotifier<List<Comment>> {
  /// Menyimpan argumen family agar dapat dipakai build dan refresh.
  CommentsNotifier(this.postId);

  final int postId;

  @override
  Future<List<Comment>> build() {
    return ref.watch(commentRepositoryProvider).fetchComments(postId);
  }

  /// Memuat ulang komentar dan mempertahankan penanganan error Riverpod.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(commentRepositoryProvider).fetchComments(postId),
    );
  }
}

/// Family provider membuat state terpisah untuk setiap postId.
final commentsProvider =
    AsyncNotifierProvider.family<CommentsNotifier, List<Comment>, int>(
      CommentsNotifier.new,
      // Error tidak di-retry otomatis agar state AsyncError segera tersedia.
      retry: (retryCount, error) => null,
    );

/// Mengubah error Dio menjadi pesan yang dapat dipahami pengguna.
String commentErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi timeout. Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) return 'Komentar tidak ditemukan (404).';
        if (statusCode == 500) {
          return 'Server sedang bermasalah (500). Coba lagi nanti.';
        }
        return 'Server mengembalikan error ($statusCode). Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }

  return 'Terjadi kesalahan tak terduga. Coba lagi.';
}
